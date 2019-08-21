using System;
using UnityEngine.Rendering;

//custom-begin: quick toggle for scene view panini
#if UNITY_EDITOR
using UnityEditor;

[InitializeOnLoad]
static class PaniniProjectionSceneView
{
    public const string key = "SceneView.PaniniProjection";
    public static bool enabled = false;

    static PaniniProjectionSceneView() { Load(); }

    [SettingsProvider]
    static SettingsProvider SettingsProvider()
    {
        return new SettingsProvider("Preferences/Scene View Extras", SettingsScope.User)
        {
            guiHandler = searchContext => OnGUI()
        };
    }

    static void OnGUI()
    {
        EditorGUILayout.Space();
        EditorGUI.BeginChangeCheck();
        enabled = EditorGUILayout.Toggle("Panini Projection", enabled);
        if (EditorGUI.EndChangeCheck())
        {
            Save();
        }
    }

    static void Load() { enabled = EditorPrefs.GetBool(key, false); }
    static void Save() { EditorPrefs.SetBool(key, enabled); }
}
#else
static class PaniniProjectionSceneView
{
    public const bool enabled = false;
}
#endif
//custom-end:

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    [Serializable, VolumeComponentMenu("Post-processing/Panini Projection")]
    public sealed class PaniniProjection : VolumeComponent, IPostProcessComponent
    {
        [Tooltip("Panini projection distance.")]
        public ClampedFloatParameter distance = new ClampedFloatParameter(0f, 0f, 1f);

        [Tooltip("Panini projection crop to fit.")]
        public ClampedFloatParameter cropToFit = new ClampedFloatParameter(1f, 0f, 1f);

        public bool IsActive()
        {
            return distance.value > 0f;
        }
    }
}
