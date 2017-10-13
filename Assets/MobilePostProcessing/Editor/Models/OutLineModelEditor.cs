using UnityEngine;
using UnityEngine.PostProcessing;

namespace UnityEditor.PostProcessing
{
    using Settings = OutLineModel.Settings;

    [PostProcessingModelEditor(typeof(OutLineModel))]

    //public class OutLineModelEditor : DefaultPostFxModelEditor
    //{
    //}

    public class OutLineModelEditor : PostProcessingModelEditor
    {
        struct OutLineSettings
        {
            public SerializedProperty blurSize;
            public SerializedProperty rtScale;
            public SerializedProperty outterColor;

        }

        OutLineSettings m_OutLine;

        public override void OnEnable()
        {
            m_OutLine = new OutLineSettings
            {
                blurSize = FindSetting((Settings x) => x.outLine.blurSize),
                rtScale = FindSetting((Settings x) => x.outLine.rtScale),
                outterColor = FindSetting((Settings x) => x.outLine.outterColor),
            };

        }

        public override void OnInspectorGUI()
        {

            EditorGUILayout.PropertyField(m_OutLine.blurSize);
            EditorGUILayout.PropertyField(m_OutLine.rtScale);
            EditorGUILayout.PropertyField(m_OutLine.outterColor);

        }

    }

}
