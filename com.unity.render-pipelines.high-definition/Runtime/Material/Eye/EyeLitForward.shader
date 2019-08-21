Shader "HDRP/EyeLitForward"
{
    Properties
    {
        // Versioning of material to help for upgrading
        [HideInInspector] _HdrpVersion("_HdrpVersion", Float) = 2

        // Following set of parameters represent the parameters node inside the MaterialGraph.
        // They are use to fill a SurfaceData. With a MaterialGraph this should not exist.

        // Reminder. Color here are in linear but the UI (color picker) do the conversion sRGB to linear
        _BaseColor("BaseColor", Color) = (1,1,1,1)
        _BaseColorMap("BaseColorMap", 2D) = "white" {}
        [HideInInspector] _BaseColorMap_MipInfo("_BaseColorMap_MipInfo", Vector) = (0, 0, 0, 0)

        _Metallic("_Metallic", Range(0.0, 1.0)) = 0
        _Smoothness("Smoothness", Range(0.0, 1.0)) = 0.5
//custom-begin: View angle dependent smoothness tweak
        _SmoothnessViewAngleOffset("Smoothness View Angle Offset", Range(0.0, 1.0)) = 0.0
//custom-end:
        _MaskMap("MaskMap", 2D) = "white" {}
        _SmoothnessRemapMin("SmoothnessRemapMin", Float) = 0.0
        _SmoothnessRemapMax("SmoothnessRemapMax", Float) = 1.0
        _AORemapMin("AORemapMin", Float) = 0.0
        _AORemapMax("AORemapMax", Float) = 1.0

        _NormalMap("NormalMap", 2D) = "bump" {}     // Tangent space normal map
        _NormalMapOS("NormalMapOS", 2D) = "white" {} // Object space normal map - no good default value
        _NormalScale("_NormalScale", Range(0.0, 8.0)) = 1

        _BentNormalMap("_BentNormalMap", 2D) = "bump" {}
        _BentNormalMapOS("_BentNormalMapOS", 2D) = "white" {}

        _HeightMap("HeightMap", 2D) = "black" {}
        // Caution: Default value of _HeightAmplitude must be (_HeightMax - _HeightMin) * 0.01
        // Those two properties are computed from the ones exposed in the UI and depends on the displaement mode so they are separate because we don't want to lose information upon displacement mode change.
        [HideInInspector] _HeightAmplitude("Height Amplitude", Float) = 0.02 // In world units. This will be computed in the UI.
        [HideInInspector] _HeightCenter("Height Center", Range(0.0, 1.0)) = 0.5 // In texture space

        [Enum(MinMax, 0, Amplitude, 1)] _HeightMapParametrization("Heightmap Parametrization", Int) = 0
        // These parameters are for vertex displacement/Tessellation
        _HeightOffset("Height Offset", Float) = 0
        // MinMax mode
        _HeightMin("Heightmap Min", Float) = -1
        _HeightMax("Heightmap Max", Float) = 1
        // Amplitude mode
        _HeightTessAmplitude("Amplitude", Float) = 2.0 // in Centimeters
        _HeightTessCenter("Height Center", Range(0.0, 1.0)) = 0.5 // In texture space

        // These parameters are for pixel displacement
        _HeightPoMAmplitude("Height Amplitude", Float) = 2.0 // In centimeters

        _DetailMap("DetailMap", 2D) = "black" {}
        _DetailAlbedoScale("_DetailAlbedoScale", Range(0.0, 2.0)) = 1
        _DetailNormalScale("_DetailNormalScale", Range(0.0, 2.0)) = 1
        _DetailSmoothnessScale("_DetailSmoothnessScale", Range(0.0, 2.0)) = 1

        _TangentMap("TangentMap", 2D) = "bump" {}
        _TangentMapOS("TangentMapOS", 2D) = "white" {}
        _Anisotropy("Anisotropy", Range(-1.0, 1.0)) = 0
        _AnisotropyMap("AnisotropyMap", 2D) = "white" {}

        _SubsurfaceMask("Subsurface Radius", Range(0.0, 1.0)) = 1.0
        _SubsurfaceMaskMap("Subsurface Radius Map", 2D) = "white" {}
        _Thickness("Thickness", Range(0.0, 1.0)) = 1.0
        _ThicknessMap("Thickness Map", 2D) = "white" {}
        _ThicknessRemap("Thickness Remap", Vector) = (0, 1, 0, 0)

        _IridescenceThickness("Iridescence Thickness", Range(0.0, 1.0)) = 1.0
        _IridescenceThicknessMap("Iridescence Thickness Map", 2D) = "white" {}
        _IridescenceThicknessRemap("Iridescence Thickness Remap", Vector) = (0, 1, 0, 0)
        _IridescenceMask("Iridescence Mask", Range(0.0, 1.0)) = 1.0
        _IridescenceMaskMap("Iridescence Mask Map", 2D) = "white" {}

        _CoatMask("Coat Mask", Range(0.0, 1.0)) = 0.0
        _CoatMaskMap("CoatMaskMap", 2D) = "white" {}

        [ToggleUI] _EnergyConservingSpecularColor("_EnergyConservingSpecularColor", Float) = 1.0
        _SpecularColor("SpecularColor", Color) = (1, 1, 1, 1)
        _SpecularColorMap("SpecularColorMap", 2D) = "white" {}

        // Following options are for the GUI inspector and different from the input parameters above
        // These option below will cause different compilation flag.
        [ToggleUI]  _EnableSpecularOcclusion("Enable specular occlusion", Float) = 0.0

        [HDR] _EmissiveColor("EmissiveColor", Color) = (0, 0, 0)
        // Used only to serialize the LDR and HDR emissive color in the material UI,
        // in the shader only the _EmissiveColor should be used
        [HideInInspector] _EmissiveColorLDR("EmissiveColor LDR", Color) = (0, 0, 0)
        _EmissiveColorMap("EmissiveColorMap", 2D) = "white" {}
        [ToggleUI] _AlbedoAffectEmissive("Albedo Affect Emissive", Float) = 0.0
        [HideInInspector] _EmissiveIntensityUnit("Emissive Mode", Int) = 0
        [ToggleUI] _UseEmissiveIntensity("Use Emissive Intensity", Int) = 0
        _EmissiveIntensity("Emissive Intensity", Float) = 1
        _EmissiveExposureWeight("Emissive Pre Exposure", Range(0.0, 1.0)) = 1.0

        _DistortionVectorMap("DistortionVectorMap", 2D) = "black" {}
        [ToggleUI] _DistortionEnable("Enable Distortion", Float) = 0.0
        [ToggleUI] _DistortionDepthTest("Distortion Depth Test Enable", Float) = 1.0
        [Enum(Add, 0, Multiply, 1, Replace, 2)] _DistortionBlendMode("Distortion Blend Mode", Int) = 0
        [HideInInspector] _DistortionSrcBlend("Distortion Blend Src", Int) = 0
        [HideInInspector] _DistortionDstBlend("Distortion Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurSrcBlend("Distortion Blur Blend Src", Int) = 0
        [HideInInspector] _DistortionBlurDstBlend("Distortion Blur Blend Dst", Int) = 0
        [HideInInspector] _DistortionBlurBlendMode("Distortion Blur Blend Mode", Int) = 0
        _DistortionScale("Distortion Scale", Float) = 1
        _DistortionVectorScale("Distortion Vector Scale", Float) = 2
        _DistortionVectorBias("Distortion Vector Bias", Float) = -1
        _DistortionBlurScale("Distortion Blur Scale", Float) = 1
        _DistortionBlurRemapMin("DistortionBlurRemapMin", Float) = 0.0
        _DistortionBlurRemapMax("DistortionBlurRemapMax", Float) = 1.0

            
        [ToggleUI]  _UseShadowThreshold("_UseShadowThreshold", Float) = 0.0
        [ToggleUI]  _AlphaCutoffEnable("Alpha Cutoff Enable", Float) = 0.0
        _AlphaCutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5 
        _AlphaCutoffShadow("_AlphaCutoffShadow", Range(0.0, 1.0)) = 0.5
        _AlphaCutoffPrepass("_AlphaCutoffPrepass", Range(0.0, 1.0)) = 0.5
        _AlphaCutoffPostpass("_AlphaCutoffPostpass", Range(0.0, 1.0)) = 0.5
        [ToggleUI] _TransparentDepthPrepassEnable("_TransparentDepthPrepassEnable", Float) = 0.0
        [ToggleUI] _TransparentBackfaceEnable("_TransparentBackfaceEnable", Float) = 0.0
        [ToggleUI] _TransparentDepthPostpassEnable("_TransparentDepthPostpassEnable", Float) = 0.0
        _TransparentSortPriority("_TransparentSortPriority", Float) = 0

        // Transparency
        [Enum(None, 0, Box, 1, Sphere, 2)]_RefractionModel("Refraction Model", Int) = 0
        [Enum(Proxy, 1, HiZ, 2)]_SSRefractionProjectionModel("Refraction Projection Model", Int) = 0
        _Ior("Index Of Refraction", Range(1.0, 2.5)) = 1.0
        _ThicknessMultiplier("Thickness Multiplier", Float) = 1.0
        _TransmittanceColor("Transmittance Color", Color) = (1.0, 1.0, 1.0)
        _TransmittanceColorMap("TransmittanceColorMap", 2D) = "white" {}
        _ATDistance("Transmittance Absorption Distance", Float) = 1.0
        [ToggleUI] _TransparentWritingMotionVec("_TransparentWritingMotionVec", Float) = 0.0

        // Stencil state

        // Forward
        [HideInInspector] _StencilRef("_StencilRef", Int) = 2 // StencilLightingUsage.RegularLighting
        [HideInInspector] _StencilWriteMask("_StencilWriteMask", Int) = 3 // StencilMask.Lighting
        // GBuffer
        [HideInInspector] _StencilRefGBuffer("_StencilRefGBuffer", Int) = 2 // StencilLightingUsage.RegularLighting
        [HideInInspector] _StencilWriteMaskGBuffer("_StencilWriteMaskGBuffer", Int) = 3 // StencilMask.Lighting
        // Depth prepass
        [HideInInspector] _StencilRefDepth("_StencilRefDepth", Int) = 0 // Nothing
        [HideInInspector] _StencilWriteMaskDepth("_StencilWriteMaskDepth", Int) = 32 // DoesntReceiveSSR
        // Motion vector pass
        [HideInInspector] _StencilRefMV("_StencilRefMV", Int) = 128 // StencilBitMask.ObjectMotionVectors
        [HideInInspector] _StencilWriteMaskMV("_StencilWriteMaskMV", Int) = 128 // StencilBitMask.ObjectMotionVectors
        // Distortion vector pass
        [HideInInspector] _StencilRefDistortionVec("_StencilRefDistortionVec", Int) = 64 // StencilBitMask.DistortionVectors
        [HideInInspector] _StencilWriteMaskDistortionVec("_StencilWriteMaskDistortionVec", Int) = 64 // StencilBitMask.DistortionVectors

        // Blending state
        [HideInInspector] _SurfaceType("__surfacetype", Float) = 0.0
        [HideInInspector] _BlendMode("__blendmode", Float) = 0.0
        [HideInInspector] _SrcBlend("__src", Float) = 1.0
        [HideInInspector] _DstBlend("__dst", Float) = 0.0
        [HideInInspector] _AlphaSrcBlend("__alphaSrc", Float) = 1.0
        [HideInInspector] _AlphaDstBlend("__alphaDst", Float) = 0.0
        [HideInInspector] _ZWrite("__zw", Float) = 1.0
        [HideInInspector] _CullMode("__cullmode", Float) = 2.0
        [HideInInspector] _CullModeForward("__cullmodeForward", Float) = 2.0 // This mode is dedicated to Forward to correctly handle backface then front face rendering thin transparent
        [HideInInspector] _ZTestDepthEqualForOpaque("_ZTestDepthEqualForOpaque", Int) = 4 // Less equal
        [HideInInspector] _ZTestModeDistortion("_ZTestModeDistortion", Int) = 8
        [HideInInspector] _ZTestGBuffer("_ZTestGBuffer", Int) = 4

        [ToggleUI] _EnableFogOnTransparent("Enable Fog", Float) = 1.0
        [ToggleUI] _EnableBlendModePreserveSpecularLighting("Enable Blend Mode Preserve Specular Lighting", Float) = 1.0

        [ToggleUI] _DoubleSidedEnable("Double sided enable", Float) = 0.0
        [Enum(Flip, 0, Mirror, 1, None, 2)] _DoubleSidedNormalMode("Double sided normal mode", Float) = 1
        [HideInInspector] _DoubleSidedConstants("_DoubleSidedConstants", Vector) = (1, 1, -1, 0)

        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3, Planar, 4, Triplanar, 5)] _UVBase("UV Set for base", Float) = 0
        _TexWorldScale("Scale to apply on world coordinate", Float) = 1.0
        [HideInInspector] _InvTilingScale("Inverse tiling scale = 2 / (abs(_BaseColorMap_ST.x) + abs(_BaseColorMap_ST.y))", Float) = 1
        [HideInInspector] _UVMappingMask("_UVMappingMask", Color) = (1, 0, 0, 0)
        [Enum(TangentSpace, 0, ObjectSpace, 1)] _NormalMapSpace("NormalMap space", Float) = 0

        // Following enum should be material feature flags (i.e bitfield), however due to Gbuffer encoding constrain many combination exclude each other
        // so we use this enum as "material ID" which can be interpreted as preset of bitfield of material feature
        // The only material feature flag that can be added in all cases is clear coat
        [Enum(Subsurface Scattering, 0, Standard, 1, Anisotropy, 2, Iridescence, 3, Specular Color, 4, Translucent, 5)] _MaterialID("MaterialId", Int) = 1 // MaterialId.Standard
        [ToggleUI] _TransmissionEnable("_TransmissionEnable", Float) = 1.0

        [Enum(None, 0, Vertex displacement, 1, Pixel displacement, 2)] _DisplacementMode("DisplacementMode", Int) = 0
        [ToggleUI] _DisplacementLockObjectScale("displacement lock object scale", Float) = 1.0
        [ToggleUI] _DisplacementLockTilingScale("displacement lock tiling scale", Float) = 1.0
        [ToggleUI] _DepthOffsetEnable("Depth Offset View space", Float) = 0.0

        [ToggleUI] _EnableGeometricSpecularAA("EnableGeometricSpecularAA", Float) = 0.0
        _SpecularAAScreenSpaceVariance("SpecularAAScreenSpaceVariance", Range(0.0, 1.0)) = 0.1
        _SpecularAAThreshold("SpecularAAThreshold", Range(0.0, 1.0)) = 0.2

        [ToggleUI] _EnableMotionVectorForVertexAnimation("EnableMotionVectorForVertexAnimation", Float) = 0.0

        _PPDMinSamples("Min sample for POM", Range(1.0, 64.0)) = 5
        _PPDMaxSamples("Max sample for POM", Range(1.0, 64.0)) = 15
        _PPDLodThreshold("Start lod to fade out the POM effect", Range(0.0, 16.0)) = 5
        _PPDPrimitiveLength("Primitive length for POM", Float) = 1
        _PPDPrimitiveWidth("Primitive width for POM", Float) = 1
        [HideInInspector] _InvPrimScale("Inverse primitive scale for non-planar POM", Vector) = (1, 1, 0, 0)

        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3)] _UVDetail("UV Set for detail", Float) = 0
        [HideInInspector] _UVDetailsMappingMask("_UVDetailsMappingMask", Color) = (1, 0, 0, 0)
        [ToggleUI] _LinkDetailsWithBase("LinkDetailsWithBase", Float) = 1.0

        [Enum(Use Emissive Color, 0, Use Emissive Mask, 1)] _EmissiveColorMode("Emissive color mode", Float) = 1
        [Enum(UV0, 0, UV1, 1, UV2, 2, UV3, 3, Planar, 4, Triplanar, 5)] _UVEmissive("UV Set for emissive", Float) = 0
        _TexWorldScaleEmissive("Scale to apply on world coordinate", Float) = 1.0
        [HideInInspector] _UVMappingMaskEmissive("_UVMappingMaskEmissive", Color) = (1, 0, 0, 0)

        // Wind
        [ToggleUI]  _EnableWind("Enable Wind", Float) = 0.0
        _InitialBend("Initial Bend", float) = 1.0
        _Stiffness("Stiffness", float) = 1.0
        _Drag("Drag", float) = 1.0
        _ShiverDrag("Shiver Drag", float) = 0.2
        _ShiverDirectionality("Shiver Directionality", Range(0.0, 1.0)) = 0.5

        // Caution: C# code in BaseLitUI.cs call LightmapEmissionFlagsProperty() which assume that there is an existing "_EmissionColor"
        // value that exist to identify if the GI emission need to be enabled.
        // In our case we don't use such a mechanism but need to keep the code quiet. We declare the value and always enable it.
        // TODO: Fix the code in legacy unity so we can customize the beahvior for GI
        _EmissionColor("Color", Color) = (1, 1, 1)

        // HACK: GI Baking system relies on some properties existing in the shader ("_MainTex", "_Cutoff" and "_Color") for opacity handling, so we need to store our version of those parameters in the hard-coded name the GI baking system recognizes.
        _MainTex("Albedo", 2D) = "white" {}
        _Color("Color", Color) = (1,1,1,1)
        _Cutoff("Alpha Cutoff", Range(0.0, 1.0)) = 0.5

        [ToggleUI] _SupportDecals("Support Decals", Float) = 1.0
        [ToggleUI] _ReceivesSSR("Receives SSR", Float) = 1.0

        [HideInInspector] _DiffusionProfile("Obsolete, kept for migration purpose", Int) = 0
        [HideInInspector] _DiffusionProfileAsset("Diffusion Profile Asset", Vector) = (0, 0, 0, 0)
        [HideInInspector] _DiffusionProfileHash("Diffusion Profile Hash", Float) = 0
    }

    HLSLINCLUDE

    #pragma target 4.5
    #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

    //-------------------------------------------------------------------------------------
    // Variant
    //-------------------------------------------------------------------------------------

