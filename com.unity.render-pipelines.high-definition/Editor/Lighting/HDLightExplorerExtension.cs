using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering;
using UnityEngine.Rendering.HighDefinition;

namespace UnityEditor.Rendering.HighDefinition
{
    [LightingExplorerExtensionAttribute(typeof(HDRenderPipelineAsset))]
    class HDLightExplorerExtension : DefaultLightingExplorerExtension
    {
        struct LightData
        {
            public HDAdditionalLightData hdAdditionalLightData;
            public bool isPrefab;
            public Object prefabRoot;

            public LightData(HDAdditionalLightData hdAdditionalLightData, bool isPrefab, Object prefabRoot)
            {
                this.hdAdditionalLightData = hdAdditionalLightData;
                this.isPrefab = isPrefab;
                this.prefabRoot = prefabRoot;
            }
        }

        struct VolumeData
        {
            public bool isGlobal;
            public bool hasStaticLightingSky;
            public bool hasVisualEnvironment;
            public VolumeProfile profile;
            public FogType fogType;
            public SkyType skyType;

            public VolumeData(bool isGlobal, VolumeProfile profile, bool hasStaticLightingSky)
            {
                this.isGlobal = isGlobal;
                this.profile = profile;
                VisualEnvironment visualEnvironment = null;
                this.hasVisualEnvironment = profile != null ? profile.TryGet<VisualEnvironment>(typeof(VisualEnvironment), out visualEnvironment) : false;
                if (this.hasVisualEnvironment)
                {
                    this.skyType = (SkyType)visualEnvironment.skyType.value;
                    this.fogType = visualEnvironment.fogType.value;
                }
                else
                {
                    this.skyType = (SkyType)1;
                    this.fogType = (FogType)0;
                }
                this.hasStaticLightingSky = hasStaticLightingSky;
            }
        }

        static Dictionary<Light, LightData> lightDataPairing = new Dictionary<Light, LightData>();

        static Dictionary<Volume, VolumeData> volumeDataPairing = new Dictionary<Volume, VolumeData>();

        static Dictionary<ReflectionProbe, HDAdditionalReflectionData> reflectionProbeDataPairing = new Dictionary<ReflectionProbe, HDAdditionalReflectionData>();

        protected static class HDStyles
        {
            public static readonly GUIContent Name = EditorGUIUtility.TrTextContent("Name");
            public static readonly GUIContent On = EditorGUIUtility.TrTextContent("On");
            public static readonly GUIContent Type = EditorGUIUtility.TrTextContent("Type");
            public static readonly GUIContent Mode = EditorGUIUtility.TrTextContent("Mode");
            public static readonly GUIContent Range = EditorGUIUtility.TrTextContent("Range");
            public static readonly GUIContent Color = EditorGUIUtility.TrTextContent("Color");
            public static readonly GUIContent ColorFilter = EditorGUIUtility.TrTextContent("Color Filter");
            public static readonly GUIContent Intensity = EditorGUIUtility.TrTextContent("Intensity");
            public static readonly GUIContent IndirectMultiplier = EditorGUIUtility.TrTextContent("Indirect Multiplier");
            public static readonly GUIContent Unit = EditorGUIUtility.TrTextContent("Unit");
            public static readonly GUIContent ColorTemperature = EditorGUIUtility.TrTextContent("Color Temperature");
            public static readonly GUIContent Shadows = EditorGUIUtility.TrTextContent("Shadows");
            public static readonly GUIContent ContactShadows = EditorGUIUtility.TrTextContent("Contact Shadows");
            public static readonly GUIContent ShadowResolutionTier = EditorGUIUtility.TrTextContent("Shadows Resolution");
            public static readonly GUIContent UseShadowQualitySettings = EditorGUIUtility.TrTextContent("Use Shadow Quality Settings");
            public static readonly GUIContent CustomShadowResolution = EditorGUIUtility.TrTextContent("Shadow Resolution");
            public static readonly GUIContent ShapeWidth = EditorGUIUtility.TrTextContent("Shape Width");
            public static readonly GUIContent VolumeProfile = EditorGUIUtility.TrTextContent("Volume Profile");
            public static readonly GUIContent ColorTemperatureMode = EditorGUIUtility.TrTextContent("Use Color Temperature");
            public static readonly GUIContent AffectDiffuse = EditorGUIUtility.TrTextContent("Affect Diffuse");
            public static readonly GUIContent AffectSpecular = EditorGUIUtility.TrTextContent("Affect Specular");
            public static readonly GUIContent FadeDistance = EditorGUIUtility.TrTextContent("Fade Distance");
            public static readonly GUIContent ShadowFadeDistance = EditorGUIUtility.TrTextContent("Shadow Fade Distance");
            public static readonly GUIContent LightLayer = EditorGUIUtility.TrTextContent("Light Layer");
            public static readonly GUIContent IsPrefab = EditorGUIUtility.TrTextContent("Prefab");

