namespace UnityEditor.Experimental.Rendering.HDPipeline
{
    class SerializedProbeVolume
    {
        public SerializedProperty probeVolumeParams;
        public SerializedProperty debugColor;
        public SerializedProperty resolutionX;
        public SerializedProperty resolutionY;
        public SerializedProperty resolutionZ;

        public SerializedProperty size;

        public SerializedProperty positiveFade;
        public SerializedProperty negativeFade;
        public SerializedProperty uniformFade;
        public SerializedProperty advancedFade;

        public SerializedProperty distanceFadeStart;
        public SerializedProperty distanceFadeEnd;

        SerializedObject m_SerializedObject;

        public SerializedProbeVolume(SerializedObject serializedObject)
        {
            m_SerializedObject = serializedObject;

            probeVolumeParams = m_SerializedObject.FindProperty("parameters");

            debugColor = probeVolumeParams.FindPropertyRelative("debugColor");

            resolutionX = probeVolumeParams.FindPropertyRelative("resolutionX");
            resolutionY = probeVolumeParams.FindPropertyRelative("resolutionY");
            resolutionZ = probeVolumeParams.FindPropertyRelative("resolutionZ");

            size = probeVolumeParams.FindPropertyRelative("size");

            positiveFade = probeVolumeParams.FindPropertyRelative("m_PositiveFade");
            negativeFade = probeVolumeParams.FindPropertyRelative("m_NegativeFade");

            uniformFade = probeVolumeParams.FindPropertyRelative("m_UniformFade");
            advancedFade = probeVolumeParams.FindPropertyRelative("advancedFade");

            distanceFadeStart = probeVolumeParams.FindPropertyRelative("distanceFadeStart");
            distanceFadeEnd   = probeVolumeParams.FindPropertyRelative("distanceFadeEnd");
        }

        public void Apply()
        {
            m_SerializedObject.ApplyModifiedProperties();
        }
    }
}
