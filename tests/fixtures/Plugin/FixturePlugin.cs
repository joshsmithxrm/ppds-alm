using System;
using Microsoft.Xrm.Sdk;
using PPDS.Plugins;

[PluginStep(Message = "Create", EntityLogicalName = "account",
    Stage = PluginStage.PostOperation, Mode = PluginMode.Synchronous)]
public sealed class FixturePlugin : IPlugin
{
    public void Execute(IServiceProvider serviceProvider) { }
}