            public static readonly GUIContent GlobalVolume = EditorGUIUtility.TrTextContent("Is Global");
            public static readonly GUIContent Priority = EditorGUIUtility.TrTextContent("Priority");
            public static readonly GUIContent HasVisualEnvironment = EditorGUIUtility.TrTextContent("Has Visual Environment");
            public static readonly GUIContent FogType = EditorGUIUtility.TrTextContent("Fog Type");
            public static readonly GUIContent SkyType = EditorGUIUtility.TrTextContent("Sky Type");
            public static readonly GUIContent HasStaticLightingSky = EditorGUIUtility.TrTextContent("Has Static Lighting Sky");

            public static readonly GUIContent ReflectionProbeMode = EditorGUIUtility.TrTextContent("Mode");
            public static readonly GUIContent ReflectionProbeShape = EditorGUIUtility.TrTextContent("Shape");
            public static readonly GUIContent ReflectionProbeShadowDistance = EditorGUIUtility.TrTextContent("Shadow Distance");
            public static readonly GUIContent ReflectionProbeNearClip = EditorGUIUtility.TrTextContent("Near Clip");
            public static readonly GUIContent ReflectionProbeFarClip = EditorGUIUtility.TrTextContent("Far Clip");
            public static readonly GUIContent ParallaxCorrection = EditorGUIUtility.TrTextContent("Parallax Correction");
            public static readonly GUIContent ReflectionProbeWeight = EditorGUIUtility.TrTextContent("Weight");

            public static readonly GUIContent DrawProbes = EditorGUIUtility.TrTextContent("Draw");
            public static readonly GUIContent DebugColor = EditorGUIUtility.TrTextContent("Debug Color");
            public static readonly GUIContent ResolutionX = EditorGUIUtility.TrTextContent("Resolution X");
            public static readonly GUIContent ResolutionY = EditorGUIUtility.TrTextContent("Resolution Y");
            public static readonly GUIContent ResolutionZ = EditorGUIUtility.TrTextContent("Resolution Z");
            public static readonly GUIContent FadeStart = EditorGUIUtility.TrTextContent("Fade Start");
            public static readonly GUIContent FadeEnd = EditorGUIUtility.TrTextContent("Fade End");

            public static readonly GUIContent[] LightmapBakeTypeTitles = { EditorGUIUtility.TrTextContent("Realtime"), EditorGUIUtility.TrTextContent("Mixed"), EditorGUIUtility.TrTextContent("Baked") };
            public static readonly int[] LightmapBakeTypeValues = { (int)LightmapBakeType.Realtime, (int)LightmapBakeType.Mixed, (int)LightmapBakeType.Baked };
        }

        public override LightingExplorerTab[] GetContentTabs()
        {
            return new[]
            {
                new LightingExplorerTab("Lights", GetHDLights, GetHDLightColumns),
                new LightingExplorerTab("Volumes", GetVolumes, GetVolumeColumns),
                new LightingExplorerTab("Reflection Probes", GetHDReflectionProbes, GetHDReflectionProbeColumns),
                new LightingExplorerTab("Planar Reflection Probes", GetPlanarReflections, GetPlanarReflectionColumns),
                new LightingExplorerTab("Light Probes", GetLightProbes, GetLightProbeColumns),
                new LightingExplorerTab("Probe Volumes", GetProbeVolumes, GetProbeVolumeColumns),
                new LightingExplorerTab("Emissive Materials", GetEmissives, GetEmissivesColumns)
            };
        }