//custom-begin: trim variants, grafted from Gawain_eyes.mat
    #define _DISABLE_SSR
    #define _MASKMAP
    #define _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
    #define _NORMALMAP
    #define _NORMALMAP_TANGENT_SPACE

//original:
//    #pragma shader_feature_local _ALPHATEST_ON
//    #pragma shader_feature_local _DEPTHOFFSET_ON
//    #pragma shader_feature_local _DOUBLESIDED_ON
//    #pragma shader_feature_local _ _VERTEX_DISPLACEMENT _PIXEL_DISPLACEMENT
//    #pragma shader_feature_local _VERTEX_DISPLACEMENT_LOCK_OBJECT_SCALE
//    #pragma shader_feature_local _DISPLACEMENT_LOCK_TILING_SCALE
//    #pragma shader_feature_local _PIXEL_DISPLACEMENT_LOCK_OBJECT_SCALE
//    #pragma shader_feature_local _VERTEX_WIND
//    #pragma shader_feature_local _ _REFRACTION_PLANE _REFRACTION_SPHERE
//
//    #pragma shader_feature_local _ _EMISSIVE_MAPPING_PLANAR _EMISSIVE_MAPPING_TRIPLANAR
//    #pragma shader_feature_local _ _MAPPING_PLANAR _MAPPING_TRIPLANAR
//    #pragma shader_feature_local _NORMALMAP_TANGENT_SPACE
//    #pragma shader_feature_local _ _REQUIRE_UV2 _REQUIRE_UV3
//
//    #pragma shader_feature_local _NORMALMAP
//    #pragma shader_feature_local _MASKMAP
//    #pragma shader_feature_local _BENTNORMALMAP
//    #pragma shader_feature_local _EMISSIVE_COLOR_MAP
//    #pragma shader_feature_local _ENABLESPECULAROCCLUSION
//    #pragma shader_feature_local _HEIGHTMAP
//    #pragma shader_feature_local _TANGENTMAP
//    #pragma shader_feature_local _ANISOTROPYMAP
//    #pragma shader_feature_local _DETAIL_MAP
//    #pragma shader_feature_local _SUBSURFACE_MASK_MAP
//    #pragma shader_feature_local _THICKNESSMAP
//    #pragma shader_feature_local _IRIDESCENCE_THICKNESSMAP
//    #pragma shader_feature_local _SPECULARCOLORMAP
//    #pragma shader_feature_local _TRANSMITTANCECOLORMAP
//
//    #pragma shader_feature_local _DISABLE_DECALS
//    #pragma shader_feature_local _DISABLE_SSR
//    #pragma shader_feature_local _ENABLE_GEOMETRIC_SPECULAR_AA
//
//    // Keyword for transparent
//    #pragma shader_feature _SURFACE_TYPE_TRANSPARENT
//    #pragma shader_feature_local _ _BLENDMODE_ALPHA _BLENDMODE_ADD _BLENDMODE_PRE_MULTIPLY
//    #pragma shader_feature_local _BLENDMODE_PRESERVE_SPECULAR_LIGHTING
//    #pragma shader_feature_local _ENABLE_FOG_ON_TRANSPARENT
//    #pragma shader_feature_local _TRANSPARENT_WRITES_MOTION_VEC
//
//    // MaterialFeature are used as shader feature to allow compiler to optimize properly
//    #pragma shader_feature_local _MATERIAL_FEATURE_SUBSURFACE_SCATTERING
//    #pragma shader_feature_local _MATERIAL_FEATURE_TRANSMISSION
//    #pragma shader_feature_local _MATERIAL_FEATURE_ANISOTROPY
//    #pragma shader_feature_local _MATERIAL_FEATURE_CLEAR_COAT
//    #pragma shader_feature_local _MATERIAL_FEATURE_IRIDESCENCE
//    #pragma shader_feature_local _MATERIAL_FEATURE_SPECULAR_COLOR
//custom-end:

    // enable dithering LOD crossfade
    #pragma multi_compile _ LOD_FADE_CROSSFADE

    //enable GPU instancing support
    #pragma multi_compile_instancing
    #pragma instancing_options renderinglayer


    //-------------------------------------------------------------------------------------
    // Define
    //-------------------------------------------------------------------------------------

    // This shader support vertex modification
    #define HAVE_VERTEX_MODIFICATION

    // If we use subsurface scattering, enable output split lighting (for forward pass)
    #if defined(_MATERIAL_FEATURE_SUBSURFACE_SCATTERING) && !defined(_SURFACE_TYPE_TRANSPARENT)
    #define OUTPUT_SPLIT_LIGHTING
    #endif

    #if defined(_TRANSPARENT_WRITES_VELOCITY) && defined(_SURFACE_TYPE_TRANSPARENT)
    #define _WRITE_TRANSPARENT_VELOCITY
    #endif
    //-------------------------------------------------------------------------------------
    // Include
    //-------------------------------------------------------------------------------------

    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
    #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Wind.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/FragInputs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPass.cs.hlsl"
    // #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

    //-------------------------------------------------------------------------------------
    // variable declaration
    //-------------------------------------------------------------------------------------

    // Can't include 'ShaderVariables.hlsl' here because of USE_LEGACY_UNITY_MATRIX_VARIABLES. :-(
    // Same story for 'Material.hlsl' (above) which includes 'AtmosphericScattering.hlsl' which includes 'ShaderVariables.hlsl'.
    // #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
    // #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.cs.hlsl"
    #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitProperties.hlsl"

    // TODO:
    // Currently, Lit.hlsl and LitData.hlsl are included for every pass. Split Lit.hlsl in two:
    // LitData.hlsl and LitShading.hlsl (merge into the existing LitData.hlsl).
    // LitData.hlsl should be responsible for preparing shading parameters.
    // LitShading.hlsl implements the light loop API.
    // LitData.hlsl is included here, LitShading.hlsl is included below for shading passes only.

    ENDHLSL

    SubShader
    {
        // This tags allow to use the shader replacement features
        Tags{ "RenderPipeline"="HDRenderPipeline" "RenderType" = "HDLitShader" }

        Pass
        {
            Name "SceneSelectionPass"
            Tags { "LightMode" = "SceneSelectionPass" }

            Cull Off

            HLSLPROGRAM

            // Note: Require _ObjectId and _PassValue variables

            // We reuse depth prepass for the scene selection, allow to handle alpha correctly as well as tessellation and vertex animation
            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #define SCENESELECTIONPASS // This will drive the output of the scene selection shader
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

        Pass
        {
            Name "ShadowCaster"
            Tags{ "LightMode" = "ShadowCaster" }

            Cull[_CullMode]

            ZClip [_ZClip]
            ZWrite On
            ZTest LEqual

            ColorMask 0

            HLSLPROGRAM

            #define SHADERPASS SHADERPASS_SHADOWS
            #define USE_LEGACY_UNITY_MATRIX_VARIABLES
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

        Pass
        {
            Name "DepthOnly"
            Tags{ "LightMode" = "DepthForwardOnly" }

            Cull[_CullMode]

            // To be able to tag stencil with disableSSR information for forward
            Stencil
            {
                WriteMask [_StencilWriteMaskDepth]
                Ref [_StencilRefDepth]
                Comp Always
                Pass Replace
            }

            ZWrite On

            HLSLPROGRAM

            // In deferred, depth only pass don't output anything.
            // In forward it output the normal buffer
//custom-begin: always write normal buffer
            //#pragma multi_compile _ WRITE_NORMAL_BUFFER
            #define WRITE_NORMAL_BUFFER 1
//custom-end:
            #pragma multi_compile _ WRITE_MSAA_DEPTH

            #define SHADERPASS SHADERPASS_DEPTH_ONLY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

//custom-begin: output geometric normal during depth prepass
            #define LIT_SURFACE_DATA_MODIFIER EyeSurfNormal
            #include "Eye.hlsl"

            void EyeSurfNormal(FragInputs input, inout SurfaceData surfaceData)
            {
                EyeData eyeData = GetEyeData(input);

                const float3 scleraNormalWS = surfaceData.normalWS;
                const float scleraSmoothness = surfaceData.perceptualSmoothness;

                // Remove normal mapping from the surface of the cornea, but keep it on the surface of the sclera.
                // The assumption here is that normal map data within the cornea region is intended for the surface
                // of the iris (layer 1) after light has traveled through the optically smooth surface of the cornea (layer 0)
                surfaceData.normalWS = NLerp(input.worldToTangent[2], scleraNormalWS, eyeData.maskSclera);
                surfaceData.perceptualSmoothness = lerp(_EyeCorneaSmoothness, scleraSmoothness, eyeData.maskSclera);
            }
//custom-end:

            #ifdef WRITE_NORMAL_BUFFER // If enabled we need all regular interpolator
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitDepthPass.hlsl"
            #endif

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassDepthOnly.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

        Pass
        {
            Name "MotionVectors"
            Tags{ "LightMode" = "MotionVectors" } // Caution, this need to be call like this to setup the correct parameters by C++ (legacy Unity)

            // If velocity pass (motion vectors) is enabled we tag the stencil so it don't perform CameraMotionVelocity
            Stencil
            {
                WriteMask [_StencilWriteMaskMV]
                Ref [_StencilRefMV]
                Comp Always
                Pass Replace
            }

            Cull[_CullMode]

            ZWrite On

            HLSLPROGRAM
//custom-begin: always write normal buffer
            //#pragma multi_compile _ WRITE_NORMAL_BUFFER
            #define WRITE_NORMAL_BUFFER 1
//custom-end:
            #pragma multi_compile _ WRITE_MSAA_DEPTH
            
            #define SHADERPASS SHADERPASS_MOTION_VECTORS
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"

//custom-begin: output geometric normal during depth prepass
            #define LIT_SURFACE_DATA_MODIFIER EyeSurfNormal
            #include "Eye.hlsl"

            void EyeSurfNormal(FragInputs input, inout SurfaceData surfaceData)
            {
                EyeData eyeData = GetEyeData(input);

                const float3 scleraNormalWS = surfaceData.normalWS;
                const float scleraSmoothness = surfaceData.perceptualSmoothness;

                // Remove normal mapping from the surface of the cornea, but keep it on the surface of the sclera.
                // The assumption here is that normal map data within the cornea region is intended for the surface
                // of the iris (layer 1) after light has traveled through the optically smooth surface of the cornea (layer 0)
                surfaceData.normalWS = NLerp(input.worldToTangent[2], scleraNormalWS, eyeData.maskSclera);
                surfaceData.perceptualSmoothness = lerp(_EyeCorneaSmoothness, scleraSmoothness, eyeData.maskSclera);
            }
//custom-end:

            #ifdef WRITE_NORMAL_BUFFER // If enabled we need all regular interpolator
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #else
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitMotionVectorPass.hlsl"
            #endif
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassMotionVectors.hlsl"

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

        Pass
        {
            Name "Forward"
            Tags { "LightMode" = "ForwardOnly" } // This will be only for transparent object based on the RenderQueue index

            Stencil
            {
                WriteMask [_StencilWriteMask]
                Ref [_StencilRef]
                Comp Always
                Pass Replace
            }

            Blend [_SrcBlend] [_DstBlend]
            // In case of forward we want to have depth equal for opaque mesh
            ZTest [_ZTestDepthEqualForOpaque]
            ZWrite [_ZWrite]
            Cull [_CullModeForward]
            ColorMask [_ColorMaskTransparentVel] 1

            HLSLPROGRAM

            #pragma multi_compile _ DEBUG_DISPLAY
            #pragma multi_compile _ LIGHTMAP_ON
            #pragma multi_compile _ DIRLIGHTMAP_COMBINED
            #pragma multi_compile _ DYNAMICLIGHTMAP_ON
            #pragma multi_compile _ SHADOWS_SHADOWMASK
            // Setup DECALS_OFF so the shader stripper can remove variants
            #pragma multi_compile DECALS_OFF DECALS_3RT DECALS_4RT
            
            // Supported shadow modes per light type
            #pragma multi_compile SHADOW_LOW SHADOW_MEDIUM SHADOW_HIGH SHADOW_VERY_HIGH

            #pragma multi_compile USE_FPTL_LIGHTLIST USE_CLUSTERED_LIGHTLIST

            #define SHADERPASS SHADERPASS_FORWARD
            // In case of opaque we don't want to perform the alpha test, it is done in depth prepass and we use depth equal for ztest (setup from UI)
            // Don't do it with debug display mode as it is possible there is no depth prepass in this case
            #if !defined(_SURFACE_TYPE_TRANSPARENT) && !defined(DEBUG_DISPLAY)
                #define SHADERPASS_FORWARD_BYPASS_ALPHA_TEST
            #endif
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/Lighting.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Material.hlsl"

        #ifdef DEBUG_DISPLAY
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"
        #endif

            // The light loop (or lighting architecture) is in charge to:
            // - Define light list
            // - Define the light loop
            // - Setup the constant/data
            // - Do the reflection hierarchy
            // - Provide sampling function for shadowmap, ies, cookie and reflection (depends on the specific use with the light loops like index array or atlas or single and texture format (cubemap/latlong))

//custom-begin: eye rendering
            #include "Eye.hlsl"

            struct LightTransformData
            {
                float refractMask;
                float3 refractNormalWS;
            };

            void LightTransform(in LightTransformData lightTransformData, in PositionInputs posInput,
                inout float3 lightData_positionRWS,
                inout float3 lightData_forward,
                inout float3 lightData_right,
                inout float3 lightData_up)
            {
                float3 L = normalize(lightData_positionRWS - posInput.positionWS);
                float3 refractL = -refract(-L, lightTransformData.refractNormalWS, _EyeCorneaIndexOfRefractionRatio);

                //float occlusion = 1.0 - saturate(-1.0 * dot(L, lightTransformData.refractNormalWS));
                float occlusion = 1.0;// just ignore this for now, might not need any internal occlusion

                float3 axis = normalize(cross(L, refractL));
                float angle = lerp(0.0, acos(dot(L, refractL)), lightTransformData.refractMask * occlusion);

                lightData_positionRWS = Rotate(posInput.positionWS, lightData_positionRWS, axis, angle);
                lightData_forward = Rotate(float3(0, 0, 0), lightData_forward, axis, angle);
                lightData_right = Rotate(float3(0, 0, 0), lightData_right, axis, angle);
                lightData_up = Rotate(float3(0, 0, 0), lightData_up, axis, angle);
            }

            void LightTransform(in LightTransformData lightTransformData, in PositionInputs posInput, inout LightData lightData)
            {
                LightTransform(lightTransformData, posInput,
                    lightData.positionRWS,
                    lightData.forward,
                    lightData.right,
                    lightData.up);
            }

            void LightTransform(in LightTransformData lightTransformData, in PositionInputs posInput, inout DirectionalLightData lightData)
            {
                LightTransform(lightTransformData, posInput,
                    lightData.positionRWS,
                    lightData.forward,
                    lightData.right,
                    lightData.up);
            }

            // UNUSED (experiment): bend the surface normal per-light, rather than rotating the light
            //void BSDFModifier(BSDFModifierData bsdfModifierData, inout float3 N, inout float3 L, inout float NdotL)
            //{
            //    if (bsdfModifierData.irisFactor && bsdfModifierData.debug)
            //    {
            //        float3 irisN = bsdfModifierData.irisNormalWS;
            //        float3 irisL = normalize(-refract(-L, N, _EyeCorneaIndexOfRefractionRatio));
            //        float irisNdotL = dot(irisN, irisL);
            //        N = NLerp(N, irisN, bsdfModifierData.irisFactor);
            //        L = NLerp(L, irisL, bsdfModifierData.irisFactor);
            //        NdotL = lerp(NdotL, irisNdotL, bsdfModifierData.irisFactor);
            //    }
            //}

            #define LIGHTLOOP_LIGHT_TRANSFORM LightTransform
            #define LIGHTLOOP_LIGHT_TRANSFORM_DATA LightTransformData
//custom-end:

            #define HAS_LIGHTLOOP

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoopDef.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/Lit.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Lighting/LightLoop/LightLoop.hlsl"

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/ShaderPass/LitSharePass.hlsl"
            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Lit/LitData.hlsl"

//custom-begin: (Nick) eye rendering
            //#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/ShaderPassForward.hlsl"
            // the structure of this code initially copied from ShaderPassForward.hlsl

            #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Sampling/SampleUVMapping.hlsl"
            #include "EyeScreenSpaceReflections.hlsl"

            #if SHADERPASS != SHADERPASS_FORWARD
            #error SHADERPASS_is_not_correctly_define
            #endif

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/VertMesh.hlsl"

            PackedVaryingsType Vert(AttributesMesh inputMesh)
            {
                VaryingsType varyingsType;
                varyingsType.vmesh = VertMesh(inputMesh);
                return PackVaryingsType(varyingsType);
            }

            #ifdef TESSELLATION_ON

            PackedVaryingsToPS VertTesselation(VaryingsToDS input)
            {
                VaryingsToPS output;
                output.vmesh = VertMeshTesselation(input.vmesh);
                return PackVaryingsToPS(output);
            }

            #include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/TessellationShare.hlsl"

            #endif // TESSELLATION_ON

            void Frag(PackedVaryingsToPS packedInput,
                    #ifdef OUTPUT_SPLIT_LIGHTING
                        out float4 outColor : SV_Target0,  // outSpecularLighting
                        out float4 outDiffuseLighting : SV_Target1,
                        OUTPUT_SSSBUFFER(outSSSBuffer)
                    #else
                        out float4 outColor : SV_Target0
                    #endif
                    #ifdef _DEPTHOFFSET_ON
                        , out float outputDepth : SV_Depth
                    #endif
                      )
            {
                FragInputs input = UnpackVaryingsMeshToFragInputs(packedInput.vmesh);

                uint2 tileIndex = uint2(input.positionSS.xy) / GetTileSize();
            #if defined(UNITY_SINGLE_PASS_STEREO)
                tileIndex.x -= unity_StereoEyeIndex * _NumTileClusteredX;
            #endif

                // input.positionSS is SV_Position
                PositionInputs posInput = GetPositionInput_Stereo(input.positionSS.xy, _ScreenSize.zw, input.positionSS.z, input.positionSS.w, input.positionRWS.xyz, tileIndex, unity_StereoEyeIndex);

            #ifdef VARYINGS_NEED_POSITION_WS
                float3 V = GetWorldSpaceNormalizeViewDir(input.positionRWS);
            #else
                // Unused
                float3 V = float3(1.0, 1.0, 1.0); // Avoid the division by 0
            #endif

                EyeData eyeData = GetEyeData(input);
                input.texCoord0.xy = eyeData.refractedUV;

                SurfaceData surfaceData;
                BuiltinData builtinData;
                GetSurfaceAndBuiltinData(input, V, posInput, surfaceData, builtinData);

                NormalData normalData;
                DecodeFromNormalBuffer(input.positionSS.xy, normalData);

                // TODO: Currently just using the ASG as diffuse and specular occlusion, applied regardless of light direction.
                // Could evaluate the ASG for each incoming light direction, which would increase visibility accuracy,
                // at the cost of per light ALU.
                surfaceData.ambientOcclusion = eyeData.asgAO;
                surfaceData.specularOcclusion = eyeData.asgAO;
                surfaceData.baseColor *= lerp(1.0, eyeData.asgAO, _EyeAsgModulateAlbedo);
                surfaceData.subsurfaceMask *= lerp(1.0, _EyeCorneaSSS, eyeData.maskCornea);

                outColor = float4(0.0, 0.0, 0.0, 0.0);
                {
                    uint featureFlags = LIGHT_FEATURE_MASK_FLAGS_OPAQUE;

                    // There are multiple transparent layers occuring near the surface of the human eye,
                    // each with unique BSDF properties
                    //
                    // 0: Fluids (tears)
                    // 1: Cornea (lens) surface
                    // 2: Cornea (lens) fluids
                    // 3: Iris surface / sclera surface
                    //
                    // For simplicity and performance, We simplify down to two distinct layers we would like to shade:
                    // Layer 0 (Specular Only): Surface fluids and cornea (lens).
                    // Layer 1 (Diffuse Only): Sclera and iris (post cornea refraction).
                    //
                    // This is a reasonable approximation, as the index of refraction of layers 0-2 are highly similar,
                    // and roughness of layers 0-2 are highly similar (and very low), and layers 0-2 are all highly transparent

                    // For simplicity of implementation, we setup and run the light loop once for each layer,
                    // and rely on dead code removal to strip out unused computations (i.e: diffuse at layer 0, specular at layer 1).
                    // This still incurs the significant cost of walking through our light data twice.
                    // Ideally, for performance, we might write a completely custom BSDF and light loop specialized for our unique BSDF.
                    // Doing so would likely incur high maintinance cost over time (to keep the custom light loop in sync with standard light loop)
                    // and as our eyes typically take up a small percentage of screen pixels, and as HDRP code is volatile (still in preview)
                    // we chose to sacrifice some performance here.
                    //
                    // One problem with this implementation is the specular + diffuse energy conservation no longer follows the typical:
                    // outgoingRadiance = specular + diffuse * (1 - fresnel)
                    // Given that normalLayer0 != normalLayer1
                    // diffuseLayer1 gets scaled by (1 - fresnelLayer1) rather than (1 - fresnelLayer0)
                    // For now, we will call this good enough, as specular + diffuse energy conservation is a hard problem in PBR in general,
                    // and the typical implementation is only plausible approximation to begin with, not a ground truth.

                    BSDFData bsdfData;

                    // Store surface properties before overwrite within layer 0 and 1.
                    const float3 surfaceData_normalWS = surfaceData.normalWS;
                    const float3 surfaceData_perceptualSmoothness = surfaceData.perceptualSmoothness;

                    // Layer 0 (Specular Only): Surface fluids and cornea (lens)
                    float3 layer0SpecularLighting;
                    {
                        // Remove normal mapping from the surface of the cornea, but keep it on the surface of the sclera.
                        // The assumption here is that normal map data within the cornea region is intended for the surface
                        // of the iris (layer 1) after light has traveled through the optically smooth surface of the cornea (layer 0)
                        surfaceData.normalWS = normalData.normalWS;
                        surfaceData.perceptualSmoothness = 1.0 - normalData.perceptualRoughness;

                        bsdfData = ConvertSurfaceDataToBSDFData(input.positionSS.xy, surfaceData);
                        bsdfData.fresnel0 = IorToFresnel0(lerp(_EyeLitIORSclera, _EyeLitIORCornea, eyeData.maskCornea));

                        float4 eyeSSR = float4(0.0, 0.0, 0.0, 0.0);
                        if (_EyeScreenSpaceReflectionsIsEnabled)
                        {
                            float3 surfacePositionWS = GetAbsolutePositionWS(input.positionRWS);
                            eyeSSR = EyeScreenSpaceReflectionsRaytrace(surfacePositionWS, input.positionSS.xy, V, bsdfData);
                            {
                                bsdfData.specularOcclusion = min(eyeData.asgAO, 1.0 - eyeSSR.a);
                            }
                        }

                        PreLightData preLightData = GetPreLightData(V, posInput, bsdfData);

                        LightTransformData lightTransformData;
                        lightTransformData.refractMask = 0.0;
                        lightTransformData.refractNormalWS = float3(0.0, 0.0, 0.0);

                        float3 layer0DiffuseLightingUnused;
#ifdef LIGHTLOOP_LIGHT_TRANSFORM
                        LightLoop(V, posInput, preLightData, bsdfData, builtinData, featureFlags, lightTransformData, layer0DiffuseLightingUnused, layer0SpecularLighting);
#else
                        LightLoop(V, posInput, preLightData, bsdfData, builtinData, featureFlags, layer0DiffuseLightingUnused, layer0SpecularLighting);
#endif

                        float prevExposure = GetPreviousExposureMultiplier();
                        layer0SpecularLighting += eyeSSR.rgb / (prevExposure + (prevExposure == 0.0));
                    }

                    // Layer 1 (Diffuse Only): Sclera and iris (post cornea refraction)
                    float3 layer1DiffuseLighting;
                    {
                        const float3 irisPlaneWS = TransformObjectToWorldDir(float3(0.0, 0.0, 1.0));
                        const float3 irisConvexWS = input.worldToTangent[2];
                        const float3 irisConcaveWS = reflect(-irisConvexWS, irisPlaneWS);

                        const float3 irisNormalTS = SurfaceGradientFromPerturbedNormal(input.worldToTangent[2], surfaceData_normalWS);
                        const float3 irisNormalWS = SurfaceGradientResolveNormal(NLerp(irisConvexWS, irisConcaveWS, _EyeIrisConcavity), irisNormalTS);

                        // Remove normal mapping from the surface of the sclera, but keep it on the surface of the iris.
                        // The assumption here is that normal map data within the the sclera is intented to drive
                        // specular-only distortion from surface wetness.
                        surfaceData.normalWS = NLerp(input.worldToTangent[2], irisNormalWS, eyeData.maskCornea);
                        surfaceData.perceptualSmoothness = 1.0 - normalData.perceptualRoughness;

                        bsdfData = ConvertSurfaceDataToBSDFData(input.positionSS.xy, surfaceData);
                        bsdfData.fresnel0 = IorToFresnel0(lerp(_EyeLitIORSclera, _EyeLitIORCornea, eyeData.maskCornea));

                        PreLightData preLightData = GetPreLightData(V, posInput, bsdfData);

                        LightTransformData lightTransformData;
                        lightTransformData.refractMask = _EyeIrisBentLighting * eyeData.maskCornea;
                        lightTransformData.refractNormalWS = input.worldToTangent[2];

                        float3 layer1SpecularLightingUnused;
#ifdef LIGHTLOOP_LIGHT_TRANSFORM
                        LightLoop(V, posInput, preLightData, bsdfData, builtinData, featureFlags, lightTransformData, layer1DiffuseLighting, layer1SpecularLightingUnused);
#else
                        LightLoop(V, posInput, preLightData, bsdfData, builtinData, featureFlags, layer1DiffuseLighting, layer1SpecularLightingUnused);
#endif

                        layer1DiffuseLighting *= (1.0 - eyeData.maskPupil);
                    }

                    // Apply lighting
                    float3 diffuseLighting = layer1DiffuseLighting;
                    float3 specularLighting = max(0.0, layer0SpecularLighting);

                    diffuseLighting *= GetCurrentExposureMultiplier();
                    specularLighting *= GetCurrentExposureMultiplier();

#ifdef OUTPUT_SPLIT_LIGHTING
                    if (_EnableSubsurfaceScattering != 0 && ShouldOutputSplitLighting(bsdfData))
                    {
                        outColor = float4(specularLighting, 1.0);
                        outDiffuseLighting = float4(TagLightingForSSS(diffuseLighting), 1.0);
                    }
                    else
                    {
                        outColor = float4(diffuseLighting + specularLighting, 1.0);
                        outDiffuseLighting = 0;
                    }
                    ENCODE_INTO_SSSBUFFER(surfaceData, posInput.positionSS, outSSSBuffer);
#else
                    outColor = ApplyBlendMode(diffuseLighting, specularLighting, builtinData.opacity);
                    outColor = EvaluateAtmosphericScattering(posInput, V, outColor);
#endif
                }
            }

            #pragma vertex Vert
            #pragma fragment Frag

            ENDHLSL
        }

//custom-end:
    }

    CustomEditor "Experimental.Rendering.HDPipeline.LitGUI"
}
