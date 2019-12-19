#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/Raytracing/Shaders/RayTracingLightCluster.hlsl"

#define USE_LIGHT_CLUSTER 

    // Grab the light count
    lightStart = lightCategory == 0 ? 0 : (lightCategory == 1 ? GetPunctualLightClusterCellCount(cellIndex) : GetAreaLightClusterCellCount(cellIndex));
    lightEnd = lightCategory == 0 ? GetPunctualLightClusterCellCount(cellIndex) : (lightCategory == 1 ? GetAreaLightClusterCellCount(cellIndex) : GetEnvLightClusterCellCount(cellIndex));
}

LightData FetchClusterLightIndex(int cellIndex, uint lightIndex)
{
    int absoluteLightIndex = GetLightClusterCellLightByIndex(cellIndex, lightIndex);
    return _LightDatasRT[absoluteLightIndex];
}

EnvLightData FetchClusterEnvLightIndex(int cellIndex, uint lightIndex)
{
    int absoluteLightIndex = GetLightClusterCellLightByIndex(cellIndex, lightIndex);
    return _EnvLightDatasRT[absoluteLightIndex];
}

#if defined(RT_SUN_OCC)
RaytracingAccelerationStructure raytracingAccelStruct;
#endif

float3 offsetRay(float3 p, float3 n)
{
    float  kOrigin     = 1.0f / 32.0f;
    float  kFloatScale = 1.0f / 65536.0f;
    float  kIntScale   = 256.0f;
    int3   of_i        = n * kIntScale;
    float3 p_i         = asfloat(asint(p) + ((p < 0) ? -of_i : of_i));

    return abs(p) < kOrigin ? (p + kFloatScale * n) : p_i;
}

