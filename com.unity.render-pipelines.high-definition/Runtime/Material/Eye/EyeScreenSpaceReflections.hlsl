//custom-begin: (Nick) eye rendering
#ifndef EYE_SCREEN_SPACE_REFLECTIONS_H
#define EYE_SCREEN_SPACE_REFLECTIONS_H

bool _EyeScreenSpaceReflectionsIsEnabled;

TEXTURE2D(_CameraColorTextureEyeSSR);

int _DepthPyramidMaxMip;
float _DepthPyramidMipLevelOffsetsX[8];
float _DepthPyramidMipLevelOffsetsY[8];

TEXTURE2D(_BlueNoiseTexture);
float4 _BlueNoiseTexture_TexelSize;
int _SampleIndex;

// A Simpler and Exact Sampling Routine for the GGX Distribution of Visible Normals
// https://hal.archives-ouvertes.fr/hal-01509746/document
// https://schuttejoe.github.io/post/ggximportancesamplingpart2/
float3 ImportanceSampleGgxDistributionOfVisibleNormals(const in float3 viewDirectionTS, const in float roughness2, const in float2 random2d)
{
    // Stretch the view vector so we are sampling as though roughness==1
    float3 v = normalize(float3(roughness2 * viewDirectionTS.x, roughness2 * viewDirectionTS.y, viewDirectionTS.z));

    // Construct an orthonormal basis about v.
    float3 tangent = (v.z < 0.9999f)
        ? normalize(cross(v, float3(0.0f, 0.0f, 1.0f)))
        : float3(1.0f, 0.0f, 0.0f);
    float3 bitangent = normalize(cross(tangent, v));

    // Choose a point on a disk with each half of the disk weighted
    // proportionally to its projection onto direction v
    float a = 1.0f / (1.0f + v.z);

    // Note / TODO: Could pre-condition random2d.x to be sqrt(random2d.x) to avoid evaluating at runtime.
    float r = sqrt(random2d.x);
    float phi = (random2d.y < a)
        ? ((random2d.y / a) * PI)
        : (PI + (random2d.y - a) / (1.0f - a) * PI);
    float p1 = r * cos(phi);
    float p2 = r * sin(phi) * ((random2d.y < a) ? 1.0f : v.z);

    // Calculate the normal in this stretched tangent space.
    float3 normal = p1 * tangent + p2 * bitangent + sqrt(max(0.0f, 1.0f - p1 * p1 - p2 * p2)) * v;

    // Unstretch and normalize the normal.
    return normalize(float3(roughness2 * normal.x, roughness2 * normal.y, max(0.0f, normal.z)));
}

float SmithGGXMasking(float nDotV, float roughness4)
{
    float denomC = sqrt(roughness4 + (1.0f - roughness4) * nDotV * nDotV) + nDotV;

    return 2.0f * nDotV / denomC;
}

//====================================================================
float SmithGGXMaskingShadowing(float nDotL, float nDotV, float roughness4)
{
    float denomA = nDotV * sqrt(roughness4 + (1.0f - roughness4) * nDotL * nDotL);
    float denomB = nDotL * sqrt(roughness4 + (1.0f - roughness4) * nDotV * nDotV);

    return 2.0f * nDotL * nDotV / (denomA + denomB);
}

// http://jcgt.org/published/0003/02/03/paper.pdf
// http://www.frostbite.com/wp-content/uploads/2014/11/course_notes_moving_frostbite_to_pbr.pdf
float SmithGGXHeightCorrelated(const in float nDotL, const in float nDotV, const in float roughness4)
{
    // Original formulation of G_SmithGGX Correlated
    // lambda_v = (-1.0f + sqrt(roughness4 * (1.0f - nDotL2) / nDotL2 + 1.0f)) * 0.5f;
    // lambda_l = (-1.0f + sqrt(roughness4 * (1.0f - nDotV2) / nDotV2 + 1.0f)) * 0.5f;
    // G_SmithGGXCorrelated = 1.0f / (1.0f + lambda_v + lambda_l);
    // V_SmithGGXCorrelated = G_SmithGGXCorrelated / (4.0f * nDotL * nDotV);

    // Optimized:
    // Caution: the nDotL* and nDotV* are inverted. This is not a mistake.
    float g1L = nDotV * sqrt((-nDotL * roughness4 + nDotL) * nDotL + roughness4);
    float g1V = nDotL * sqrt((-nDotV * roughness4 + nDotV) * nDotV + roughness4);

    return 0.5f / (g1L + g1V);
}

