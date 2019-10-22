#ifndef MOTION_VEC_VERTEX_COMMON_INCLUDED
#define MOTION_VEC_VERTEX_COMMON_INCLUDED

// TODO: replace alembic motion vectors with builtin 'precomputedVelocity'

//custom-begin: alembic
float _AlembicMotionVectorsScale;
//custom-end:

//custom-begin: object motion override
    float override_Matrix;
    float4x4 override_MatrixPreviousM;
    float4x4 override_MatrixPreviousMI;
//custom-end:

// Available semantic start from TEXCOORD4
struct AttributesPass
{
//custom-begin: alembic
#ifdef ALEMBIC
    float3 aiVelocity : TEXCOORD3;
#endif
//custom-end:
    float3 previousPositionOS : TEXCOORD4; // Contain previous transform position (in case of skinning for example)
#if defined (_ADD_PRECOMPUTED_VELOCITY)
    float3 precomputedVelocity    : TEXCOORD5; // Add Precomputed Velocity (Alembic computes velocities on runtime side).
#endif
};

struct VaryingsPassToPS
{
    // Note: Z component is not use currently
    // This is the clip space position. Warning, do not confuse with the value of positionCS in PackedVarying which is SV_POSITION and store in positionSS
    float4 positionCS;
    float4 previousPositionCS;
};

// Available interpolator start from TEXCOORD8
struct PackedVaryingsPassToPS
{
    // Note: Z component is not use
    float3 interpolators0 : TEXCOORD8;
    float3 interpolators1 : TEXCOORD9;
};

PackedVaryingsPassToPS PackVaryingsPassToPS(VaryingsPassToPS input)
{
    PackedVaryingsPassToPS output;
    output.interpolators0 = float3(input.positionCS.xyw);
    output.interpolators1 = float3(input.previousPositionCS.xyw);

    return output;
}

VaryingsPassToPS UnpackVaryingsPassToPS(PackedVaryingsPassToPS input)
{
    VaryingsPassToPS output;
    output.positionCS = float4(input.interpolators0.xy, 0.0, input.interpolators0.z);
    output.previousPositionCS = float4(input.interpolators1.xy, 0.0, input.interpolators1.z);

    return output;
}

#ifdef TESSELLATION_ON

// Available interpolator start from TEXCOORD4

// Same as ToPS here
#define VaryingsPassToDS VaryingsPassToPS
#define PackedVaryingsPassToDS PackedVaryingsPassToPS
#define PackVaryingsPassToDS PackVaryingsPassToPS
#define UnpackVaryingsPassToDS UnpackVaryingsPassToPS

VaryingsPassToDS InterpolateWithBaryCoordsPassToDS(VaryingsPassToDS input0, VaryingsPassToDS input1, VaryingsPassToDS input2, float3 baryCoords)
{
    VaryingsPassToDS output;

    TESSELLATION_INTERPOLATE_BARY(positionCS, baryCoords);
    TESSELLATION_INTERPOLATE_BARY(previousPositionCS, baryCoords);

    return output;
}

#endif // TESSELLATION_ON

#ifdef TESSELLATION_ON
#define VaryingsPassType VaryingsPassToDS
#else
#define VaryingsPassType VaryingsPassToPS
#endif

// We will use custom attributes for this pass
#define VARYINGS_NEED_PASS
#include "Packages/com.unity.render-pipelines.high-definition/Runtime/RenderPipeline/ShaderPass/VertMesh.hlsl"

// Transforms normal from object to world space
float3 TransformPreviousObjectToWorldNormal(float3 normalOS)
{
#ifdef UNITY_ASSUME_UNIFORM_SCALING
    return normalize(mul((float3x3)unity_MatrixPreviousM, normalOS));
#else
    // Normal need to be multiply by inverse transpose
    return normalize(mul(normalOS, (float3x3)unity_MatrixPreviousMI));
#endif
}

// Transforms local position to camera relative world space
float3 TransformPreviousObjectToWorld(float3 positionOS)
{
    float4x4 previousModelMatrix = ApplyCameraTranslationToMatrix(unity_MatrixPreviousM);
    return mul(previousModelMatrix, float4(positionOS, 1.0)).xyz;
}

void MotionVectorPositionZBias(VaryingsToPS input)
{
#if defined(UNITY_REVERSED_Z)
    input.vmesh.positionCS.z -= unity_MotionVectorsParams.z * input.vmesh.positionCS.w;
#else
    input.vmesh.positionCS.z += unity_MotionVectorsParams.z * input.vmesh.positionCS.w;
#endif
}

