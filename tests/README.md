# Offline contract tests

These tests execute the PowerShell scripts extracted from the working tree's workflows and the actual `build-solution` helper. They do not consume published ALM `@v1` or `@main` actions.

Prerequisites: Python 3.10+, PowerShell 7, .NET SDK 8+.

```powershell
python -m pip install -r tests/requirements.txt
python -m unittest discover -s tests -v
```

The default suite evaluates MSBuild projects with competing dependency DLLs, imported assembly names, multiple projects/frameworks, and missing outputs. It also builds a package-free solution to verify output paths and assembly names conditioned on solution properties, including single-framework re-evaluation. It mocks the `ppds` boundary to assert exact auth/extract/diff/deploy arguments and output handling, including failure cleanup and genuine drift exit code 1. It also checks that consumer workflows acquire actions through the defining `job.workflow_repository` / `job.workflow_sha`, forward project selectors, and reject missing identity or an occupied reserved directory.

To include a real packaged CLI extraction, set `PPDS_TEST_CLI_COMMAND` to a JSON argv array identifying the exact CLI executable or full package DLL. The test builds the net462 fixture with published PPDS.Plugins 3.0.0, selects its evaluated assembly, and executes the workflow's extraction script. Restore uses the fixture's NuGet.Config and can download public packages; extraction itself is offline.

Auth create/delete and plugin diff/deploy probes use `--help` only. Both tested CLI packages return exit zero and help even with a nonexistent option, so this is **not evidence of successful argument parsing**. The tests instead compare the workflow's exact option names, value requirements and enum choices with the declarations in actual command help. Negative controls verify that a nonexistent option is rejected by this evidence check even when help succeeds; unit cases reject prefixes and names mentioned only in descriptions. These checks establish advertised syntax, not runtime parsing or live authentication, comparison, or deployment behavior. The separate workflow mocks and actual extraction test retain their respective coverage.

```powershell
$env:PPDS_TEST_CLI_COMMAND = '["dotnet","C:/tools/ppds-cli-1.4.1/ppds.dll"]'
python -m unittest discover -s tests -v
```

The DLL must remain beside its complete packaged dependencies. `PPDS_TEST_CLI_COMMAND` can instead be `["/path/to/local/tool/ppds"]`; a singleton-command regression checks that this remains an argv array. CI installs exactly PPDS.Cli 1.4.1 to a job-local tool directory and runs this check inside the existing `Validate YAML` required context. The prepared 1.0.1 patch was also checked with the 1.4.2 candidate; it does not publish either version or validate live environment deployment.

In a restricted local workspace, point `TEMP`, `TMP`, and `NUGET_PACKAGES` at writable directories before running. Test build artifacts and repository `tmp/` are ignored by Git.

`actionlint` 1.7.12 currently reports the new documented `job.workflow_*` fields as undefined ([upstream issue](https://github.com/rhysd/actionlint/issues/757)). Keep these fields: using the caller's `github` context would fetch the wrong repository/revision. The offline tests validate these bindings directly; the workflows fail closed if GitHub does not supply them.
