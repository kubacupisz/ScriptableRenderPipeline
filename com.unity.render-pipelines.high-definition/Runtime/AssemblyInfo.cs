using System.Runtime.CompilerServices;

[assembly: InternalsVisibleTo("Unity.RenderPipelines.HighDefinition.Editor")]
[assembly: InternalsVisibleTo("Unity.RenderPipelines.HighDefinition.Editor.Tests")]
[assembly: InternalsVisibleTo("Unity.RenderPipelines.HighDefinition.Runtime.Tests")]

//custom-begin: Expose internal guts to dependencies
[assembly: InternalsVisibleTo("Unity.DemoTeam.Playables")]
[assembly: InternalsVisibleTo("PropertyMaster")]
[assembly: InternalsVisibleTo("Unity.Demo.VFXLookDev")]
//custom-end: