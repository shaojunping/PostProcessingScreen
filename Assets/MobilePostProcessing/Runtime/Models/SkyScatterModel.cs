using System;

namespace UnityEngine.PostProcessing
{
    [Serializable]
    public class SkyScatterModel : PostProcessingModel
    {
        public enum SunShaftsResolution
        {
            Low = 0,
            Normal = 1,
            High = 2,
        }

        [Serializable]
        public class Settings
        //public struct Settings
        {
            //[Tooltip("Use the \"Classic\" mode for parametric controls. Use the \"Masked\" mode to use your own texture mask.")]
            [Tooltip("Sun Shafts Resolution.")]
            public SunShaftsResolution resolution;

            //[Tooltip("Sun Transform.")]
            //public Transform sunTransform;

            [Tooltip("Sun color.")]
            public Color sunColor;


            [Range(0.1f, 2f), Tooltip("Amount of Sun Shafts.")]
            public float sunShaftIntensity;

            [Range(0.1f, 1f), Tooltip("Screen size of Shafts.")]
            public float maxRadius;

            [Range(0.01f, 0.04f), Tooltip("Sample Radius.")]
            public float sampleRadius;

            public static Settings defaultSettings
            {
                get
                {
                    return new Settings
                    {
                        resolution = SunShaftsResolution.Low,
                        //sunTransform =null,
                        sunColor = new Color(0f, 0f, 0f, 1f),
                        //center = new Vector2(0.5f, 0.5f),
                        sunShaftIntensity = 0.8f,
                        maxRadius = 0.8f,
                        sampleRadius =0.025f,

                    };
                }
            }
        }

        [SerializeField]
        Settings m_Settings = Settings.defaultSettings;
        public Settings settings
        {
            get { return m_Settings; }
            set { m_Settings = value; }
        }

        public override void Reset()
        {
            m_Settings = Settings.defaultSettings;
        }
    }
}
