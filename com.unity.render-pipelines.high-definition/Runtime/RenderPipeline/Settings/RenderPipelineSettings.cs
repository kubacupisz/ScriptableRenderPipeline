using System;
using UnityEngine.Experimental.Rendering;

namespace UnityEngine.Rendering.HighDefinition
{
    // RenderPipelineSettings define settings that can't be change during runtime. It is equivalent to the GraphicsSettings of Unity (Tiers + shader variant removal).
    // This allow to allocate resource or not for a given feature.
    // FrameSettings control within a frame what is enable or not(enableShadow, enableDistortion...).
    // HDRenderPipelineAsset reference the current RenderPipelineSettings used, there is one per supported platform(Currently this feature is not implemented and only one GlobalFrameSettings is available).
    // A Camera with HDAdditionalData has one FrameSettings that configures how it will render. For example a camera used for reflection will disable distortion and post-process.
    // Additionally, on a Camera there is another FrameSettings called ActiveFrameSettings that is created on the fly based on FrameSettings and allows modifications for debugging purpose at runtime without being serialized on disk.
    // The ActiveFrameSettings is registered in the debug windows at the creation of the camera.
    // A Camera with HDAdditionalData has a RenderPath that defines if it uses a "Default" FrameSettings, a preset of FrameSettings or a custom one.
    // HDRenderPipelineAsset contains a "Default" FrameSettings that can be referenced by any camera with RenderPath.Defaut or when the camera doesn't have HDAdditionalData like the camera of the Editor.
    // It also contains a DefaultActiveFrameSettings

    // RenderPipelineSettings represents settings that are immutable at runtime.
    // There is a dedicated RenderPipelineSettings for each platform
    [Serializable]
    public struct RenderPipelineSettings
    {
        public enum SupportedLitShaderMode
        {
            ForwardOnly = 1 << 0,
            DeferredOnly = 1 << 1,
            Both = ForwardOnly | DeferredOnly
        }

        public enum RaytracingTier
        {
            Tier1 = 1 << 0,
            Tier2 = 1 << 1
        }

        public enum ColorBufferFormat
        {
            R11G11B10 = GraphicsFormat.B10G11R11_UFloatPack32,
            R16G16B16A16 = GraphicsFormat.R16G16B16A16_SFloat
        }

        /// <summary>Default RenderPipelineSettings</summary>
        public static readonly RenderPipelineSettings @default = new RenderPipelineSettings()
        {
            supportShadowMask = true,
            supportSSAO = true,
            supportSubsurfaceScattering = true,
            supportVolumetrics = true,
//custom-begin: custom high-quality volumetrics level
            volumetricsHQTileSize = 6,
//custom-end:
            supportDistortion = true,
            supportTransparentBackface = true,
            supportTransparentDepthPrepass = true,
            supportTransparentDepthPostpass = true,
            colorBufferFormat = ColorBufferFormat.R11G11B10,
            supportedLitShaderMode = SupportedLitShaderMode.DeferredOnly,
            supportDecals = true,
            msaaSampleCount = MSAASamples.None,
            supportMotionVectors = true,
            supportRuntimeDebugDisplay = true,
            supportDitheringCrossFade = true,
            supportTerrainHole = false,
            lightLoopSettings = GlobalLightLoopSettings.@default,
            hdShadowInitParams = HDShadowInitParameters.@default,
            decalSettings = GlobalDecalSettings.@default,
            postProcessSettings = GlobalPostProcessSettings.@default,
            dynamicResolutionSettings = GlobalDynamicResolutionSettings.@default,
            lowresTransparentSettings = GlobalLowResolutionTransparencySettings.@default,
            supportRayTracing = false,
            supportedRaytracingTier = RaytracingTier.Tier2,
            supportProbeVolume = false,
            probeVolumeSettings = GlobalProbeVolumeSettings.@default,
        };

        // Lighting
        public bool supportShadowMask;
        public bool supportSSR;
        public bool supportSSAO;
        public bool supportSubsurfaceScattering;
        public bool increaseSssSampleCount;
        public bool supportVolumetrics;
        public bool increaseResolutionOfVolumetrics;
//custom-begin: custom high-quality volumetrics level
        [Range(2, 6)] public int volumetricsHQTileSize;
//custom-end:
        public bool supportLightLayers;
        public bool supportDistortion;
        public bool supportTransparentBackface;
        public bool supportTransparentDepthPrepass;
        public bool supportTransparentDepthPostpass;
        public ColorBufferFormat colorBufferFormat;
        public SupportedLitShaderMode supportedLitShaderMode;

        // Engine
        public bool supportDecals;

        public MSAASamples msaaSampleCount;
        public bool supportMSAA
        {
            get
            {
                return msaaSampleCount != MSAASamples.None;
            }
        }

        public bool supportMotionVectors;
        public bool supportRuntimeDebugDisplay;
        public bool supportDitheringCrossFade;
        public bool supportTerrainHole;
        public bool supportProbeVolume;
        public bool supportRayTracing;
        public RaytracingTier supportedRaytracingTier;

        public GlobalProbeVolumeSettings probeVolumeSettings;
        public GlobalLightLoopSettings lightLoopSettings;
        public HDShadowInitParameters hdShadowInitParams;
        public GlobalDecalSettings decalSettings;
        public GlobalPostProcessSettings postProcessSettings;
        public GlobalDynamicResolutionSettings dynamicResolutionSettings;
        public GlobalLowResolutionTransparencySettings lowresTransparentSettings;
    }
}
