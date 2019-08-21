using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Experimental.Rendering.HDPipeline;
using UnityEngine.Rendering;
using RTHandle = UnityEngine.Experimental.Rendering.RTHandleSystem.RTHandle;

[ExecuteInEditMode]
public class LensFlareSettings : MonoBehaviour
{
    public static LensFlareSettings Instance { get; private set;}
    static readonly List<LensFlareSettings> PrevInstances = new List<LensFlareSettings>(2);

    public Light m_Light;

    public enum OcclusionMode
    {
        Automatic,
        Manual
    }
    [Header("Global Settings")]
    public float m_Intensity = 1.0f;
    [Range(0f,180f)]
    public float m_ConeAngle = 180f;
    [Range(0f,1f)]
    public float m_Feather = 0f;

    [Space()]
    public OcclusionMode m_OcclusionMode = OcclusionMode.Automatic;

    [Tooltip("Size of a disk used to check if the light source is occluded or partially occluded.")]
    public float m_OcclusionRadius = 1.0f;
    [Range(0, 1)]
    [Tooltip("Manual occlusion level for keyframe animation. 0 is no light, i.e. full occlusion.")]
    public float m_OcclusionManual = 1.0f;

    [Header("Flare Element Settings")]
    [SerializeField]
    public FlareSettings[] m_Flares;

	//[HideInInspector]
	public Mesh m_Mesh;

    static class Uniforms
	{
        internal static readonly int _FlareScreenPos = Shader.PropertyToID("_FlareScreenPos");
        internal static readonly int _FlareScreenPosPanini = Shader.PropertyToID("_FlareScreenPosPanini");
        internal static readonly int _FlareDepth = Shader.PropertyToID("_FlareDepth");
		internal static readonly int _OcclusionRadius = Shader.PropertyToID("_OcclusionRadius");
        internal static readonly int _OcclusionManual = Shader.PropertyToID("_OcclusionManual");
        internal static readonly int _FlareIntensity = Shader.PropertyToID("_FlareIntensity");
		internal static readonly int _FlareColor = Shader.PropertyToID("_FlareColor");
		internal static readonly int _FlareData = Shader.PropertyToID("_FlareData");
        internal static readonly int _ViewportAdjustment = Shader.PropertyToID("_ViewportAdjustment");
	}

    void OnEnable()
    {
        if (Instance != null)
            PrevInstances.Add(Instance);
        Instance = this;
    }

    void OnDisable()
    {
        if (Instance == this)
        {
            if (PrevInstances.Count > 0)
            {
                Instance = PrevInstances[PrevInstances.Count - 1];
                PrevInstances.RemoveAt(PrevInstances.Count - 1);
            }
            else
            {
                Instance = null;
            }
        }
        else
        {
            if (PrevInstances.Contains(this))
                PrevInstances.Remove(this);
        }
    }

    public void Render(CommandBuffer cmd, RTHandle src, HDCamera hdcam, PaniniProjection paniniProjection)
    {
        Debug.Assert(Instance == this, "More than one LensFlareSettings object enabled at a time: " + this.name + ", " + (Instance != null ? Instance.name : "(none)"));

        cmd.BeginSample("LensFlare");

        Camera cam = hdcam.camera;

        // This is due to how HDRP handles Game View: when it's resolution is decreased, it keeps using the same RT, so those
        // dimensions stay the same, but all the camera viewport-related sizes and matrices get updated to the requested size.
        Vector2 viewportAdjustment = new Vector2((float)hdcam.actualWidth / src.rt.width, (float)hdcam.actualHeight / src.rt.height);
        cmd.SetGlobalVector(Uniforms._ViewportAdjustment, viewportAdjustment);

        Vector3 viewportPos = cam.WorldToViewportPoint(transform.position);
        Vector2 screenPos = (Vector2)viewportPos;

        Vector2 occlusionRadiusEdgeScreenPos = (Vector2)cam.WorldToViewportPoint(transform.position + cam.transform.up * m_OcclusionRadius);
        float occlusionRadius = (screenPos - occlusionRadiusEdgeScreenPos).magnitude * 2;
        cmd.SetGlobalFloat(Uniforms._OcclusionRadius, occlusionRadius);

        Vector2 ScreenUVToNDC(Vector2 uv)  { return new Vector2(uv.x * 2 - 1, 1 - uv.y * 2); }

        cmd.SetGlobalVector(Uniforms._FlareScreenPos, ScreenUVToNDC(screenPos * viewportAdjustment));
        cmd.SetGlobalFloat(Uniforms._FlareDepth, viewportPos.z);
        
        Vector2 screenPosPanini = ScreenUVToNDC(screenPos);
        if (paniniProjection.IsActive() && (cam.cameraType != CameraType.SceneView || PaniniProjectionSceneView.enabled))
            screenPosPanini = DoPaniniProjection(screenPosPanini, hdcam, paniniProjection, inverse:true);
        cmd.SetGlobalVector(Uniforms._FlareScreenPosPanini, screenPosPanini);

        var intensity = m_Intensity;
        var coneOuter = m_Feather * m_ConeAngle;
        var coneInner = m_ConeAngle - coneOuter;
        var angle = Vector3.Angle(transform.forward, -hdcam.camera.transform.forward);
        var innerAngle = angle - coneInner;
        intensity *= Mathf.SmoothStep(1, 0, innerAngle / coneOuter);
        cmd.SetGlobalFloat(Uniforms._FlareIntensity, intensity);

        cmd.SetGlobalFloat(Uniforms._OcclusionManual, m_OcclusionMode == OcclusionMode.Manual ? m_OcclusionManual : -1f);

        cmd.SetRenderTarget(src);

        foreach(FlareSettings flare in m_Flares)
		{
			if (flare.material == null)
				continue;

			Color color = (flare.multiplyByLightColor && m_Light != null) ? flare.color * m_Light.color * m_Light.intensity : flare.color;
			cmd.SetGlobalColor(Uniforms._FlareColor, color);

			float rotation = flare.rotation;
			if (flare.autoRotate)
				rotation = rotation == 0.0f ? -360.0f : -rotation;
			rotation *= Mathf.Deg2Rad;

			Vector4 data = new Vector4(flare.rayPosition, rotation, flare.size, flare.size * flare.aspectRatio);
			cmd.SetGlobalVector(Uniforms._FlareData, data);

            cmd.DrawMesh(m_Mesh, Matrix4x4.identity, flare.material, 0, 0);
		}

        cmd.EndSample("LensFlare");
    }

