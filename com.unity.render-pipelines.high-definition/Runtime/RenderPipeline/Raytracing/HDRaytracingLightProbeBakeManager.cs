using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace UnityEngine.Experimental.Rendering
{
#if ENABLE_RAYTRACING

    public static class HDRaytracingLightProbeBakeManager
    {
        public static bool IsEnabled { get; set; } = false;

        public static event System.Action<HDCamera, CommandBuffer> preRenderLightProbes;
        public static void PreRender(HDCamera camera, CommandBuffer cmdBuffer)
        {
            preRenderLightProbes?.Invoke(camera, cmdBuffer);
        }

        public static event System.Action<HDCamera, CommandBuffer, RayTracingAccelerationStructure, HDRaytracingLightCluster, Texture> bakeLightProbes;
        public static void Bake(HDCamera camera, CommandBuffer cmdBuffer, RayTracingAccelerationStructure accelerationStructure, HDRaytracingLightCluster lightCluster, Texture skyTexture)
        {
            bakeLightProbes?.Invoke(camera, cmdBuffer, accelerationStructure, lightCluster, skyTexture);
        }
    }
#endif
}
