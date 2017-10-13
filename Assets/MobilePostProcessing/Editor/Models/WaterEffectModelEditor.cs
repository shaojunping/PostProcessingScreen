using UnityEngine;
using UnityEngine.PostProcessing;

namespace UnityEditor.PostProcessing
{
    using WaterEffectMode = WaterEffectModel.Mode;
    using Settings = WaterEffectModel.Settings;

    [PostProcessingModelEditor(typeof(WaterEffectModel))]
    public class WaterEffectModelEditor : PostProcessingModelEditor
    {
        SerializedProperty m_Mode;
        //SerializedProperty m_Color;
        //SerializedProperty m_Center;
        SerializedProperty m_Intensity;
        SerializedProperty m_distortionSpeed;
        SerializedProperty m_WetLenTex;
        SerializedProperty m_DistortionTex;
        //SerializedProperty m_Rounded;

        public override void OnEnable()
        {
            m_Mode = FindSetting((Settings x) => x.mode);
            //m_Color = FindSetting((Settings x) => x.color);
            //m_Center = FindSetting((Settings x) => x.center);
            m_WetLenTex = FindSetting((Settings x) => x.wetLenTex);
            m_Intensity = FindSetting((Settings x) => x.intensity);

            m_DistortionTex = FindSetting((Settings x) => x.distortionTex);
            m_distortionSpeed = FindSetting((Settings x) => x.distortionSpeed);

            //m_Rounded = FindSetting((Settings x) => x.rounded);
        }

        public override void OnInspectorGUI()
        {
            EditorGUILayout.PropertyField(m_Mode);
            //EditorGUILayout.PropertyField(m_Color);

            //if (m_Mode.intValue < (int)WaterEffectMode.WetLens)
            //{
                //EditorGUILayout.PropertyField(m_Center);
                EditorGUILayout.PropertyField(m_Intensity);

                //EditorGUILayout.PropertyField(m_Rounded);
            //}
            //else
            //{

                //var mask = (target as VignetteModel).settings.mask;
                var mask = (target as WaterEffectModel).settings.wetLenTex;
                // Checks import settings on the mask, offers to fix them if invalid
                if (mask != null)
                {
                    var importer = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(mask)) as TextureImporter;

                }

                EditorGUILayout.PropertyField(m_WetLenTex);

                var mask1 = (target as WaterEffectModel).settings.distortionTex;
                // Checks import settings on the mask, offers to fix them if invalid
                if (mask1 != null)
                {
                    var importer1 = AssetImporter.GetAtPath(AssetDatabase.GetAssetPath(mask1)) as TextureImporter;

                }
                EditorGUILayout.PropertyField(m_distortionSpeed);
                EditorGUILayout.PropertyField(m_DistortionTex);

            //}
        }

    }
}
