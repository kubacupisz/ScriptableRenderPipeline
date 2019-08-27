using System;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    [GenerateHLSL]
    public enum DebugLightingMode
    {
        None,
        DiffuseLighting,
        SpecularLighting,
        LuxMeter,
        LuminanceMeter,
        VisualizeCascade,
        VisualizeShadowMasks,
        IndirectDiffuseOcclusion,
        IndirectSpecularOcclusion,
        ProbeVolume
    }

    [GenerateHLSL]
    public enum ShadowMapDebugMode
    {
        None,
        VisualizeAtlas,
        VisualizeShadowMap,
        SingleShadow,
    }

    [GenerateHLSL]
    public enum ProbeVolumeDebugMode
    {
        None,
        VisualizeAtlas
    }

    [Serializable]
    public class LightingDebugSettings
    {
        public bool IsDebugDisplayEnabled()
        {
            return debugLightingMode != DebugLightingMode.None
                || overrideSmoothness
                || overrideAlbedo
                || overrideNormal
                || overrideSpecularColor
                || overrideEmissiveColor
                || shadowDebugMode == ShadowMapDebugMode.SingleShadow
                || probeVolumeDebugMode == ProbeVolumeDebugMode.VisualizeAtlas;
        }

        public bool IsDebugDisplayRemovePostprocess()
        {
            return debugLightingMode != DebugLightingMode.None;
        }

        public DebugLightingMode    debugLightingMode = DebugLightingMode.None;
        public ShadowMapDebugMode   shadowDebugMode = ShadowMapDebugMode.None;
        public ProbeVolumeDebugMode probeVolumeDebugMode = ProbeVolumeDebugMode.None;
        public float                probeVolumeMinValue = 0.0f;
        public float                probeVolumeMaxValue = 1.0f;
        public bool                 shadowDebugUseSelection = false;
        public uint                 shadowMapIndex = 0;
        public uint                 shadowAtlasIndex = 0;
        public uint                 shadowSliceIndex = 0;
        public float                shadowMinValue = 0.0f;
        public float                shadowMaxValue = 1.0f;
        public float                shadowResolutionScaleFactor = 1.0f;
        public bool                 clearShadowAtlas = false;

        public bool                 overrideSmoothness = false;
        public float                overrideSmoothnessValue = 0.5f;
        public bool                 overrideAlbedo = false;
        public Color                overrideAlbedoValue = new Color(0.5f, 0.5f, 0.5f);
        public bool                 overrideNormal = false;
        public bool                 overrideSpecularColor = false;
        public Color                overrideSpecularColorValue = new Color(1.0f, 1.0f, 1.0f);
        public bool                 overrideEmissiveColor = false;
        public Color                overrideEmissiveColorValue = new Color(1.0f, 1.0f, 1.0f);

        public bool                 displaySkyReflection = false;
        public float                skyReflectionMipmap = 0.0f;

        public bool                         displayLightVolumes = false;
        public LightLoop.LightVolumeDebug   lightVolumeDebugByCategory = LightLoop.LightVolumeDebug.Gradient;
        public uint                         maxDebugLightCount = 24;

        public float                environmentProxyDepthScale = 20;

        public float                debugExposure = 0.0f;

        public bool                 showPunctualLight = true;
        public bool                 showDirectionalLight = true;
        public bool                 showAreaLight = true;
        public bool                 showReflectionProbe = true;

        public LightLoop.TileClusterDebug tileClusterDebug = LightLoop.TileClusterDebug.None;
        public LightLoop.TileClusterCategoryDebug tileClusterDebugByCategory = LightLoop.TileClusterCategoryDebug.Punctual;
    }
}
