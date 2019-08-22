using System;
using UnityEngine;
using UnityEngine.Rendering;

namespace UnityEngine.Rendering.HighDefinition
{
    [Serializable, VolumeComponentMenu("Custom/Lens Flare")]
    public sealed class LensFlare : VolumeComponent, IPostProcessComponent
    {
        public bool IsActive()
        {
            return LensFlareSettings.Instance != null && active;
        }
    }
}
