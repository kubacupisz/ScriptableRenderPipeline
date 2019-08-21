using System;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Rendering.HighDefinition;
using System.Linq;

// Include material common properties names
using static UnityEngine.Rendering.HighDefinition.HDMaterialProperties;

namespace UnityEditor.Rendering.HighDefinition
{
    class LayeringOptionsUIBlock : MaterialUIBlock
    {
        public static class Styles
        {
            public const string header = "Layering Options";
            public static readonly GUIContent layerInfluenceMapMaskText = EditorGUIUtility.TrTextContent("Layer Influence Mask", "Specifies the Layer Influence Mask for this Material.");
            public static readonly GUIContent opacityAsDensityText = EditorGUIUtility.TrTextContent("Use Opacity map as Density map", "When enabled, HDRP uses the opacity map (alpha channel of Base Color) as the Density map.");
            public static readonly GUIContent inheritBaseNormalText = EditorGUIUtility.TrTextContent("Normal influence", "Controls the strength of the normals inherited from the base layer.");
            public static readonly GUIContent inheritBaseHeightText = EditorGUIUtility.TrTextContent("Heightmap influence", "Controls the strength of the height map inherited from the base layer.");
            public static readonly GUIContent inheritBaseColorText = EditorGUIUtility.TrTextContent("BaseColor influence", "Controls the strength of the Base Color inherited from the base layer.");

//custom-begin: slope mask feature
            public readonly GUIContent slopeMaskModeText = EditorGUIUtility.TrTextContent("Slope Mask Mode", "The Slope Mask is multiplied with the mask .");
            public readonly GUIContent slopeAngleText = EditorGUIUtility.TrTextContent("Slope Angle", "Slope under the angle value are part of the mask. Negative Value invert the mask");
            public readonly GUIContent slopeBiasText = EditorGUIUtility.TrTextContent("Slope Bias", "Used to smooth the Slope Mask");
            public readonly GUIContent slopeMaskIntensityText = EditorGUIUtility.TrTextContent("Slope Mask Influence", "Slope Mask Influence.");
            public readonly GUIContent slopeReferenceDirText = EditorGUIUtility.TrTextContent("Slope Reference Direction", "The direction used to compute the slope");
            public readonly GUIContent slopeSmoothNormalText = EditorGUIUtility.TrTextContent("Smooth Main Layer Normal for Slope", "Smooth the main layer normal map for the slope mask generation");
//custom-end: slope mask feature
        }

        // Influence
        MaterialProperty[] inheritBaseNormal = new MaterialProperty[kMaxLayerCount - 1];
        const string kInheritBaseNormal = "_InheritBaseNormal";
        MaterialProperty[] inheritBaseHeight = new MaterialProperty[kMaxLayerCount - 1];
        const string kInheritBaseHeight = "_InheritBaseHeight";
        MaterialProperty[] inheritBaseColor = new MaterialProperty[kMaxLayerCount - 1];
        const string kInheritBaseColor = "_InheritBaseColor";

        // Layer Options
        MaterialProperty layerInfluenceMaskMap = null;
        const string kLayerInfluenceMaskMap = "_LayerInfluenceMaskMap";
        MaterialProperty useMainLayerInfluence = null;
        const string kkUseMainLayerInfluence = "_UseMainLayerInfluence";

//custom-begin: slope mask feature
        // Slope mask
        MaterialProperty slopeMaskMode = null;
        const string kSlopeMaskMode = "_SlopeMaskMode";
        MaterialProperty slopeReferenceDir = null;
        const string kSlopeReferenceDir = "_SlopeReferenceDir";
        MaterialProperty slopeSmoothNormal = null;
        const string KSlopeSmoothNormal = "_SlopeSmoothNormal";
        MaterialProperty[] slopeAngle = new MaterialProperty[kMaxLayerCount - 1];
        const string kSlopeAngle = "_SlopeAngle";
        MaterialProperty[] slopeBias = new MaterialProperty[kMaxLayerCount - 1];
        const string kSlopeBias = "_SlopeBias";
        MaterialProperty[] slopeMaskIntensity = new MaterialProperty[kMaxLayerCount - 1];
        const string kSlopeMaskIntensity = "_SlopeMaskIntensity";
//custom-end: slope mask feature

        Expandable  m_ExpandableBit;
        int         m_LayerIndex;

        MaterialUIBlockList transparencyBlocks = new MaterialUIBlockList
        {
            new RefractionUIBlock(kMaxLayerCount),
            new DistortionUIBlock(),
        };