// An Inexpensive BRDF Model for Physically-based Rendering:
// http://www.cs.virginia.edu/~jdl/bib/appearance/analytic%20models/schlick94b.pdf
float fresnelSchlick(const in float vDotH, const in float f0)
{
    return (1.0f - f0) * pow(1.0f - vDotH, 5.0f) + f0;
}

// Numerical fit of microfacet energy loss compensation from:
// http://blog.selfshadow.com/publications/s2017-shading-course/imageworks/s2017_pbs_imageworks_slides_v2.pdf
float FaverageDielectric(const in float ior)
{
    float ior2 = ior * ior;
    float ior3 = ior2 * ior;
    return (ior - 1.0) / (4.08567 + 1.00071 * ior);
}

float OneMinusEAverage(const in float r)
{
    const float A = 0.592665;
    const float B = -1.47034;
    const float C = 1.47196;

    float r2 = r * r;
    float r3 = r2 * r;

    return A * r3 / (1.0 + B * r + C * r2);
}

float MicrofacetEnergyCompensationFresnelDielectricNumericalFit(const in float r, const in float ior)
{
    float Favg = FaverageDielectric(ior);
    float oneMinusEavg = OneMinusEAverage(r);
    float Eavg = 1.0 - oneMinusEavg;

    return Favg * Favg * Eavg / (1.0 - Favg * oneMinusEavg);
}

float SampleDepthPyramid(float2 positionSS, int mipLevel)
{
    int _mipLevel = min(mipLevel, _DepthPyramidMaxMip);
    int2 mipCoord = int2(positionSS.xy) >> _mipLevel;
    int2 mipOffset = int2(_DepthPyramidMipLevelOffsetsX[(_mipLevel + 0) >> 1] + 0.5,
                          _DepthPyramidMipLevelOffsetsY[(_mipLevel + 1) >> 1] + 0.5);

    float sampleDepthNDC = LOAD_TEXTURE2D_X(_CameraDepthTexture, mipOffset + mipCoord).x;
    return sampleDepthNDC;

    // previously
    //float sampleDepthNDC = LOAD_TEXTURE2D_LOD(_DepthPyramidTexture, float2(int2(positionSS) >> mipLevel) + 0.5f, mipLevel).x;
}


