using System.Collections.Generic;
using UnityEngine.Rendering;

namespace UnityEngine.Rendering.HighDefinition
{
    public class ProbeVolumeManager
    {
        static private ProbeVolumeManager _instance = null;

        public static ProbeVolumeManager manager
        {
            get
            {
                if (_instance == null)
                {
                    _instance = new ProbeVolumeManager();
                }
                return _instance;
            }
        }
        private ProbeVolumeManager()
        {
            volumes = new List<ProbeVolume>();
        }

        public List<ProbeVolume> volumes = null;

        public void RegisterVolume(ProbeVolume volume)
        {
            if (volumes.Contains(volume))
                return;

            volumes.Add(volume);
        }
        public void DeRegisterVolume(ProbeVolume volume)
        {
            if (!volumes.Contains(volume))
                return;

            volumes.Remove(volume);
        }
#if UNITY_EDITOR
        public void ReactivateProbes()
        {
            foreach (ProbeVolume v in volumes)
            {
                v.EnableBaking();
            }
#if PROBEBAKE_API
            UnityEditor.Lightmapping.additionalBakedProbesCompleted -= ReactivateProbes;
#endif
        }
        public static void BakeSingle(ProbeVolume probeVolume)
        {
            if (!probeVolume)
                return;

            foreach (ProbeVolume v in manager.volumes)
            {
                if (v == probeVolume)
                    continue;

                v.DisableBaking();
            }
#if PROBEBAKE_API
            UnityEditor.Lightmapping.additionalBakedProbesCompleted += manager.ReactivateProbes;
#endif
            UnityEditor.Lightmapping.BakeAsync();
        }
    }
#endif
        }
