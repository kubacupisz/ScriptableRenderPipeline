//
// This file was automatically generated. Please don't edit by hand.
//

#ifndef PROBEVOLUMESYSTEM_CS_HLSL
#define PROBEVOLUMESYSTEM_CS_HLSL
// Generated from UnityEngine.Experimental.Rendering.HDPipeline.ProbeVolumeEngineData
// PackingRules = Exact
struct ProbeVolumeEngineData
{
    float3 debugColor;
    int payloadIndex;
    float3 rcpPosFaceFade;
    float3 rcpNegFaceFade;
    float rcpDistFadeLen;
    float endTimesRcpDistFadeLen;
};

//
// Accessors for UnityEngine.Experimental.Rendering.HDPipeline.ProbeVolumeEngineData
//
float3 GetDebugColor(ProbeVolumeEngineData value)
{
    return value.debugColor;
}
int GetPayloadIndex(ProbeVolumeEngineData value)
{
    return value.payloadIndex;
}
float3 GetRcpPosFaceFade(ProbeVolumeEngineData value)
{
    return value.rcpPosFaceFade;
}
float3 GetRcpNegFaceFade(ProbeVolumeEngineData value)
{
    return value.rcpNegFaceFade;
}
float GetRcpDistFadeLen(ProbeVolumeEngineData value)
{
    return value.rcpDistFadeLen;
}
float GetEndTimesRcpDistFadeLen(ProbeVolumeEngineData value)
{
    return value.endTimesRcpDistFadeLen;
}

#endif
