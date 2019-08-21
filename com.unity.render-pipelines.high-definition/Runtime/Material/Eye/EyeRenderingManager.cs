//custom-begin: (Nick) eye rendering
using UnityEngine.Rendering;
using System;

namespace UnityEngine.Experimental.Rendering.HDPipeline
{
    public class EyeRenderingManager
    {
        Material m_ScreenSpaceReflectionsMaterial;
        Texture2D m_BlueNoiseTexture;

        RTHandleSystem.RTHandle m_ScreenSpaceReflectionsRT;
        RTHandleSystem.RTHandle m_ColorBufferCopyRT;

        public EyeRenderingManager()
        {
        }

        public void InitBuffers(GBufferManager gbufferManager, RenderPipelineSettings settings)
        {
            m_ScreenSpaceReflectionsRT = RTHandles.Alloc(
                Vector2.one,
                filterMode: FilterMode.Point,
                colorFormat: GraphicsFormat.R16G16B16A16_SFloat,
                enableRandomWrite: false,
                enableMSAA: false,
                name : "EyeScreenSpaceReflections"
            );

            m_ColorBufferCopyRT = RTHandles.Alloc(
                Vector2.one,
                filterMode: FilterMode.Bilinear,
                colorFormat: GraphicsFormat.R16G16B16A16_SFloat,
                enableRandomWrite: false,
                enableMSAA: false,
                name : "ColorBufferCopy"
            );
        }

        public void Build(HDRenderPipelineAsset hdAsset)
        {
            m_BlueNoiseTexture = hdAsset.renderPipelineResources.textures.eyeBlueNoiseTexture;
        }

        public void Cleanup()
        {
            CoreUtils.Destroy(m_ScreenSpaceReflectionsMaterial);

            RTHandles.Release(m_ScreenSpaceReflectionsRT);
            RTHandles.Release(m_ColorBufferCopyRT);
        }

        public void PushGlobalParams(HDCamera hdCamera, CommandBuffer cmd, uint frameIndex)
        {

            int sampleIndex = (int)frameIndex % 2;
            cmd.SetGlobalInt("_SampleIndex", sampleIndex);
        }

        public void SetupScreenSpaceReflectionsData(
            HDCamera hdCamera,
            CommandBuffer cmd,
            RTHandleSystem.RTHandle colorBufferRT,
            RTHandleSystem.RTHandle depthStencilBufferRT,
            RTHandleSystem.RTHandle depthTextureRT,
            HDUtils.PackedMipChainInfo depthPyramidInfo)
        {
            using (new ProfilingSample(cmd, "Setup Eye Screen Space Reflections Data", CustomSamplerId.EyeScreenSpaceReflections.GetSampler()))
            {
                // packed mip offsets
                {
                    float[] depthPyramidMipLevelOffsetsX = new float[8];
                    float[] depthPyramidMipLevelOffsetsY = new float[8];

                    for (int i = 0; i < 8; i++)
                    {
                        int j = i << 1;
                        depthPyramidMipLevelOffsetsX[i] = depthPyramidInfo.mipLevelOffsets[j].x;
                        depthPyramidMipLevelOffsetsY[i] = depthPyramidInfo.mipLevelOffsets[Math.Max(0, j - 1)].y;
                    }

                    cmd.SetGlobalInt("_DepthPyramidMaxMip", depthPyramidInfo.mipLevelCount);
                    cmd.SetGlobalFloatArray("_DepthPyramidMipLevelOffsetsX", depthPyramidMipLevelOffsetsX);
                    cmd.SetGlobalFloatArray("_DepthPyramidMipLevelOffsetsY", depthPyramidMipLevelOffsetsY);
                }

                cmd.SetGlobalTexture("_BlueNoiseTexture", m_BlueNoiseTexture);

                cmd.Blit(colorBufferRT, m_ColorBufferCopyRT);
                cmd.SetGlobalTexture(Shader.PropertyToID("_CameraColorTextureEyeSSR"), m_ColorBufferCopyRT);
            }
        }

    }
}
//custom-end: (Nick) eye rendering