    // TODO: it makes no sense to duplicate this code, but current implementation in PostProcessing is such
    // that there's no way to re-use code. So copy-pasta for now, until the main implementation is refactored
    // and offers smth like static Vector2 DoPaniniProjection(Vector2 screenPos, HDCamera camera, bool inverse)
#region Panini Projection

    static Vector2 DoPaniniProjection(Vector2 screenPos, HDCamera camera, PaniniProjection paniniProjection, bool inverse)
    {
        float distance = paniniProjection.distance.value;
//custom-begin: hack to force panini to 1 in this resolution
            if (camera.actualWidth == 3168 && camera.actualHeight == 1056)
            {
                distance = 1;
            }
//custom-end:
        Vector2 viewExtents = CalcViewExtents(camera);
        Vector2 cropExtents = Panini_Generic_Inv(viewExtents, distance);

        float scaleX = cropExtents.x / viewExtents.x;
        float scaleY = cropExtents.y / viewExtents.y;
        float scaleF = Mathf.Min(scaleX, scaleY);

        float paniniD = distance;
        float paniniS = Mathf.Lerp(1.0f, Mathf.Clamp01(scaleF), paniniProjection.cropToFit.value);

        if (!inverse)
            return Panini_Generic(screenPos * viewExtents * paniniS, paniniD) / viewExtents;
        else
            return Panini_Generic_Inv(screenPos * viewExtents, paniniD) / (viewExtents * paniniS);
    }

    static Vector2 CalcViewExtents(HDCamera camera)
    {
        float fovY = camera.camera.fieldOfView * Mathf.Deg2Rad;
        float aspect = (float)camera.actualWidth / (float)camera.actualHeight;

        float viewExtY = Mathf.Tan(0.5f * fovY);
        float viewExtX = aspect * viewExtY;

        return new Vector2(viewExtX, viewExtY);
    }

    static Vector2 Panini_Generic(Vector2 view_pos, float d)
    {
        // Given
        //    S----------- E--X-------
        //    |    `  ~.  /,´
        //    |-- ---    Q
        //    |        ,/    `
        //  1 |      ,´/       `
        //    |    ,´ /         ´
        //    |  ,´  /           ´
        //    |,`   /             ,
        //    O    /
        //    |   /               ,
        //  d |  /
        //    | /                ,
        //    |/                .
        //    P 
        //    |              ´
        //    |         , ´
        //    +-    ´
        //
        // Have E
        // Want to find X
        //
        // First compute line-circle intersection to find Q
        // Then project Q to find X

        float view_dist = 1.0f + d;
        float view_hyp_sq = view_pos.x * view_pos.x + view_dist * view_dist;

        float isect_D = view_pos.x * d;
        float isect_discrim = view_hyp_sq - isect_D * isect_D;

        float cyl_dist_minus_d = (-isect_D * view_pos.x + view_dist * Mathf.Sqrt(isect_discrim)) / view_hyp_sq;
        float cyl_dist = cyl_dist_minus_d + d;

        Vector2 cyl_pos = view_pos * (cyl_dist / view_dist);
        return cyl_pos / (cyl_dist - d);
    }

    static Vector2 Panini_Generic_Inv(Vector2 projPos, float d)
    {
        // given
        //    S----------- E--X-------
        //    |    `  ~.  /,´
        //    |-- ---    Q
        //    |        ,/    `
        //  1 |      ,´/       `
        //    |    ,´ /         ´
        //    |  ,´  /           ´
        //    |,`   /             ,
        //    O    /
        //    |   /               ,
        //  d |  /
        //    | /                ,
        //    |/                .
        //    P
        //    |              ´
        //    |         , ´
        //    +-    ´
        //
        // have X
        // want to find E

        float viewDist = 1f + d;
        var projHyp = Mathf.Sqrt(projPos.x * projPos.x + 1f);

        float cylDistMinusD = 1f / projHyp;
        float cylDist = cylDistMinusD + d;
        var cylPos = projPos * cylDistMinusD;

        return cylPos * (viewDist / cylDist);
    }

#endregion

    [System.Serializable]
    public class FlareSettings
    {
        public float rayPosition;
		public float size;
		public float aspectRatio;
		[Space()]
        public Material material;
        [ColorUsage(true,true,0,10,0,10)]
        public Color color;
        public bool multiplyByLightColor;
		[Space()]
		[Range(0, 360)]
        public float rotation;
        public bool autoRotate;
    }
}
