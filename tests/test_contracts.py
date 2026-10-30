"""Offline tests of the shipped workflow scripts and composite action boundary."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest

import yaml

ROOT = Path(__file__).resolve().parents[1]
ACTION = ROOT / ".github/actions/build-solution/Find-PluginAssembly.ps1"
CLI_COMMAND = os.environ.get("PPDS_TEST_CLI_COMMAND")
MOCK = r"""
function global:ppds {
    $tokens = @($args)
    ConvertTo-Json -InputObject $tokens -Compress >> $env:TRACE_FILE
    $global:LASTEXITCODE = 0
    switch ("$($tokens[0]) $($tokens[1])") {
        'auth create' {
            if ($env:FAKE_MODE -eq 'auth-error') { $global:LASTEXITCODE = 4 }
        }
        'auth delete' { }
        'plugins extract' {
            if ($env:FAKE_MODE -eq 'extract-error') { $global:LASTEXITCODE = 2 }
        }
        'plugins diff' {
            if ($env:FAKE_MODE -eq 'invalid-json') { 'not-json'; return }
            if ($env:FAKE_MODE -eq 'error') {
                $global:LASTEXITCODE = 1
                '{"version":"1.0","success":false,"error":{"code":"Auth.Failed"}}'
                return
            }
            $assembly = @{
                assemblyName = 'Consumer.Plugin'; assemblyMissing = $false
                missingSteps = @(); orphanedSteps = @(); modifiedSteps = @()
                missingImages = @(); orphanedImages = @(); modifiedImages = @()
            }
            if ($env:FAKE_MODE -in 'drift','wrong-success-exit') {
                $assembly.missingSteps = @(@{ stepName = 'Create of account' })
                $global:LASTEXITCODE = 1
            }
            if ($env:FAKE_MODE -eq 'wrong-success-exit') { $global:LASTEXITCODE = 0 }
            if ($env:FAKE_MODE -eq 'wrong-drift-exit') { $global:LASTEXITCODE = 1 }
            if ($env:FAKE_MODE -eq 'malformed-data') { $assembly.Remove('assemblyMissing') }
            @{ version = '1.0'; success = $true; data = @($assembly) } |
                ConvertTo-Json -Depth 10
        }
        'plugins deploy' {
            if ($env:FAKE_MODE -eq 'deploy-error') {
                $global:LASTEXITCODE = 1
                '{"version":"1.0","success":false,"error":{"code":"Deployment.Failed"}}'
                return
            }
            '{"version":"1.0","success":true,"data":{"assembliesDeployed":1}}'
        }
        default { throw "Unexpected command in offline mock: $($tokens[0]) $($tokens[1])" }
    }
}
"""


def workflow(name):
    return yaml.safe_load((ROOT / ".github/workflows" / name).read_text(encoding="utf-8"))


def steps(name, job):
    return {s["id"]: s for s in workflow(name)["jobs"][job]["steps"] if "id" in s}


def run_pwsh(script, folder, env=None):
    path = Path(folder) / "harness.ps1"
    path.write_text(script, encoding="utf-8")
    return subprocess.run(
        ["pwsh", "-NoProfile", "-File", str(path)], cwd=folder,
        env={**os.environ, **(env or {})}, capture_output=True, text=True,
        encoding="utf-8", timeout=90,
    )


class WorkflowContracts(unittest.TestCase):
    def run_deploy(self, mode="none"):
        scripts = steps("plugin-deploy.yml", "deploy")
        with tempfile.TemporaryDirectory() as d:
            trace = Path(d) / "trace.jsonl"
            output = Path(d) / "outputs"
            env = dict(TRACE_FILE=str(trace), GITHUB_OUTPUT=str(output), FAKE_MODE=mode,
                       PPDS_PROFILE="alm-offline-fixture", DATAVERSE_URL="https://offline.invalid",
                       CLIENT_ID="synthetic-client", CLIENT_SECRET="synthetic-secret-never-real",
                       TENANT_ID="synthetic-tenant", REGISTRATION_FILE="path with spaces/registrations.json")
            body = MOCK + "\ntry {\n" + "\n".join(scripts[x]["run"] for x in ("auth", "drift", "deploy"))
            body += "\n} finally {\n" + scripts["cleanup"]["run"] + "\n}\n"
            result = run_pwsh(body, d, env)
            calls = [json.loads(l) for l in trace.read_text(encoding="utf-8").splitlines()]
            outputs = output.read_text(encoding="utf-8") if output.exists() else ""
            return result, calls, outputs

    def test_profile_auth_and_no_drift_deployment_contract(self):
        result, calls, outputs = self.run_deploy()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(calls[0], ["auth", "create", "--name", "alm-offline-fixture",
                         "--environment", "https://offline.invalid", "--applicationId", "synthetic-client",
                         "--clientSecret", "synthetic-secret-never-real", "--tenant", "synthetic-tenant"])
        self.assertEqual(calls[1], ["plugins", "diff", "--config", "path with spaces/registrations.json",
                         "--profile", "alm-offline-fixture", "--environment", "https://offline.invalid",
                         "--output-format", "Json"])
        self.assertEqual(calls[2], ["plugins", "deploy", *calls[1][2:]])
        self.assertEqual(calls[-1], ["auth", "delete", "--name", "alm-offline-fixture"])
        self.assertIn("detected=false", outputs)
        self.assertIn("deployed=true", outputs)
        self.assertNotIn("synthetic-secret-never-real", result.stdout + result.stderr)

    def test_real_drift_exit_one_is_success_and_continues(self):
        result, calls, outputs = self.run_deploy("drift")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertIn("detected=true", outputs)
        self.assertIn("deployed=true", outputs)
        self.assertEqual(calls[2][0:2], ["plugins", "deploy"])

    def test_failed_or_inconsistent_comparison_stops_deploy_and_cleans_up(self):
        for mode in ("invalid-json", "error", "malformed-data", "wrong-success-exit", "wrong-drift-exit"):
            with self.subTest(mode=mode):
                result, calls, outputs = self.run_deploy(mode)
                self.assertNotEqual(result.returncode, 0)
                self.assertNotIn(["plugins", "deploy"], [c[:2] for c in calls])
                self.assertEqual(calls[-1][:2], ["auth", "delete"])
                self.assertNotIn("deployed=true", outputs)

    def test_drift_step_resets_native_status(self):
        script = steps("plugin-deploy.yml", "deploy")["drift"]["run"]
        with tempfile.TemporaryDirectory() as d:
            result = run_pwsh(MOCK + script + "\nexit $LASTEXITCODE\n", d, dict(
                TRACE_FILE=str(Path(d) / "trace"), GITHUB_OUTPUT=str(Path(d) / "outputs"),
                FAKE_MODE="drift", PPDS_PROFILE="fixture", DATAVERSE_URL="https://offline.invalid",
                REGISTRATION_FILE="registrations.json"))
            self.assertEqual(result.returncode, 0, result.stderr)

    def test_action_checkout_guard_fails_closed(self):
        script = next(s["run"] for s in workflow("solution-build.yml")["jobs"]["build"]["steps"]
                      if s["name"] == "Reserve ALM action directory")
        for sha, repository in [("", "owner/alm"), ("abc", "")]:
            with self.subTest(sha=sha, repository=repository), tempfile.TemporaryDirectory() as d:
                result = run_pwsh(script, d, dict(ALM_WORKFLOW_SHA=sha, ALM_WORKFLOW_REPOSITORY=repository))
                self.assertNotEqual(result.returncode, 0)
                self.assertIn("workflow identity", result.stderr)
        with tempfile.TemporaryDirectory() as d:
            reserved = Path(d) / ".ppds-alm-actions"
            reserved.mkdir()
            marker = reserved / "consumer.txt"
            marker.write_text("retain")
            result = run_pwsh(script, d, dict(ALM_WORKFLOW_SHA="abc", ALM_WORKFLOW_REPOSITORY="owner/alm"))
            self.assertNotEqual(result.returncode, 0)
            self.assertIn("already exists", result.stderr)
            self.assertEqual(marker.read_text(), "retain")

    def test_auth_failure_stops_all_plugin_operations(self):
        result, calls, outputs = self.run_deploy("auth-error")
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual([c[:2] for c in calls], [["auth", "create"], ["auth", "delete"]])
        self.assertNotIn("deployed=true", outputs)

    def test_deploy_failure_does_not_report_success(self):
        result, calls, outputs = self.run_deploy("deploy-error")
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("deployed=true", outputs)
        self.assertEqual(calls[-1][:2], ["auth", "delete"])

    def test_extract_uses_input_option_and_checks_native_exit(self):
        script = steps("plugin-extract.yml", "extract")["extract"]["run"]
        for mode in ("none", "extract-error"):
            with self.subTest(mode=mode), tempfile.TemporaryDirectory() as d:
                trace, output = Path(d) / "trace", Path(d) / "outputs"
                result = run_pwsh(MOCK + script, d, dict(
                    TRACE_FILE=str(trace), GITHUB_OUTPUT=str(output), FAKE_MODE=mode,
                    ASSEMBLY_PATH="folder with spaces/Consumer.Plugin.dll", OUTPUT_PATH="output file.json"))
                calls = [json.loads(l) for l in trace.read_text().splitlines()]
                self.assertEqual(calls, [["plugins", "extract", "--input",
                                 "folder with spaces/Consumer.Plugin.dll", "--output", "output file.json"]])
                self.assertEqual(result.returncode == 0, mode == "none")
                self.assertEqual(output.exists(), mode == "none")

    def test_composite_resolves_helper_from_installed_action(self):
        action = yaml.safe_load((ROOT / ".github/actions/build-solution/action.yml").read_text())
        locate = next(s for s in action["runs"]["steps"] if s.get("id") == "locate")
        self.assertEqual(locate["env"]["ALM_ACTION_PATH"], "${{ github.action_path }}")
        self.assertIn('$ALM_ACTION_PATH/Find-PluginAssembly.ps1', locate["run"])
        self.assertEqual(locate["env"]["PLUGIN_PROJECT"], "${{ inputs.plugin-project }}")
        self.assertEqual(locate["env"]["PLUGIN_TARGET_FRAMEWORK"], "${{ inputs.plugin-target-framework }}")

    def test_reusable_actions_use_the_defining_workflow_revision(self):
        for path in (ROOT / ".github/workflows").glob("*.yml"):
            for job in workflow(path.name).get("jobs", {}).values():
                action_steps = [s for s in job.get("steps", []) if s.get("uses", "").startswith("./")]
                if not action_steps:
                    continue
                checkout = next(s for s in job["steps"] if s.get("name") == "Checkout matching ALM actions")
                self.assertEqual(checkout["with"]["repository"], "${{ job.workflow_repository }}")
                self.assertEqual(checkout["with"]["ref"], "${{ job.workflow_sha }}")
                self.assertFalse(checkout["with"]["persist-credentials"])
                guard = next(s for s in job["steps"] if s.get("name") == "Reserve ALM action directory")
                self.assertEqual(guard["env"]["ALM_WORKFLOW_SHA"], "${{ job.workflow_sha }}")
                self.assertEqual(guard["env"]["ALM_WORKFLOW_REPOSITORY"], "${{ job.workflow_repository }}")
                self.assertLess(job["steps"].index(guard), job["steps"].index(checkout))
                self.assertTrue(all(s["uses"].startswith("./.ppds-alm-actions/.github/actions/") for s in action_steps))
                for step in action_steps:
                    if step["uses"].endswith("/build-solution"):
                        self.assertEqual(step["with"]["plugin-project"], "${{ inputs.plugin-project }}")
                        self.assertEqual(step["with"]["plugin-target-framework"], "${{ inputs.plugin-target-framework }}")


class AssemblySelection(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.root = Path(self.temp.name)
        self.plugins = self.root / "src/Plugins"

    def tearDown(self):
        self.temp.cleanup()

    def project(self, name="Chosen", assembly="Selected.Plugin", multi=False):
        folder = self.plugins / name
        folder.mkdir(parents=True)
        (self.root / "Directory.Build.props").write_text(
            '<Project><PropertyGroup Condition="\'$(Configuration)\' == \'Release\'">'
            f'<AssemblyName>{assembly}</AssemblyName></PropertyGroup></Project>', encoding="utf-8")
        framework = "<TargetFrameworks>net8.0;net9.0</TargetFrameworks>" if multi else "<TargetFramework>net8.0</TargetFramework>"
        project = folder / (name + ".csproj")
        project.write_text(f'<Project Sdk="Microsoft.NET.Sdk"><PropertyGroup>{framework}</PropertyGroup></Project>')
        output = folder / "bin/Release/net8.0"
        output.mkdir(parents=True)
        (output / "PPDS.Plugins.dll").write_bytes(b"dependency, not the plugin")
        expected = output / (assembly + ".dll")
        expected.write_bytes(b"fixture output")
        return project, expected

    def select(self, *extra):
        return subprocess.run(["pwsh", "-NoProfile", "-File", str(ACTION),
                              "-PluginsFolder", str(self.plugins), *extra],
                              cwd=self.root, capture_output=True, text=True, encoding="utf-8", timeout=90)

    def test_uses_evaluated_project_target_not_dependency(self):
        project, expected = self.project()
        result = self.select()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()), expected)

    def test_multiple_projects_fail_until_explicitly_selected(self):
        project, expected = self.project()
        self.project("Other")
        result = self.select()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("plugin-project", result.stderr)
        result = self.select("-ProjectPath", str(project))
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()), expected)

    def test_multitarget_requires_framework(self):
        project, expected = self.project(multi=True)
        result = self.select()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("plugin-target-framework", result.stderr)
        result = self.select("-TargetFramework", "net8.0")
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(Path(result.stdout.strip()), expected)

    def test_missing_project_output_cannot_fall_back_to_dependency(self):
        project, expected = self.project()
        expected.unlink()
        result = self.select()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("TargetPath", result.stderr)

    def test_no_classic_plugin_project_is_valid(self):
        result = self.select()
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(result.stdout.strip(), "")


@unittest.skipUnless(CLI_COMMAND, "Set PPDS_TEST_CLI_COMMAND to an exact packaged CLI for offline extraction.")
class PackagedCliContract(unittest.TestCase):
    def test_actual_cli_accepts_workflow_options_with_help_only(self):
        # --help short-circuits execution: never authenticate or contact Dataverse.
        _, commands, _ = WorkflowContracts().run_deploy()
        for arguments in commands:
            with self.subTest(command=arguments[:2]):
                result = subprocess.run([*json.loads(CLI_COMMAND), *arguments, "--help"],
                                        cwd=ROOT, capture_output=True, text=True, encoding="utf-8", timeout=90)
                self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn("Usage:", result.stdout)

    def test_actual_workflow_extracts_a_consumer_plugin(self):
        project = ROOT / "tests/fixtures/Plugin/Fixture.Plugin.csproj"
        build = subprocess.run(["dotnet", "build", str(project), "-c", "Release", "--nologo"],
                               cwd=ROOT, capture_output=True, text=True, encoding="utf-8", timeout=180)
        self.assertEqual(build.returncode, 0, build.stdout + build.stderr)
        selected = subprocess.run(["pwsh", "-NoProfile", "-File", str(ACTION), "-ProjectPath", str(project)],
                                  cwd=ROOT, capture_output=True, text=True, encoding="utf-8", timeout=90)
        self.assertEqual(selected.returncode, 0, selected.stderr)
        dll = Path(selected.stdout.strip())
        self.assertEqual(dll.name, "Consumer.Plugin.dll")
        with tempfile.TemporaryDirectory() as d:
            output = Path(d) / "registrations.json"
            script = r"""
function global:ppds {
    $command = ConvertFrom-Json $env:PPDS_TEST_CLI_COMMAND
    $arguments = @($command | Select-Object -Skip 1) + @($args)
    & $command[0] @arguments
    $global:LASTEXITCODE = $LASTEXITCODE
}
""" + steps("plugin-extract.yml", "extract")["extract"]["run"]
            result = run_pwsh(script, d, dict(ASSEMBLY_PATH=str(dll), OUTPUT_PATH=str(output),
                                             GITHUB_OUTPUT=str(Path(d) / "outputs")))
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            config = json.loads(output.read_text(encoding="utf-8-sig"))
            self.assertEqual(config["assemblies"][0]["name"], "Consumer.Plugin")
            self.assertEqual(config["assemblies"][0]["types"][0]["typeName"], "FixturePlugin")
            self.assertEqual(config["assemblies"][0]["types"][0]["steps"][0]["message"], "Create")


if __name__ == "__main__":
    unittest.main(verbosity=2)
