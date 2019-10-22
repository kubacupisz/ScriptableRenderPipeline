namespace UnityEditor.Rendering.HighDefinition
{
    class SerializedProbeVolume
    {
        public SerializedProperty probeVolumeParams;
        public SerializedProperty probeVolumeAsset;
        public SerializedProperty debugColor;
        public SerializedProperty drawProbes;

        public SerializedProperty resolutionX;
        public SerializedProperty resolutionY;
        public SerializedProperty resolutionZ;

        public SerializedProperty weight;

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
            probeVolumeAsset = m_SerializedObject.FindProperty("probeVolumeAsset");

            debugColor = probeVolumeParams.FindPropertyRelative("debugColor");
            drawProbes = probeVolumeParams.FindPropertyRelative("drawProbes");

            resolutionX = probeVolumeParams.FindPropertyRelative("resolutionX");
            resolutionY = probeVolumeParams.FindPropertyRelative("resolutionY");
            resolutionZ = probeVolumeParams.FindPropertyRelative("resolutionZ");

            weight = probeVolumeParams.FindPropertyRelative("weight");

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
