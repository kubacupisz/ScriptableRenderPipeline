#if SHADER_STAGE_RAY_TRACING
StructuredBuffer<uint>                      _RaytracingLightCluster : register(GLOBAL_RAY_TRACING_LIGHT_CLUSTER_REGISTER, space1);
StructuredBuffer<LightData>                 _LightDatasRT           : register(GLOBAL_RAY_TRACING_LIGHT_DATA_REGISTER, space1);
StructuredBuffer<EnvLightData>              _EnvLightDatasRT        : register(GLOBAL_RAY_TRACING_ENV_LIGHT_DATA_REGISTER, space1);
#else
StructuredBuffer<uint>                      _RaytracingLightCluster;
StructuredBuffer<LightData>                 _LightDatasRT;
StructuredBuffer<EnvLightData>              _EnvLightDatasRT;
#endif

#if SHADER_STAGE_RAY_TRACING
RAY_TRACING_GLOBAL_CBUFFER_START(UnityRayTracingLightLoop, UNITY_RAY_TRACING_LIGHT_LOOP_CBUFFER_REGISTER)
#else
CBUFFER_START(UnityRayTracingLightLoop)
#endif

uint                                        _LightPerCellCount;
float3                                      _MinClusterPos;
float3                                      _MaxClusterPos;
uint                                        _PunctualLightCountRT;
uint                                        _AreaLightCountRT;
uint                                        _EnvLightCountRT;

CBUFFER_END // UnityRayTracingLightLoop
