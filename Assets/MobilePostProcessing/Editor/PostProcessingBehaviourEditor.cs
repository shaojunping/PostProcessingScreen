using System;
using System.Linq.Expressions;
using UnityEngine;
using UnityEngine.PostProcessing;

namespace UnityEditor.PostProcessing
{
    [CustomEditor(typeof(PostProcessingBehaviour))]
    public class PostProcessingBehaviourEditor : Editor
    {
        SerializedProperty m_Profile;
        SerializedProperty m_SunShaftTran;


        public void OnEnable()
        {
            m_Profile = FindSetting((PostProcessingBehaviour x) => x.profile);
            m_SunShaftTran = FindSetting((PostProcessingBehaviour x) => x.sunShaftTran);
        }

        public override void OnInspectorGUI()
        {
            serializedObject.Update();

            EditorGUILayout.PropertyField(m_Profile);
            EditorGUILayout.PropertyField(m_SunShaftTran);

            serializedObject.ApplyModifiedProperties();
        }

        SerializedProperty FindSetting<T, TValue>(Expression<Func<T, TValue>> expr)
        {
            return serializedObject.FindProperty(ReflectionUtils.GetFieldPath(expr));
        }
    }
}
