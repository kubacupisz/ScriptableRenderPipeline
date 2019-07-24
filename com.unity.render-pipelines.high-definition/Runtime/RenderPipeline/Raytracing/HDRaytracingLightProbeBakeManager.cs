using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace UnityEngine.Experimental.Rendering.HighDefinition
{
#if ENABLE_RAYTRACING

    public static class HDRaytracingLightProbeBakeManager
    {
        public static event System.Action<Camera, CommandBuffer> preRenderLightProbes;
        public static void PreRender(Camera camera, CommandBuffer cmdBuffer)
        {
            preRenderLightProbes?.Invoke(camera, cmdBuffer);
        }

        public static event System.Action<Camera, CommandBuffer, Texture> bakeLightProbes;
        public static void Bake(Camera camera, CommandBuffer cmdBuffer, Texture skyTexture)
        {
            bakeLightProbes?.Invoke(camera, cmdBuffer, skyTexture);
        }
    }
#endif
}