void LightLoop( float3 V, PositionInputs posInput, PreLightData preLightData, BSDFData bsdfData, BuiltinData builtinData, 
            float reflectionHierarchyWeight, float refractionHierarchyWeight, float3 reflection, float3 transmission,
			out float3 diffuseLighting,
            out float3 specularLighting)
{
    LightLoopContext context;
    context.contactShadow    = 1.0;
    context.shadowContext    = InitShadowContext();
    context.shadowValue      = 1.0;
    context.sampleReflection = 0;

    // Initialize the contactShadow and contactShadowFade fields
    InvalidateConctactShadow(posInput, context);
    
#if defined(RT_SUN_OCC)
    // Evaluate sun shadows.
    if (_DirectionalShadowIndex >= 0)
    {
        DirectionalLightData light = _DirectionalLightDatas[_DirectionalShadowIndex];

        if (dot(bsdfData.normalWS, -light.forward) > 0.0)
        {
            const float kTMin = 1e-6f;
            const float kTMax = 1e10f;
            RayDesc rayDescriptor;
            rayDescriptor.Origin    = offsetRay(GetAbsolutePositionWS(posInput.positionWS), bsdfData.normalWS);
            rayDescriptor.Direction = -light.forward;
            rayDescriptor.TMin      = kTMin;
            rayDescriptor.TMax      = kTMax;

            RayIntersection rayIntersection;
            rayIntersection.color             = float3(0.0, 0.0, 0.0);
            rayIntersection.incidentDirection = rayDescriptor.Direction;
            rayIntersection.origin            = rayDescriptor.Origin;
            rayIntersection.t                 = -1.0f;
            rayIntersection.cone.spreadAngle  = 0;
            rayIntersection.cone.width        = 0;

            const uint missShaderIndex = 1; // See the inspector of the BakeProbes.raytrace shader.
            TraceRay(raytracingAccelStruct, RAY_FLAG_ACCEPT_FIRST_HIT_AND_END_SEARCH | RAY_FLAG_SKIP_CLOSEST_HIT_SHADER, 0xFF, 0, 1, missShaderIndex, rayDescriptor, rayIntersection);

            context.shadowValue = rayIntersection.t < kTMax ? 0.0 : 1.0;
        }
    }
#else
    // Evaluate sun shadows.
    if (_DirectionalShadowIndex >= 0)
    {
        DirectionalLightData light = _DirectionalLightDatas[_DirectionalShadowIndex];

        // TODO: this will cause us to load from the normal buffer first. Does this cause a performance problem?
        float3 L = -light.forward;

        // Is it worth sampling the shadow map?
        if ((light.lightDimmer > 0) && (light.shadowDimmer > 0) && // Note: Volumetric can have different dimmer, thus why we test it here
            IsNonZeroBSDF(V, L, preLightData, bsdfData) &&
            !ShouldEvaluateThickObjectTransmission(V, L, preLightData, bsdfData, light.shadowIndex))
        {
            context.shadowValue = GetDirectionalShadowAttenuation(context.shadowContext,
                                                                  posInput.positionSS, posInput.positionWS, GetNormalForShadowBias(bsdfData),
                                                                  light.shadowIndex, L);
        }
    }
#endif

    AggregateLighting aggregateLighting;
    ZERO_INITIALIZE(AggregateLighting, aggregateLighting); // LightLoop is in charge of initializing the structure

    // Indices of the subranges to process
    uint lightStart = 0, lightEnd = 0;

    // The light cluster is in actual world space coordinates, 
    #ifdef USE_LIGHT_CLUSTER
    // Get the actual world space position
    float3 actualWSPos = GetAbsolutePositionWS(posInput.positionWS);
    #endif

    #ifdef USE_LIGHT_CLUSTER
    // Get the punctual light count
    uint cellIndex;
    GetLightCountAndStartCluster(actualWSPos, LIGHTCATEGORY_PUNCTUAL, lightStart, lightEnd, cellIndex);
    #else
    lightStart = 0;
    lightEnd = _PunctualLightCountRT;
    #endif

    uint i = 0;
    for (i = lightStart; i < lightEnd; i++)
    {
        #ifdef USE_LIGHT_CLUSTER
        LightData lightData = FetchClusterLightIndex(cellIndex, i);
        #else
        LightData lightData = _LightDatasRT[i];
        #endif
        if (IsMatchingLightLayer(lightData.lightLayers, builtinData.renderingLayers))
        {
            DirectLighting lighting = EvaluateBSDF_Punctual(context, V, posInput, preLightData, lightData, bsdfData, builtinData);
            AccumulateDirectLighting(lighting, aggregateLighting);
        }
    }

#if !defined(_DISABLE_SSR)
    // Add the traced reflection
    if (reflectionHierarchyWeight == 1.0)
    {
        IndirectLighting indirect;
        ZERO_INITIALIZE(IndirectLighting, indirect);
        indirect.specularReflected = reflection.rgb * preLightData.specularFGD;
        AccumulateIndirectLighting(indirect, aggregateLighting);
    }
#endif

#if HAS_REFRACTION
    // Add the traced transmission
    if (refractionHierarchyWeight == 1.0)
    {
        IndirectLighting indirect;
        ZERO_INITIALIZE(IndirectLighting, indirect);
        IndirectLighting lighting = EvaluateBSDF_RaytracedRefraction(context, preLightData, transmission);
        AccumulateIndirectLighting(lighting, aggregateLighting);
    }
#endif

    // Define macro for a better understanding of the loop
    // TODO: this code is now much harder to understand...
#define EVALUATE_BSDF_ENV_SKY(envLightData, TYPE, type) \
    IndirectLighting lighting = EvaluateBSDF_Env(context, V, posInput, preLightData, envLightData, bsdfData, envLightData.influenceShapeType, MERGE_NAME(GPUIMAGEBASEDLIGHTINGTYPE_, TYPE), MERGE_NAME(type, HierarchyWeight)); \
    AccumulateIndirectLighting(lighting, aggregateLighting);

// Environment cubemap test lightlayers, sky don't test it
#define EVALUATE_BSDF_ENV(envLightData, TYPE, type) if (IsMatchingLightLayer(envLightData.lightLayers, builtinData.renderingLayers)) { EVALUATE_BSDF_ENV_SKY(envLightData, TYPE, type) }
    
    #ifdef USE_LIGHT_CLUSTER
    // Get the punctual light count
    GetLightCountAndStartCluster(actualWSPos, LIGHTCATEGORY_ENV, lightStart, lightEnd, cellIndex);
    #else
    lightStart = 0;
    lightEnd = _EnvLightCountRT;
    #endif

    context.sampleReflection = SINGLE_PASS_CONTEXT_SAMPLE_REFLECTION_PROBES;

    // Scalarized loop, same rationale of the punctual light version
    uint envLightIdx = lightStart;
    while (envLightIdx < lightEnd)
    {
        #ifdef USE_LIGHT_CLUSTER
        EnvLightData envLightData = FetchClusterEnvLightIndex(cellIndex, envLightIdx);
        #else
        EnvLightData envLightData = _EnvLightDatasRT[envLightIdx];
        #endif
        envLightData.multiplier = _EnvLightDatas[envLightIdx].multiplier;

        if (reflectionHierarchyWeight < 1.0)
        {
            EVALUATE_BSDF_ENV(envLightData, REFLECTION, reflection);
        }
        if (refractionHierarchyWeight < 1.0)
        {
            EVALUATE_BSDF_ENV(envLightData, REFRACTION, refraction);
        }
        envLightIdx++;
    }

    // Only apply the sky IBL if the sky texture is available
    if (_EnvLightSkyEnabled)
    {
        // The sky is a single cubemap texture separate from the reflection probe texture array (different resolution and compression)
        context.sampleReflection = SINGLE_PASS_CONTEXT_SAMPLE_SKY;

        // The sky data are generated on the fly so the compiler can optimize the code
        EnvLightData envLightSky = InitSkyEnvLightData(0);

        // Only apply the sky if we haven't yet accumulated enough IBL lighting.
        if (reflectionHierarchyWeight < 1.0)
        {
            EVALUATE_BSDF_ENV_SKY(envLightSky, REFLECTION, reflection);
        }

        if ((refractionHierarchyWeight < 1.0))
        {
            EVALUATE_BSDF_ENV_SKY(envLightSky, REFRACTION, refraction);
        }
    }
#undef EVALUATE_BSDF_ENV
#undef EVALUATE_BSDF_ENV_SKY

    // We loop over all the directional lights given that there is no culling for them
    for (i = 0; i < _DirectionalLightCount; ++i)
    {
        if (IsMatchingLightLayer(_DirectionalLightDatas[i].lightLayers, builtinData.renderingLayers))
        {
            DirectLighting lighting = EvaluateBSDF_Directional(context, V, posInput, preLightData, _DirectionalLightDatas[i], bsdfData, builtinData);
            AccumulateDirectLighting(lighting, aggregateLighting);
        }
    }


    #ifdef USE_LIGHT_CLUSTER
    // Let's loop through all the 
    GetLightCountAndStartCluster(actualWSPos, LIGHTCATEGORY_AREA, lightStart, lightEnd, cellIndex);
    #else
    lightStart = _PunctualLightCountRT;
    lightEnd = _PunctualLightCountRT + _AreaLightCountRT;
    #endif

    if (lightEnd != lightStart)
    {
        i = lightStart;
        uint last = lightEnd;
        #ifdef USE_LIGHT_CLUSTER
        LightData lightData = FetchClusterLightIndex(cellIndex, i);
        #else
        LightData lightData = _LightDatasRT[i];
        #endif

        while (i < last && lightData.lightType == GPULIGHTTYPE_TUBE)
        {
            lightData.lightType = GPULIGHTTYPE_TUBE; // Enforce constant propagation

            if (IsMatchingLightLayer(lightData.lightLayers, builtinData.renderingLayers))
            {
                DirectLighting lighting = EvaluateBSDF_Area(context, V, posInput, preLightData, lightData, bsdfData, builtinData);
                AccumulateDirectLighting(lighting, aggregateLighting);
            }
            i++;
            #ifdef USE_LIGHT_CLUSTER
            lightData = FetchClusterLightIndex(cellIndex, i);
            #else
            lightData = _LightDatasRT[i];
            #endif
        }

        while (i < last ) // GPULIGHTTYPE_RECTANGLE
        {
            lightData.lightType = GPULIGHTTYPE_RECTANGLE; // Enforce constant propagation

            if (IsMatchingLightLayer(lightData.lightLayers, builtinData.renderingLayers))
            {
                DirectLighting lighting = EvaluateBSDF_Area(context, V, posInput, preLightData, lightData, bsdfData, builtinData);
                AccumulateDirectLighting(lighting, aggregateLighting);
            }
            i++;
            #ifdef USE_LIGHT_CLUSTER
            lightData = FetchClusterLightIndex(cellIndex, i);
            #else
            lightData = _LightDatasRT[i];
            #endif
        }
    }

#ifdef USE_RTPV
    {
        float3 wpos = GetAbsolutePositionWS(posInput.positionWS);
        aggregateLighting.direct.diffuse += sampleIrradiance(wpos, bsdfData.normalWS, -WorldRayDirection(), bsdfData.normalWS);
    }
#endif

    PostEvaluateBSDF(context, V, posInput, preLightData, bsdfData, builtinData, aggregateLighting, diffuseLighting, specularLighting);
}
