Shader "HDRenderPipeline/LensFlare (HDRP Lerp)"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
	}
	SubShader
	{
		Pass
		{
			Name "ForwardUnlit"
			Tags{ "LightMode" = "Forward"  "RenderQueue" = "Transparent" }

			Blend SrcAlpha OneMinusSrcAlpha
			ColorMask RGB
			ZWrite Off
			Cull Off
			ZTest Always

			HLSLPROGRAM

			#pragma target 5.0
			#pragma vertex vert
			#pragma fragment frag

			#include "Packages/com.unity.render-pipelines.core/ShaderLibrary/Common.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderConfig.cs.hlsl"
			#include "Packages/com.unity.render-pipelines.high-definition/Runtime/ShaderLibrary/ShaderVariables.hlsl"
			#include "LensFlareHDRPCommon.hlsl"

			float4 frag (v2f i) : SV_Target
			{
				float4 col = tex2D(_MainTex, i.uv);
				
				return col * i.color;
			}

			ENDHLSL
		}
	}
}
