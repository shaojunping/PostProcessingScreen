using UnityEngine;
using UnityEngine.PostProcessing;

namespace UnityEditor.PostProcessing
{
    using Settings = SkyScatterModel.Settings;

    [PostProcessingModelEditor(typeof(SkyScatterModel))]

    public class SkyScatterModellEditor : DefaultPostFxModelEditor
    {
    }

    //public class SkyScatterModellEditor : PostProcessingModelEditor
    //{
    //    struct SkyScatterSettings
    //    {
    //        public SerializedProperty blurSize;
    //        public SerializedProperty rtScale;
    //        public SerializedProperty outterColor;

    //    }

    //    SkyScatterSettings m_SkyScatter;

    //    public override void OnEnable()
    //    {
    //        m_SkyScatter = new SkyScatterSettings
    //        {
    //            //blurSize = FindSetting((Settings x) => x.outLine.blurSize),
    //            //rtScale = FindSetting((Settings x) => x.outLine.rtScale),
    //            //outterColor = FindSetting((Settings x) => x.outLine.outterColor),
    //        };

    //    }

    //    public override void OnInspectorGUI()
    //    {

    //        EditorGUILayout.PropertyField(m_SkyScatter.blurSize);
    //        EditorGUILayout.PropertyField(m_SkyScatter.rtScale);
    //        EditorGUILayout.PropertyField(m_SkyScatter.outterColor);

    //    }

//}

}