PackedVaryingsType MotionVectorVS(inout VaryingsType varyingsType, AttributesMesh inputMesh, AttributesPass inputPass)
{

#if !defined(TESSELLATION_ON)
    MotionVectorPositionZBias(varyingsType);
#endif

    // It is not possible to correctly generate the motion vector for tesselated geometry as tessellation parameters can change
    // from one frame to another (adaptative, lod) + in Unity we only receive information for one non tesselated vertex.
    // So motion vetor will be based on interpolate previous position at vertex level instead.
    varyingsType.vpass.positionCS = mul(UNITY_MATRIX_UNJITTERED_VP, float4(varyingsType.vmesh.positionRWS, 1.0));

    // Note: unity_MotionVectorsParams.y is 0 is forceNoMotion is enabled
    bool forceNoMotion = unity_MotionVectorsParams.y == 0.0;
    if (forceNoMotion)
    {
        varyingsType.vpass.previousPositionCS = float4(0.0, 0.0, 0.0, 1.0);
    }
    else
    {
//custom-begin: object motion override
        if (override_Matrix == 1.0)
        {
            unity_MatrixPreviousM = override_MatrixPreviousM;
            unity_MatrixPreviousMI = override_MatrixPreviousMI;
        }
//custom-end:

        bool hasDeformation = unity_MotionVectorsParams.x > 0.0; // Skin or morph target

        float3 effectivePositionOS = (hasDeformation ? inputPass.previousPositionOS : inputMesh.positionOS);
#if defined(_ADD_PRECOMPUTED_VELOCITY)
        effectivePositionOS -= inputPass.precomputedVelocity;
#endif

    // Need to apply any vertex animation to the previous worldspace position, if we want it to show up in the motion vector buffer
#if defined(HAVE_MESH_MODIFICATION)
        AttributesMesh previousMesh = inputMesh;
        previousMesh.positionOS = effectivePositionOS ;

        previousMesh = ApplyMeshModification(previousMesh, _LastTimeParameters.xyz);
        float3 previousPositionRWS = TransformPreviousObjectToWorld(previousMesh.positionOS);
#else
        float3 previousPositionRWS = TransformPreviousObjectToWorld(effectivePositionOS);
#endif

//custom-begin: warp
#if defined(WARP) || defined(WARP2)
    #ifdef ATTRIBUTES_NEED_NORMAL
        float3 normal = inputMesh.normalOS;
    #else
        float3 normal = float3(0.0, 0.0, 0.0); // We need this case to be able to compile ApplyVertexModification that doesn't use normal.
    #endif
    #ifdef WARP
        CorridorWarpVertex(PARAM_FRAME_PREV, inputMesh.positionOS, normal, inputMesh.uv0, inputMesh.uv1, inputMesh.uv2);
    #else//WARP2
        CorridorWarpVertex2(PARAM_FRAME_PREV, inputMesh.positionOS, normal, inputMesh.uv0, inputMesh.uv1, inputMesh.uv2);
    #endif
        previousPositionRWS = TransformPreviousObjectToWorld(inputMesh.positionOS);
    #ifdef ATTRIBUTES_NEED_NORMAL
        inputMesh.normalOS = normal;
    #endif
#endif
//custom-end:

//custom-begin: alembic
#ifdef ALEMBIC
        previousPositionRWS = TransformPreviousObjectToWorld(inputMesh.positionOS + inputPass.aiVelocity * _AlembicMotionVectorsScale);
#endif
//custom-end:

#ifdef ATTRIBUTES_NEED_NORMAL
        float3 normalWS = TransformPreviousObjectToWorldNormal(inputMesh.normalOS);
#else
        float3 normalWS = float3(0.0, 0.0, 0.0);
#endif

#if defined(HAVE_VERTEX_MODIFICATION)
//custom-begin: warp
    #if defined(WARP) || defined(WARP2)
        ApplyVertexModification(inputMesh, normalWS, previousPositionRWS, _LastTimeParameters.xyz, PARAM_FRAME_PREV);
    #else
        ApplyVertexModification(inputMesh, normalWS, previousPositionRWS, _LastTimeParameters.xyz);
    #endif
//custom-end:
#endif

        varyingsType.vpass.previousPositionCS = mul(UNITY_MATRIX_PREV_VP, float4(previousPositionRWS, 1.0));

//custom-begin: wires
#ifdef _WIRES
        varyingsType.vpass.previousPositionCS = WireVertexPreviousPositionCS(inputMesh, varyingsType.vpass.positionCS);
#endif
//custom-end:
    }

    return PackVaryingsType(varyingsType);
}

#endif