        // Density/opacity mode
        MaterialProperty[] opacityAsDensity = new MaterialProperty[kMaxLayerCount];
        const string kOpacityAsDensity = "_OpacityAsDensity";

        public LayeringOptionsUIBlock(Expandable expandableBit, int layerIndex)
        {
            m_ExpandableBit = expandableBit;
            m_LayerIndex = layerIndex;
        }

        public override void LoadMaterialProperties()
        {
            useMainLayerInfluence = FindProperty(kkUseMainLayerInfluence);
            layerInfluenceMaskMap = FindProperty(kLayerInfluenceMaskMap);

//custom-begin: slope mask feature
            slopeMaskMode = FindProperty(kSlopeMaskMode);
            slopeReferenceDir = FindProperty(kSlopeReferenceDir);
            slopeSmoothNormal = FindProperty(KSlopeSmoothNormal);
//custom-end: slope mask feature

            // Density/opacity mode
            opacityAsDensity = FindPropertyLayered(kOpacityAsDensity, kMaxLayerCount);

            for (int i = 1; i < kMaxLayerCount; ++i)
            {
                // Influence
                inheritBaseNormal[i - 1] = FindProperty(string.Format("{0}{1}", kInheritBaseNormal, i));
                inheritBaseHeight[i - 1] = FindProperty(string.Format("{0}{1}", kInheritBaseHeight, i));
                inheritBaseColor[i - 1] = FindProperty(string.Format("{0}{1}", kInheritBaseColor, i));

//custom-begin: slope mask feature
                    // Slope mask
                    slopeAngle[i - 1] = FindProperty(string.Format("{0}{1}", kSlopeAngle, i), props);
                    slopeBias[i - 1] = FindProperty(string.Format("{0}{1}", kSlopeBias, i), props);
                    slopeMaskIntensity[i - 1] = FindProperty(string.Format("{0}{1}", kSlopeMaskIntensity, i), props);
//custom-end: slope mask feature
            }
        }

        public override void OnGUI()
        {
            // We're using a subheader here because we know that layering options are only used within layers
            using (var header = new MaterialHeaderScope(Styles.header, (uint)m_ExpandableBit, materialEditor, colorDot: kLayerColors[m_LayerIndex], subHeader: true))
            {
                if (header.expanded)
                {
                    DrawLayeringOptionsGUI();
                }
            }
        }

        void DrawLayeringOptionsGUI()
        {
//custom-begin: slope mask feature
            bool mainLayerSlopeMaskModeEnable = slopeMaskMode.floatValue > 0.0f;
//custom-end:

            bool mainLayerInfluenceEnable = useMainLayerInfluence.floatValue > 0.0f;
            // Main layer does not have any options but height base blend.
            if (m_LayerIndex > 0)
            {
                materialEditor.ShaderProperty(opacityAsDensity[m_LayerIndex], Styles.opacityAsDensityText);

                if (mainLayerInfluenceEnable)
                {
                    materialEditor.ShaderProperty(inheritBaseColor[m_LayerIndex - 1], Styles.inheritBaseColorText);
                    materialEditor.ShaderProperty(inheritBaseNormal[m_LayerIndex - 1], Styles.inheritBaseNormalText);
                    // Main height influence is only available if the shader use the heightmap for displacement (per vertex or per level)
                    // We always display it as it can be tricky to know when per pixel displacement is enabled or not
                    materialEditor.ShaderProperty(inheritBaseHeight[m_LayerIndex - 1], Styles.inheritBaseHeightText);
                }

//custom-begin: slope mask feature
                if (mainLayerSlopeMaskModeEnable)
                {
                    EditorGUILayout.Space();
                    materialEditor.ShaderProperty(slopeAngle[layerIndex - 1], Styles.slopeAngleText);
                    materialEditor.ShaderProperty(slopeBias[layerIndex - 1], Styles.slopeBiasText);
                    materialEditor.ShaderProperty(slopeMaskIntensity[layerIndex - 1], Styles.slopeMaskIntensityText);
                }
//custom-end:
            }
            else
            {
                materialEditor.TexturePropertySingleLine(Styles.layerInfluenceMapMaskText, layerInfluenceMaskMap);

//custom-begin: slope mask feature
                if (header.expanded)
                {
                    materialEditor.ShaderProperty(slopeReferenceDir, Styles.slopeReferenceDirText);
                    materialEditor.ShaderProperty(slopeSmoothNormal, Styles.slopeSmoothNormalText);
                }
//custom-end:
            }
        }
    }
}
