Shader "Hidden/ScriptableRenderPipeline/DebugDisplayProbeVolume"
{
    HLSLINCLUDE
        #pragma target 4.5
        #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch

        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
        #include "Packages/com.unity.render-pipelines.high-definition/Runtime/Debug/DebugDisplay.hlsl"

        float4  _TextureScaleBias;
        float2  _ValidRange;
        int _ProbeVolumeAtlasSliceMode;
        // float   _RcpGlobalScaleFactor;
        SamplerState ltc_linear_clamp_sampler;
        TEXTURE2D_ARRAY(_AtlasTextureSH);

        struct Attributes
        {
            uint vertexID : VERTEXID_SEMANTIC;
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord : TEXCOORD0;
        };

        Varyings Vert(Attributes input)
        {
            Varyings output;
            output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
            output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
            output.texcoord = output.texcoord * _TextureScaleBias.xy + _TextureScaleBias.zw;
            return output;
        }
    ENDHLSL

    SubShader
    {
        Pass
        {
            Name "ProbeVolume"
            ZTest Off
            Blend One Zero
            Cull Off
            ZWrite On

            HLSLPROGRAM

            #pragma vertex Vert
            #pragma fragment Frag

            float4 Frag(Varyings input) : SV_Target
            {
                float4 valueShAr = saturate((SAMPLE_TEXTURE2D_ARRAY_LOD(_AtlasTextureSH, ltc_linear_clamp_sampler, input.texcoord, 0, 0) - _ValidRange.x) * _ValidRange.y);
                float4 valueShAg = saturate((SAMPLE_TEXTURE2D_ARRAY_LOD(_AtlasTextureSH, ltc_linear_clamp_sampler, input.texcoord, 1, 0) - _ValidRange.x) * _ValidRange.y);
                float4 valueShAb = saturate((SAMPLE_TEXTURE2D_ARRAY_LOD(_AtlasTextureSH, ltc_linear_clamp_sampler, input.texcoord, 2, 0) - _ValidRange.x) * _ValidRange.y);
                float valueValidity = saturate((SAMPLE_TEXTURE2D_ARRAY_LOD(_AtlasTextureSH, ltc_linear_clamp_sampler, input.texcoord, 3, 0).x - _ValidRange.x) * _ValidRange.y);


                switch (_ProbeVolumeAtlasSliceMode)
                {
                    case PROBEVOLUMEATLASSLICEMODE_IRRADIANCESH00:
                    {

                        return float4(valueShAr.x, valueShAg.x, valueShAb.x, 1);
                    }

                    case PROBEVOLUMEATLASSLICEMODE_IRRADIANCESH1_1:
                    {
                        return float4(valueShAr.y, valueShAg.y, valueShAb.y, 1);
                    }

                    case PROBEVOLUMEATLASSLICEMODE_IRRADIANCESH10:
                    {
                        return float4(valueShAr.z, valueShAg.z, valueShAb.z, 1);
                    }

                    case PROBEVOLUMEATLASSLICEMODE_IRRADIANCESH11:
                    {
                        return float4(valueShAr.w, valueShAg.w, valueShAb.w, 1);
                    }

                    case PROBEVOLUMEATLASSLICEMODE_VALIDITY:
                    {
                        return float4(lerp(float3(1, 0, 0), float3(0, 1, 0), valueValidity), 1);
                    }

                    default: return float4(0.0, 0.0, 0.0, 1.0);
                }

            }

            ENDHLSL
        }

    }
    Fallback Off
}