        protected virtual UnityEngine.Object[] GetHDLights()
        {
            var lights = UnityEngine.Object.FindObjectsOfType<Light>();
            foreach (Light light in lights)
            {
                if (PrefabUtility.GetCorrespondingObjectFromSource(light) != null) // We have a prefab
                {
                    lightDataPairing[light] = new LightData(light.GetComponent<HDAdditionalLightData>(),
                                                            true, PrefabUtility.GetCorrespondingObjectFromSource(PrefabUtility.GetOutermostPrefabInstanceRoot(light.gameObject)));
                }
                else
                {
                    lightDataPairing[light] = new LightData(light.GetComponent<HDAdditionalLightData>(), false, null);
                }
            }
            return lights;
        }

        protected virtual UnityEngine.Object[] GetHDReflectionProbes()
        {
            var reflectionProbes = Object.FindObjectsOfType<ReflectionProbe>();
            {
                foreach (ReflectionProbe probe in reflectionProbes)
                {
                    reflectionProbeDataPairing[probe] = probe.GetComponent<HDAdditionalReflectionData>();
                }
            }
            return reflectionProbes;
        }

        protected virtual UnityEngine.Object[] GetPlanarReflections()
        {
            return UnityEngine.Object.FindObjectsOfType<PlanarReflectionProbe>();
        }

        protected virtual UnityEngine.Object[] GetVolumes()
        {
            var volumes = UnityEngine.Object.FindObjectsOfType<Volume>();
            foreach (var volume in volumes)
            {
                bool hasStaticLightingSky = volume.GetComponent<StaticLightingSky>();
                volumeDataPairing[volume] = !volume.HasInstantiatedProfile() && volume.sharedProfile == null
                    ? new VolumeData(volume.isGlobal, null, hasStaticLightingSky)
                    : new VolumeData(volume.isGlobal, volume.HasInstantiatedProfile() ? volume.profile : volume.sharedProfile, hasStaticLightingSky);
            }
            return volumes;
        }

        protected virtual UnityEngine.Object[] GetProbeVolumes()
        {
            return Resources.FindObjectsOfTypeAll<ProbeVolume>();
        }

