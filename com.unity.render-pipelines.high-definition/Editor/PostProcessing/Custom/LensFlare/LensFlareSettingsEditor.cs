using UnityEngine;
using UnityEditor;

[CustomEditor(typeof(LensFlareSettings))]
public class LensFlareSettingsEditor : Editor
{
	SerializedProperty m_Light;
	SerializedProperty m_OcclusionMode;
	SerializedProperty m_OcclusionRadius;
	SerializedProperty m_OcclusionManual;
	SerializedProperty m_Intensity;
    SerializedProperty m_ConeAngle;
    SerializedProperty m_Feather;
    SerializedProperty m_Flares;

	void OnEnable()
	{
		m_Light = serializedObject.FindProperty ("m_Light");
		m_OcclusionMode = serializedObject.FindProperty ("m_OcclusionMode");
		m_OcclusionRadius = serializedObject.FindProperty ("m_OcclusionRadius");
		m_OcclusionManual = serializedObject.FindProperty ("m_OcclusionManual");
		m_Intensity = serializedObject.FindProperty ("m_Intensity");
        m_ConeAngle = serializedObject.FindProperty("m_ConeAngle");
        m_Feather = serializedObject.FindProperty("m_Feather");
        m_Flares = serializedObject.FindProperty ("m_Flares");
	}

	override public void OnInspectorGUI()
	{
		serializedObject.Update();

		EditorGUILayout.PropertyField(m_Light);
        if (m_Light.objectReferenceValue == null)
        {
            EditorGUILayout.HelpBox("Light is not set. Position of this object will be used instead", MessageType.Info);
        }
		EditorGUILayout.PropertyField(m_Intensity);
        EditorGUILayout.PropertyField(m_ConeAngle);
        EditorGUILayout.PropertyField(m_Feather);


        EditorGUILayout.PropertyField(m_OcclusionMode);

		if(m_OcclusionMode.enumValueIndex == (int)LensFlareSettings.OcclusionMode.Automatic)
			EditorGUILayout.PropertyField(m_OcclusionRadius);
		else
			EditorGUILayout.PropertyField(m_OcclusionManual);

		EditorGUILayout.PropertyField(m_Flares, true);

		serializedObject.ApplyModifiedProperties();
	}
}