float4 EyeScreenSpaceReflectionsRaytrace(const in float3 surfacePositionWS, const in float2 surfacePositionSS, const in float3 viewDirectionWS, const in BSDFData bsdfData)
{
    float3 surfaceNormalWS = bsdfData.normalWS;
    float roughness = bsdfData.perceptualRoughness ? bsdfData.perceptualRoughness : ((bsdfData.roughnessT + bsdfData.roughnessB) * 0.5f);
    roughness = max(0.06f, roughness);
    float roughness2 = roughness * roughness;
    float roughness4 = roughness2 * roughness2;
    float3 fresnel0 = bsdfData.fresnel0;

    // Importance sample the distribution of visible normals in order to generate a microfacet normal (half vector)
    // that is guaranteed to be visible to the viewDirection.
    float2 blueNoiseUv = frac(surfacePositionSS * _BlueNoiseTexture_TexelSize.xy);
    float4 blueNoiseLut = SAMPLE_TEXTURE2D_LOD(_BlueNoiseTexture, s_linear_repeat_sampler, blueNoiseUv, 0);

    // TODO: Rather than simply ossilating between .xy and .zw components of blue noise LUT per frame, expand blue noise LUT
    // over time by rotating the resulting vector by a low discrepancy angle (i.e: golden ratio based hash) over time.
    float2 random2d = (_SampleIndex == 0) ? blueNoiseLut.xy : blueNoiseLut.zw;

    // PDF_BIAS range: [0.0f, 1.0f] allows user to bias sampling toward center (reflection vector)
    // to reduce variance by trimming the distribution's toe.
    const float PDF_BIAS = 0.05f;
    random2d.x = random2d.x * 2.0f - 1.0f;
    random2d.x *= 1.0f - PDF_BIAS;
    random2d.x = random2d.x * 0.5f + 0.5f;

    // Construct an ortho-normal basis around our surface normal as the importance sampling NDF procedure
    // assumes input of tangent space view direction.
    // Note: GetLocalFrame() returns a row-major 3x3 matrix, aka, transpose of tangentFromWorldMatrix
    // aka inverse (due to ortho-normal) of tangentFromWorldMatrix aka worldFromTangentMatrix
    float3x3 worldFromTangentMatrix = GetLocalFrame(surfaceNormalWS);
    float3 viewDirectionTS = mul(viewDirectionWS, worldFromTangentMatrix);
    float3 halfVectorTS = ImportanceSampleGgxDistributionOfVisibleNormals(viewDirectionTS, roughness2, random2d);
    float3 halfVectorWS = mul(worldFromTangentMatrix, halfVectorTS);
    float3 reflectionDirectionWS = reflect(-viewDirectionWS, halfVectorWS);

    float3 rayOriginWS = surfacePositionWS;
    float3 rayDirectionWS = reflectionDirectionWS;

    // TODO: Was playing around with a depth-based bias term (depth based as precision decreases with depth)
    // Might be nice to expose bias along surface normal as a UI slider.
    // rayOriginWS += surfaceNormalWS * log2(1.0f + rcp(depthLinearEyeInverse)) * 0.005f;

    // TODO: Expose rayLengthMaxWS as a UI slider.
    float rayLengthMaxWS = 0.025f;
    float3 rayEndWS = rayDirectionWS * rayLengthMaxWS + rayOriginWS;

    float4 rayOriginCS = ComputeClipSpacePosition(GetCameraRelativePositionWS(rayOriginWS), UNITY_MATRIX_VP);
    float4 rayEndCS = ComputeClipSpacePosition(GetCameraRelativePositionWS(rayEndWS), UNITY_MATRIX_VP);

    float rayOriginHomogenizerCS = rcp(rayOriginCS.w);
    float rayEndHomogenizerCS = rcp(rayEndCS.w);

    // Note: NDC is in range: [(-1, -1, 0), (1, 1, 1)]
    float3 rayOriginNDC = rayOriginCS.xyz * rayOriginHomogenizerCS;
    float3 rayEndNDC = rayEndCS.xyz * rayEndHomogenizerCS;

    // Note: Screen-space is in range: [(0, 0, 0), (_ScreenSize.x, _ScreenSize.y, 1)]
    // _ProjectionParams.x: 1 or -1 for flipping vertically when required.
    float flipV = _ProjectionParams.x * 0.5f;
    float3 rayOriginSS = (rayOriginNDC * float3(0.5f, flipV, 1.0f) + float3(0.5f, 0.5f, 0.0f)) * float3(_ScreenSize.xy, 1.0f);
    float3 rayEndSS = (rayEndNDC * float3(0.5f, flipV, 1.0f) + float3(0.5f, 0.5f, 0.0f)) * float3(_ScreenSize.xy, 1.0f);

    rayOriginSS.z = LinearEyeDepth(rayOriginSS.z, _ZBufferParams);
    rayEndSS.z = LinearEyeDepth(rayEndSS.z, _ZBufferParams);

    float3 rayDirectionSS = rayEndSS - rayOriginSS;
    float rayDistanceMaxSS = length(rayDirectionSS);
    rayDirectionSS *= rcp(rayDistanceMaxSS);

    // Typical (CPU) implementations of DDA ray marching, and AABB tests often rely on 1 / 0 == infinity.
    // In our context, 1 / 0 will result in NaN, we we need to explicity guard against divide by zero
    // and manually place value at FLT_MAX.
    float3 rayDirectionInverseSS;
    rayDirectionInverseSS.x = (rayDirectionSS.x == 0.0f) ? FLT_MAX : rcp(rayDirectionSS.x);
    rayDirectionInverseSS.y = (rayDirectionSS.y == 0.0f) ? FLT_MAX : rcp(rayDirectionSS.y);
    rayDirectionInverseSS.z = (rayDirectionSS.z == 0.0f) ? FLT_MAX : rcp(rayDirectionSS.z);

    // return LOAD_TEXTURE2D(_CameraColorTextureEyeSSR, rayEndSS.xy);

    // Intersect ray and frustum AABB (in screen-space).
    // Use numerically robust implementation of ray -> AABB intersection.
    // Source: Robust BVH Ray Traversal
    // http://jcgt.org/published/0002/02/02/paper.pdf
    //
    // Note: If no bias was applied (ray started at surface), then we know ray origin is within frustum,
    // so we would only need to compute the intersection of the farther three planes.

    float cameraNearPlaneVS = _ProjectionParams.y;
    float cameraFarPlaneVS = _ProjectionParams.z;
    float3 frustumMinSS = float3(0.0f, 0.0f, cameraNearPlaneVS);
    float3 frustumMaxSS = float3(_ScreenSize.xy, cameraFarPlaneVS);

    float x0 = (rayDirectionInverseSS.x >= 0.0f) ? frustumMinSS.x : frustumMaxSS.x;
    float y0 = (rayDirectionInverseSS.y >= 0.0f) ? frustumMinSS.y : frustumMaxSS.y;
    float z0 = (rayDirectionInverseSS.z >= 0.0f) ? frustumMinSS.z : frustumMaxSS.z;

    float x1 = (rayDirectionInverseSS.x < 0.0f) ? frustumMinSS.x : frustumMaxSS.x;
    float y1 = (rayDirectionInverseSS.y < 0.0f) ? frustumMinSS.y : frustumMaxSS.y;
    float z1 = (rayDirectionInverseSS.z < 0.0f) ? frustumMinSS.z : frustumMaxSS.z;

    x0 = (x0 - rayOriginSS.x) * rayDirectionInverseSS.x;
    y0 = (y0 - rayOriginSS.y) * rayDirectionInverseSS.y;
    z0 = (z0 - rayOriginSS.z) * rayDirectionInverseSS.z;

    x1 = (x1 - rayOriginSS.x) * rayDirectionInverseSS.x;
    y1 = (y1 - rayOriginSS.y) * rayDirectionInverseSS.y;
    z1 = (z1 - rayOriginSS.z) * rayDirectionInverseSS.z;

    float rayFrustumTDistanceMinSS = max(z0, max(y0, x0));
    float rayFrustumTDistanceMaxSS = min(z1, min(y1, x1));

    // This is the 1-ULP 32-bit float constant for error compensation referenced in source paper.
    rayFrustumTDistanceMaxSS *= 1.00000024f;

    // Clip ray line segment against bounds of frustum AABB (in screen-space) to implicitly exit if ray marches outside of frustum.
    float rayDistanceMinSS = max(0.0f, rayFrustumTDistanceMinSS);
    rayDistanceMaxSS = min(rayDistanceMaxSS, rayFrustumTDistanceMaxSS);

    // Compute the position of the ray sample in screen-space.xy
    float2 samplePositionSS = rayDirectionSS.xy * rayDistanceMinSS + rayOriginSS.xy;

    // Initialize patch index at whichever cell our ray segment start is currently inside (or has just entered).
    float2 sampleIndexSS = floor(samplePositionSS);

    float numSamplesTargetInverse = 1.0f / 512.0f;
    float numSamplesManhattan = abs(rayDirectionSS.x * rayDistanceMaxSS - rayDirectionSS.x * rayDistanceMinSS)
        + abs(rayDirectionSS.y * rayDistanceMaxSS - rayDirectionSS.y * rayDistanceMinSS);
    float numSamplesRatio = numSamplesManhattan * numSamplesTargetInverse;

    uint strideLog2 = uint(ceil(log2(max(1.0f, numSamplesRatio))));
    float stride = float(1u << strideLog2);
    float2 rayDistanceToCrossingBiasSS;
    {
        float2 bias = float2(
            (rayDirectionSS.x < 0.0f) ? 0.0f : 1.0f,
            (rayDirectionSS.y < 0.0f) ? 0.0f : 1.0f
        );

        // FIXME: Note: rayDistanceMinSS == 0.0f at this point. No reason to add except for "completeness".
        rayDistanceToCrossingBiasSS = (sampleIndexSS + bias - samplePositionSS) * rayDirectionInverseSS.xy * stride + rayDistanceMinSS;
    }

    // Add half-pixel offset for center sampling textures.
    sampleIndexSS += float2(0.5f, 0.5f);

    float2 crossingsCount = float2(0.0f, 0.0f);
    float2 crossingDistanceAbs = abs(rayDirectionInverseSS.xy) * stride;
    float2 crossingNextSign = float2(
        (rayDirectionSS.x < 0.0f) ? -stride : stride,
        (rayDirectionSS.y < 0.0f) ? -stride : stride
    );

    // If our ray starts out inside our pixel origin, advance into the next pixel in order to avoid
    // self shadowing / self reflections.
    // Note: Currently, this is always the case, as we Initialize rayDistanceMinSS to 0.0f.
    // If this persists, simply remove this conditional check.
    if ((sampleIndexSS.x == surfacePositionSS.x) && (sampleIndexSS.y == surfacePositionSS.y))
    {
        float2 rayDistanceToCrossingSS = crossingsCount * crossingDistanceAbs + rayDistanceToCrossingBiasSS;

        // Advance to next pixel grid crossing.
        if (rayDistanceToCrossingSS.x < rayDistanceToCrossingSS.y)
        {
            rayDistanceMinSS = rayDistanceToCrossingSS.x;
            ++crossingsCount.x;
            sampleIndexSS.x += crossingNextSign.x;
        } else
        {
            rayDistanceMinSS = rayDistanceToCrossingSS.y;
            ++crossingsCount.y;
            sampleIndexSS.y += crossingNextSign.y;
        }
    }

    bool hit = false;
    float debugNumSteps = 0.0f;
    float isValidWeight = 0.0f;
    while (rayDistanceMinSS < rayDistanceMaxSS)
    {
        // TODO: disable debugNumSteps, or rename and expose as slider.
        // This forces ray march to terminate after a set number of steps, even if ray hasn't marched to requested to world-space end point.
        // May be redundant.
        ++debugNumSteps;
        if (debugNumSteps > 1024.0f) { break; }

        float2 rayDistanceToCrossingSS = crossingsCount * crossingDistanceAbs + rayDistanceToCrossingBiasSS;

        float rayDistanceMinPreviousSS = rayDistanceMinSS;

        float2 sampleIndexPreviousSS = sampleIndexSS;

        // Advance to next pixel grid crossing.
        // TODO: Could write as conditional assignments, should look at instruction output and determine if compiler is doing this already.
        if (rayDistanceToCrossingSS.x < rayDistanceToCrossingSS.y)
        {
            rayDistanceMinSS = rayDistanceToCrossingSS.x;
            ++crossingsCount.x;
            sampleIndexSS.x += crossingNextSign.x;
        } else
        {
            rayDistanceMinSS = rayDistanceToCrossingSS.y;
            ++crossingsCount.y;
            sampleIndexSS.y += crossingNextSign.y;
        }

        float2 rayDistanceMinMaxSS = (rayDistanceMinPreviousSS < rayDistanceMinSS)
            ? float2(rayDistanceMinPreviousSS, rayDistanceMinSS)
            : float2(rayDistanceMinSS, rayDistanceMinPreviousSS);

        float2 rayDepthMinMaxLinearVS = rayDistanceMinMaxSS * rayDirectionSS.z + rayOriginSS.z;

        float sampleDepthNDC = SampleDepthPyramid(sampleIndexPreviousSS, strideLog2);
        float sampleDepthLinearMinVS = LinearEyeDepth(sampleDepthNDC, _ZBufferParams);

        // TODO: May want to expose this thickness as a UI slider.
        // It assigns an artifical / adhoc / made up thickness to the pixel we are marching through.
        float sampleThickness = (rayDepthMinMaxLinearVS.y - rayDepthMinMaxLinearVS.x);
        sampleThickness = max(0.01f, sampleThickness);

        float sampleDepthLinearMaxVS = sampleDepthLinearMinVS + sampleThickness;

        if ((sampleDepthLinearMinVS > rayDepthMinMaxLinearVS.y) || (sampleDepthLinearMaxVS < rayDepthMinMaxLinearVS.x))
        {
            // No hit.
        } else
        {
            hit = true;

            // TODO: Pull these assignments / calculations outside of raymarch loop, and perform after loop has exited with a hit.
            sampleIndexSS = sampleIndexPreviousSS;

            float2 hitUv = sampleIndexSS.xy * _ScreenSize.zw * 2.0f - 1.0f;
            isValidWeight = saturate((1.0f - hitUv.x * hitUv.x) * (1.0f - hitUv.y * hitUv.y));
            break;
        }
    }

    if (!hit)
    {
        return 0.0f;
    }

    {
        // Evaluate BRDF response for our ray direction.
        float3 lightDirectionWS = reflectionDirectionWS;
        float nDotL = saturate(dot(surfaceNormalWS, lightDirectionWS));
        float nDotV = max(1e-5f, abs(dot(surfaceNormalWS, viewDirectionWS)));
        float nDotH = dot(surfaceNormalWS, halfVectorWS);
        float vDotH = saturate(dot(viewDirectionWS, halfVectorWS));

        // TODO: As we are importance sampling, we compute: radianceOut = radianceIn * nDotL * brdf / pdf factor.
        // Many of these terms factor out, in particular between the brdf and pdf.
        // float brdf = d * v;//f * d * v;
        // float pdf = d / (4.0f * vDotH);
        float3 f = F_Schlick(fresnel0, vDotH);
        // float d = D_GGX(nDotH, roughness2);
        // float v = SmithGGXHeightCorrelated(nDotL, nDotV, roughness4);

        float g1 = SmithGGXMasking(nDotV, roughness4);
        float g2 = SmithGGXMaskingShadowing(nDotL, nDotV, roughness4);


        float4 sampleRadianceIncoming = LOAD_TEXTURE2D(_CameraColorTextureEyeSSR, sampleIndexSS);
        // float4 sampleRadianceIncoming = LOAD_TEXTURE2D_LOD(_ColorPyramidTexture, float2(int2(sampleIndexSS.xy) >> strideLog2) + 0.5f, strideLog2);


        // Note: Experimented with energy loss from single scatter compensation.
        // Likely, this is overkill, especially for the non-metallic surface this SSR trace is for (the eye).
        // TODO: Do final evaluation and likely remove cRgb multiplication (replace cRgb with 1.0)
        float3 iorRgb = float3(Fresnel0ToIor(fresnel0.r), Fresnel0ToIor(fresnel0.g), Fresnel0ToIor(fresnel0.b));
        float3 cRgb = float3(
            MicrofacetEnergyCompensationFresnelDielectricNumericalFit(roughness, iorRgb.r),
            MicrofacetEnergyCompensationFresnelDielectricNumericalFit(roughness, iorRgb.g),
            MicrofacetEnergyCompensationFresnelDielectricNumericalFit(roughness, iorRgb.b)
        );

        float3 sampleRadianceOutgoing = sampleRadianceIncoming.rgb * f * (isValidWeight * ((cRgb * nDotL) + (g2 / g1)));

        return float4(sampleRadianceOutgoing, isValidWeight);
    }
}

#endif
//custom-end: (Nick) eye rendering