using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace UnityEngine.Experimental.Rendering
{
#if ENABLE_RAYTRACING

    public static class HDRaytracingLightProbeBakeManager
    {
        public static event System.Action<HDCamera, CommandBuffer> preRenderLightProbes;
        public static void PreRender(HDCamera camera, CommandBuffer cmdBuffer)
        {
            preRenderLightProbes?.Invoke(camera, cmdBuffer);
        }

        public static event System.Action<HDCamera, CommandBuffer, Texture> bakeLightProbes;
        public static void Bake(HDCamera camera, CommandBuffer cmdBuffer, Texture skyTexture)
        {
            bakeLightProbes?.Invoke(camera, cmdBuffer, skyTexture);
        }
    }
#endif
}
