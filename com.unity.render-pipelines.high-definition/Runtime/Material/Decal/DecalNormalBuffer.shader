Shader "Hidden/HDRP/Material/Decal/DecalNormalBuffer"
{

    Properties
    {
        // Stencil state
        [HideInInspector] _DecalNormalBufferStencilRef("_DecalNormalBufferStencilRef", Int) = 0           // set at runtime
        [HideInInspector] _DecalNormalBufferStencilReadMask("_DecalNormalBufferStencilReadMask", Int) = 0 // set at runtime
    }

    HLSLINCLUDE

        #pragma target 4.5
        #pragma only_renderers d3d11 ps4 xboxone vulkan metal switch
        #include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
        #include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
		#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/Decal/Decal.hlsl"
		#include "Packages/com.unity.render-pipelines.high-definition/Runtime/Material/NormalBuffer.hlsl"

#if defined(PLATFORM_NEEDS_UNORM_UAV_SPECIFIER) && defined(PLATFORM_SUPPORTS_EXPLICIT_BINDING)
        // Explicit binding is needed on D3D since we bind the UAV to slot 1 and we don't have a colour RT bound to fix a D3D warning.
        RW_TEXTURE2D_X(unorm float4, _NormalBuffer) : register(u1);
//custom-begin: add decal mode for blurring normal buffer
        RW_TEXTURE2D(unorm float, _NormalBlurMask) : register(u2);
        RW_TEXTURE2D(unorm float4, _NormalBlurBuffer) : register(u3);
//custom-end:
#else
        RW_TEXTURE2D_X(float4, _NormalBuffer);
//custom-begin: add decal mode for blurring normal buffer
        RW_TEXTURE2D(float, _NormalBlurMask);
        RW_TEXTURE2D(float4, _NormalBlurBuffer);
//custom-end:
#endif

        struct Attributes
        {
            uint vertexID : SV_VertexID;
            UNITY_VERTEX_INPUT_INSTANCE_ID
        };

        struct Varyings
        {
            float4 positionCS : SV_POSITION;
            float2 texcoord   : TEXCOORD0;
            UNITY_VERTEX_OUTPUT_STEREO
        };

        DECLARE_DBUFFER_TEXTURE(_DBufferTexture);

        Varyings Vert(Attributes input)
        {
            Varyings output;
            UNITY_SETUP_INSTANCE_ID(input);
            UNITY_INITIALIZE_VERTEX_OUTPUT_STEREO(output);
            output.positionCS = GetFullScreenTriangleVertexPosition(input.vertexID);
            output.texcoord = GetFullScreenTriangleTexCoord(input.vertexID);
            return output;
        }

        // Force the stencil test before the UAV write.
        [earlydepthstencil]
        void FragNearest(Varyings input)
        {
            UNITY_SETUP_STEREO_EYE_INDEX_POST_VERTEX(input);
            FETCH_DBUFFER(DBuffer, _DBufferTexture, input.texcoord * _ScreenSize.xy);
            DecalSurfaceData decalSurfaceData;
            DECODE_FROM_DBUFFER(DBuffer, decalSurfaceData);

            uint2 positionSS = uint2(input.texcoord * _ScreenSize.xy);
            float4 GBufferNormal = _NormalBuffer[COORD_TEXTURE2D_X(positionSS)];
            NormalData normalData;
            DecodeFromNormalBuffer(GBufferNormal, uint2(0, 0), normalData);
            normalData.normalWS.xyz = normalize(normalData.normalWS.xyz * decalSurfaceData.normalWS.w + decalSurfaceData.normalWS.xyz);
            EncodeIntoNormalBuffer(normalData, uint2(0, 0), GBufferNormal);
            _NormalBuffer[COORD_TEXTURE2D_X(positionSS)] = GBufferNormal;
        }

//custom-begin: add decal mode for blurring normal buffer
        float4 DecodeNormalBufferFloat4(int2 sspos)
        {
            NormalData normalData;
            DecodeFromNormalBuffer(_NormalBuffer[COORD_TEXTURE2D_X(sspos)], uint2(0, 0), normalData);
            return float4(normalData.normalWS, normalData.perceptualRoughness);
        }

        [earlydepthstencil]
        void FragNearest_BlurNormal_Mask(Varyings input)
        {
            _NormalBlurMask[input.positionCS.xy] = 1;
        }

        [earlydepthstencil]
        void FragNearest_BlurNormal_Conv(Varyings input)
        {
            int2 sspos = input.positionCS.xy;

            const int MAX_EXT = 20;
            const float RCP_MAX_EXT = 1.0 / float(MAX_EXT);

            // binary search for edge of decal
            int ext_hi = MAX_EXT;
            int ext_lo = 0;
            while (ext_hi > ext_lo)
            {
                int mid = (ext_lo + ext_hi + 1) >> 1;

                float4 outside = float4(
                    _NormalBlurMask.Load(sspos + int2(-mid,    0)),
                    _NormalBlurMask.Load(sspos + int2( mid,    0)),
                    _NormalBlurMask.Load(sspos + int2(   0, -mid)),
                    _NormalBlurMask.Load(sspos + int2(   0,  mid)));

                if (any(outside))// if any of the samples are outside the blur decal
                    ext_hi = mid - 1;
                else
                    ext_lo = mid;
            }
            int ext = ext_lo;

            // blur within decal
            const float sigma = ext / 1.5 + FLT_EPS;
            const float rcp_2sigmasq = -1.0 / (2.0 * sigma * sigma);

            float4 sum = 0.0;
            float wsum = 0.0;

            for (int dy = -ext; dy <= ext; dy++)
            {
                for (int dx = -ext; dx <= ext; dx++)
                {
                    float dd = dx * dx + dy * dy;
                    float w = exp(dd * rcp_2sigmasq);
                    sum += w * DecodeNormalBufferFloat4(sspos + int2(dx, dy));
                    wsum += w;
                }
            }

            sum.xyz = normalize(sum.xyz);
            sum.a = sum.a / wsum;

//#define STRICT_TEARLINE
#ifdef STRICT_TEARLINE
            float4 raw = DecodeNormalBufferFloat4(sspos);

            const float tearlineRoughness = 0.3;
            float tearlineDotN = abs(dot(sum.xyz, raw.xyz));
            float tearline = 2.0 * saturate((1.0 - pow(tearlineDotN, 16)) - 0.5);
#else
            float tearline = ext * RCP_MAX_EXT;
#endif

            // write new data
            NormalData normalData;
            normalData.normalWS = sum.xyz;
            normalData.perceptualRoughness = sum.a;// lerp(sum.a, 0.2, tearline);

            // encode
            float4 GBufferNormal;
            EncodeIntoNormalBuffer(normalData, uint2(0, 0), GBufferNormal);
            _NormalBlurBuffer[sspos] = GBufferNormal;
        }

        [earlydepthstencil]
        void FragNearest_BlurNormal_Blit(Varyings input)
        {
            _NormalBuffer[COORD_TEXTURE2D_X(input.positionCS.xy)] = _NormalBlurBuffer[input.positionCS.xy];
        }

        void FragNearest_BlurNormal_Zero(Varyings input)
        {
            // this only serves to clear specific stencil mask
        }
//custom-end:

    ENDHLSL

    SubShader
    {
        Tags{ "RenderPipeline" = "HDRenderPipeline" }

        Pass
        {
            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            Stencil
            {
                WriteMask [_DecalNormalBufferStencilReadMask]
                ReadMask [_DecalNormalBufferStencilReadMask]
                Ref [_DecalNormalBufferStencilRef]
                Comp Equal
//custom-begin: add decal mode for blurring normal buffer
                //Pass Zero   // Clear bits since they are not needed anymore.
                Pass Keep     // ^^ clear moved to separate pass after blurring normals
//custom-end:
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragNearest
            ENDHLSL
        }

//custom-begin: add decal mode for blurring normal buffer
        Pass// 1 mask exterior
        {
            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            Stencil
            {
                ReadMask[_DecalNormalBufferStencilReadMask]
                Ref[_DecalNormalBufferStencilRef]
                Comp NotEqual
                Pass Keep
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragNearest_BlurNormal_Mask
            ENDHLSL
        }

        Pass// 2 conv interior
        {
            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            Stencil
            {
                ReadMask[_DecalNormalBufferStencilReadMask]
                Ref[_DecalNormalBufferStencilRef]
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragNearest_BlurNormal_Conv
            ENDHLSL
        }

        Pass// 3 blit interior
        {
            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            Stencil
            {
                ReadMask[_DecalNormalBufferStencilReadMask]
                Ref[_DecalNormalBufferStencilRef]
                Comp Equal
                Pass Keep
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragNearest_BlurNormal_Blit
            ENDHLSL
        }

        Pass// 4 zero stencil
        {
            ZWrite Off
            ZTest Always
            Blend Off
            Cull Off

            Stencil
            {
                WriteMask[_DecalNormalBufferStencilReadMask]
                ReadMask[_DecalNormalBufferStencilReadMask]
                Ref[_DecalNormalBufferStencilRef]
                Comp Equal
                Pass Zero
            }

            HLSLPROGRAM
                #pragma vertex Vert
                #pragma fragment FragNearest_BlurNormal_Zero
            ENDHLSL
        }
//custom-end:
    }

    Fallback Off
}