        protected virtual LightingExplorerTableColumn[] GetHDLightColumns()
        {
            return new[]
            {
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Name, HDStyles.Name, null, 200),                                               // 0: Name
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.On, "m_Enabled", 25),                                       // 1: Enabled
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Enum, HDStyles.Type, "m_Type", 60),                                            // 2: Type
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Enum, HDStyles.Mode, "m_Lightmapping", 60),                                    // 3: Mixed mode
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Enum, HDStyles.Range, "m_Range", 60),                                           // 4: Range
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.ColorTemperatureMode, "m_UseColorTemperature", 100),         // 5: Color Temperature Mode
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Color, HDStyles.Color, "m_Color", 60),                                         // 6: Color
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ColorTemperature, "m_ColorTemperature", 100,(r, prop, dep) =>  // 7: Color Temperature
                {
                    if (prop.serializedObject.FindProperty("m_UseColorTemperature").boolValue)
                    {
                        prop = prop.serializedObject.FindProperty("m_ColorTemperature");
                        prop.floatValue = EditorGUI.FloatField(r,prop.floatValue);
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.Intensity, "m_Intensity", 60, (r, prop, dep) =>                // 8: Intensity
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    float intensity = lightDataPairing[light].hdAdditionalLightData.intensity;
                    EditorGUI.BeginChangeCheck();
                    intensity = EditorGUI.FloatField(r, intensity);
                    if (EditorGUI.EndChangeCheck())
                    {
                        Undo.RecordObject(lightDataPairing[light].hdAdditionalLightData, "Changed light intensity");
                        lightDataPairing[light].hdAdditionalLightData.intensity = intensity;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.Unit, "m_Intensity", 60, (r, prop, dep) =>                // 9: Unit
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    LightUnit unit = lightDataPairing[light].hdAdditionalLightData.lightUnit;
                    EditorGUI.BeginChangeCheck();
                    unit = (LightUnit)EditorGUI.EnumPopup(r, unit);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.lightUnit = unit;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.IndirectMultiplier, "m_BounceIntensity", 90),                  // 10: Indirect multiplier
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.Shadows, "m_Shadows.m_Type", 60, (r, prop, dep) =>          // 11: Shadows
                {
                    EditorGUI.BeginChangeCheck();
                    bool shadows = EditorGUI.Toggle(r, prop.intValue != (int)LightShadows.None);
                    if (EditorGUI.EndChangeCheck())
                    {
                        prop.intValue = shadows ? (int)LightShadows.Soft : (int)LightShadows.None;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.ContactShadows, "m_Shadows.m_Type", 100, (r, prop, dep) =>  // 12: Contact Shadows
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool contactShadows = lightDataPairing[light].hdAdditionalLightData.contactShadows;
                    EditorGUI.BeginChangeCheck();
                    contactShadows = EditorGUI.Toggle(r, contactShadows);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.contactShadows = contactShadows;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.UseShadowQualitySettings, "m_Intensity", 60, (r, prop, dep) =>           // 13: Use Custom Shadow Res
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool useQualitySettings = lightDataPairing[light].hdAdditionalLightData.useShadowQualitySettings;
                    EditorGUI.BeginChangeCheck();
                    useQualitySettings = EditorGUI.Toggle(r, useQualitySettings);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.useShadowQualitySettings = useQualitySettings;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Enum, HDStyles.ShadowResolutionTier, "m_Intensity", 60, (r, prop, dep) =>           // 14: Shadow tiers
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    ShadowResolutionTier resTier = lightDataPairing[light].hdAdditionalLightData.shadowResolutionTier;
                    EditorGUI.BeginChangeCheck();
                    resTier = (ShadowResolutionTier)EditorGUI.EnumPopup(r, resTier);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.shadowResolutionTier = resTier;
                    }
                }),

                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Int, HDStyles.CustomShadowResolution, "m_Intensity", 60, (r, prop, dep) =>           // 15: Custom Shadow resolution
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    int customResolution = lightDataPairing[light].hdAdditionalLightData.customResolution;
                    EditorGUI.BeginChangeCheck();
                    customResolution = EditorGUI.IntField(r, customResolution);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.customResolution = customResolution;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.AffectDiffuse, "m_Intensity", 90, (r, prop, dep) =>         // 16: Affect Diffuse
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool affectDiffuse = lightDataPairing[light].hdAdditionalLightData.affectDiffuse;
                    EditorGUI.BeginChangeCheck();
                    affectDiffuse = EditorGUI.Toggle(r, affectDiffuse);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.affectDiffuse = affectDiffuse;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.AffectSpecular, "m_Intensity", 90, (r, prop, dep) =>        // 17: Affect Specular
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool affectSpecular = lightDataPairing[light].hdAdditionalLightData.affectSpecular;
                    EditorGUI.BeginChangeCheck();
                    affectSpecular = EditorGUI.Toggle(r, affectSpecular);
                    if (EditorGUI.EndChangeCheck())
                    {
                        lightDataPairing[light].hdAdditionalLightData.affectSpecular = affectSpecular;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.FadeDistance, "m_Intensity", 60, (r, prop, dep) =>                // 18: Fade Distance
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    float fadeDistance = lightDataPairing[light].hdAdditionalLightData.fadeDistance;
                    EditorGUI.BeginChangeCheck();
                    fadeDistance = EditorGUI.FloatField(r, fadeDistance);
                    if (EditorGUI.EndChangeCheck())
                    {
                        Undo.RecordObject(lightDataPairing[light].hdAdditionalLightData, "Changed light fade distance");
                        lightDataPairing[light].hdAdditionalLightData.fadeDistance = fadeDistance;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ShadowFadeDistance, "m_Intensity", 60, (r, prop, dep) =>           // 19: Shadow Fade Distance
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null || lightDataPairing[light].hdAdditionalLightData == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    float shadowFadeDistance = lightDataPairing[light].hdAdditionalLightData.shadowFadeDistance;
                    EditorGUI.BeginChangeCheck();
                    shadowFadeDistance = EditorGUI.FloatField(r, shadowFadeDistance);
                    if (EditorGUI.EndChangeCheck())
                    {
                        Undo.RecordObject(lightDataPairing[light].hdAdditionalLightData, "Changed light shadow fade distance");
                        lightDataPairing[light].hdAdditionalLightData.shadowFadeDistance = shadowFadeDistance;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Custom, HDStyles.LightLayer, "m_RenderingLayerMask", 80, (r, prop, dep) =>     // 20: Light Layer
                {
                    using (new EditorGUI.DisabledScope(!(GraphicsSettings.renderPipelineAsset as HDRenderPipelineAsset).currentPlatformRenderPipelineSettings.supportLightLayers))
                    {
                        HDEditorUtils.LightLayerMaskPropertyDrawer(r,prop);
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Custom, HDStyles.IsPrefab, "m_Intensity", 60, (r, prop, dep) =>                // 21: Prefab
                {
                    Light light = prop.serializedObject.targetObject as Light;
                    if(light == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool isPrefab = lightDataPairing[light].isPrefab;
                    if (isPrefab)
                    {
                        EditorGUI.ObjectField(r, lightDataPairing[light].prefabRoot, typeof(GameObject),false);
                    }
                }),

            };
        }

        protected virtual LightingExplorerTableColumn[] GetVolumeColumns()
        {
            return new[]
            {
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Name, HDStyles.Name, null, 200),                                               // 0: Name
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.On, "m_Enabled", 25),                                       // 1: Enabled
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.GlobalVolume, "isGlobal", 60),                              // 2: Is Global
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.Priority, "priority", 60),                                     // 3: Priority
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Custom, HDStyles.VolumeProfile, "sharedProfile", 100, (r, prop, dep) =>        // 4: Profile
                {
                    if (prop.objectReferenceValue != null )
                        EditorGUI.PropertyField(r, prop, GUIContent.none);
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.HasVisualEnvironment, "sharedProfile", 100, (r, prop, dep) =>// 5: Has Visual environment
                {
                    Volume volume = prop.serializedObject.targetObject as Volume;
                    if(volume == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool hasVisualEnvironment = volumeDataPairing[volume].hasVisualEnvironment;
                    EditorGUI.BeginDisabledGroup(true);
                    EditorGUI.Toggle(r, hasVisualEnvironment);
                    EditorGUI.EndDisabledGroup();
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Custom, HDStyles.SkyType, "sharedProfile", 100, (r, prop, dep) =>              // 6: Sky type
                {
                    Volume volume = prop.serializedObject.targetObject as Volume;
                    if(volume == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    if (volumeDataPairing[volume].hasVisualEnvironment)
                    {
                        SkyType skyType = volumeDataPairing[volume].skyType;
                        EditorGUI.BeginDisabledGroup(true);
                        EditorGUI.EnumPopup(r, skyType);
                        EditorGUI.EndDisabledGroup();
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Custom, HDStyles.FogType, "sharedProfile", 100, (r, prop, dep) =>              // 7: Fog type
                {
                    Volume volume = prop.serializedObject.targetObject as Volume;
                    if(volume == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    if (volumeDataPairing[volume].hasVisualEnvironment)
                    {
                        FogType fogType = volumeDataPairing[volume].fogType;
                        EditorGUI.BeginDisabledGroup(true);
                        EditorGUI.EnumPopup(r, fogType);
                        EditorGUI.EndDisabledGroup();
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.HasStaticLightingSky, "sharedProfile", 100, (r, prop, dep) =>       // 8: Has Static Lighting Sky
                {
                    Volume volume = prop.serializedObject.targetObject as Volume;
                    if(volume == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    bool hasStaticLightingSky = volumeDataPairing[volume].hasStaticLightingSky;
                    EditorGUI.BeginDisabledGroup(true);
                    EditorGUI.Toggle(r, hasStaticLightingSky);
                    EditorGUI.EndDisabledGroup();
                }),
            };
        }

        protected virtual LightingExplorerTableColumn[] GetHDReflectionProbeColumns()
        {
            return new[]
            {
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Name, HDStyles.Name, null, 200),                                               // 0: Name
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.On, "m_Enabled", 25),                                       // 1: Enabled
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Enum, HDStyles.ReflectionProbeMode, "m_Mode", 60, (r, prop, dep) =>            // 2: Mode
                {
                    prop.intValue = (int)(UnityEngine.Rendering.ReflectionProbeMode)EditorGUI.EnumPopup(r,(UnityEngine.Rendering.ReflectionProbeMode)prop.intValue);
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Enum, HDStyles.ReflectionProbeShape, "m_Mode", 60, (r, prop, dep) =>           // 3: Shape
                {
                    ReflectionProbe probe = prop.serializedObject.targetObject as ReflectionProbe;
                    if(probe == null)
                    {
                        EditorGUI.LabelField(r,"null");
                        return;
                    }
                    InfluenceShape influenceShape = reflectionProbeDataPairing[probe].influenceVolume.shape;
                    EditorGUI.BeginChangeCheck();
                    influenceShape = (InfluenceShape)EditorGUI.EnumPopup(r, influenceShape);
                    if (EditorGUI.EndChangeCheck())
                    {
                        reflectionProbeDataPairing[probe].influenceVolume.shape = influenceShape;
                    }
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ReflectionProbeShadowDistance, "m_ShadowDistance", 90),        // 4: Shadow distance
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ReflectionProbeNearClip, "m_NearClip", 60),                    // 5: Near clip
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ReflectionProbeFarClip, "m_FarClip", 60),                      // 6: Far clip
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.ParallaxCorrection, "m_BoxProjection", 90),                 // 7: Parallax correction
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ReflectionProbeWeight, "m_Mode", 60, (r, prop, dep) =>         // 8: Weight
                {
                    ReflectionProbe probe = prop.serializedObject.targetObject as ReflectionProbe;

                    float weight = reflectionProbeDataPairing[probe].weight;
                    EditorGUI.BeginChangeCheck();
                    weight = EditorGUI.FloatField(r, weight);
                    if (EditorGUI.EndChangeCheck())
                    {
                        reflectionProbeDataPairing[probe].weight = weight;
                    }
                }),
            };
        }

        protected virtual LightingExplorerTableColumn[] GetPlanarReflectionColumns()
        {
            return new[]
            {
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Name, HDStyles.Name, null, 200),                                               // 0: Name
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.On, "m_Enabled", 25),                                       // 1: Enabled
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.ReflectionProbeWeight, "m_ProbeSettings.lighting.weight", 50), // 2: Weight
            };
        }

        protected virtual LightingExplorerTableColumn[] GetProbeVolumeColumns()
        {
            return new[]
            {
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Name, HDStyles.Name, null, 200),                                       // 0: Name
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Checkbox, HDStyles.DrawProbes, "parameters", 35, (r, prop, dep) =>       // 1: Draw Probes
                {
                    SerializedProperty drawProbes = prop.FindPropertyRelative("drawProbes");
                    EditorGUI.PropertyField(r, drawProbes, GUIContent.none);
                }, (lhs, rhs) =>
                {
                    return lhs.FindPropertyRelative("drawProbes").boolValue.CompareTo(rhs.FindPropertyRelative("drawProbes").boolValue);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("drawProbes").boolValue = source.FindPropertyRelative("drawProbes").boolValue;
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Color, HDStyles.DebugColor, "parameters", 75, (r, prop, dep) =>       // 2: Debug Color
                {
                    SerializedProperty debugColor = prop.FindPropertyRelative("debugColor");
                    EditorGUI.PropertyField(r, debugColor, GUIContent.none);
                }, (lhs, rhs) =>
                {
                    float lh, ls, lv, rh, rs, rv;
                    Color.RGBToHSV(lhs.FindPropertyRelative("debugColor").colorValue, out lh, out ls, out lv);
                    Color.RGBToHSV(rhs.FindPropertyRelative("debugColor").colorValue, out rh, out rs, out rv);
                    return lh.CompareTo(rh);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("debugColor").colorValue = source.FindPropertyRelative("debugColor").colorValue;
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Int, HDStyles.ResolutionX, "parameters", 75, (r, prop, dep) =>      // 3: Resolution X
                {
                    SerializedProperty resolutionX = prop.FindPropertyRelative("resolutionX");

                    EditorGUI.BeginChangeCheck();
                    EditorGUI.PropertyField(r, resolutionX, GUIContent.none);

                    if (EditorGUI.EndChangeCheck())
                    {
                        resolutionX.intValue = Mathf.Max(1, resolutionX.intValue);
                    }
                }, (lhs, rhs) =>
                {
                    return lhs.FindPropertyRelative("resolutionX").intValue.CompareTo(rhs.FindPropertyRelative("resolutionX").intValue);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("resolutionX").intValue = source.FindPropertyRelative("resolutionX").intValue;
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Int, HDStyles.ResolutionY, "parameters", 75, (r, prop, dep) =>      // 4: Resolution Y
                {
                    SerializedProperty resolutionY = prop.FindPropertyRelative("resolutionY");

                    EditorGUI.BeginChangeCheck();
                    EditorGUI.PropertyField(r, resolutionY, GUIContent.none);

                    if (EditorGUI.EndChangeCheck())
                    {
                        SerializedProperty resolutionX = prop.FindPropertyRelative("resolutionX");
                        resolutionY.intValue = Mathf.Max(1, resolutionY.intValue);
                    }
                }, (lhs, rhs) =>
                {
                    return lhs.FindPropertyRelative("resolutionY").intValue.CompareTo(rhs.FindPropertyRelative("resolutionY").intValue);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("resolutionY").intValue = source.FindPropertyRelative("resolutionY").intValue;
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Int, HDStyles.ResolutionZ, "parameters", 75, (r, prop, dep) =>      // 5: Resolution Z
                {
                    SerializedProperty resolutionZ = prop.FindPropertyRelative("resolutionZ");
                    
                    EditorGUI.BeginChangeCheck();
                    EditorGUI.PropertyField(r, resolutionZ, GUIContent.none);

                    if (EditorGUI.EndChangeCheck())
                    {
                        SerializedProperty resolutionX = prop.FindPropertyRelative("resolutionX");
                        resolutionZ.intValue = Mathf.Max(1, resolutionZ.intValue);
                    }
                }, (lhs, rhs) =>
                {
                    return lhs.FindPropertyRelative("resolutionZ").intValue.CompareTo(rhs.FindPropertyRelative("resolutionZ").intValue);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("resolutionZ").intValue = source.FindPropertyRelative("resolutionZ").intValue;
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.FadeStart, "parameters", 65, (r, prop, dep) =>        // 6: Distance Fade Start
                {
                    SerializedProperty distanceFadeStart = prop.FindPropertyRelative("distanceFadeStart");
                    EditorGUI.PropertyField(r, distanceFadeStart, GUIContent.none);
                }, (lhs, rhs) =>
                {
                    return lhs.FindPropertyRelative("distanceFadeStart").floatValue.CompareTo(rhs.FindPropertyRelative("distanceFadeStart").floatValue);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("distanceFadeStart").floatValue = source.FindPropertyRelative("distanceFadeStart").floatValue;
                }),
                new LightingExplorerTableColumn(LightingExplorerTableColumn.DataType.Float, HDStyles.FadeEnd, "parameters", 65, (r, prop, dep) =>          // 7: Distance Fade End
                {
                    SerializedProperty distanceFadeEnd = prop.FindPropertyRelative("distanceFadeEnd");
                    EditorGUI.PropertyField(r, distanceFadeEnd, GUIContent.none);
                }, (lhs, rhs) =>
                {
                    return lhs.FindPropertyRelative("distanceFadeEnd").floatValue.CompareTo(rhs.FindPropertyRelative("distanceFadeEnd").floatValue);
                }, (target, source) => 
                {
                    target.FindPropertyRelative("distanceFadeEnd").floatValue = source.FindPropertyRelative("distanceFadeEnd").floatValue;
                })
            };
        }

        public override void OnDisable()
        {
            lightDataPairing.Clear();
            volumeDataPairing.Clear();
            reflectionProbeDataPairing.Clear();
        }
    }
}
