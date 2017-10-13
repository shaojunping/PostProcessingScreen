using System;

namespace UnityEngine.PostProcessing
{
    [Serializable]
    public class WaterEffectModel : PostProcessingModel
    {
        public enum Mode
        {
            UnderWater,
            WetLens
        }

        [Serializable]
        public class Settings
        //public struct Settings
        {
            //[Tooltip("Use the \"Classic\" mode for parametric controls. Use the \"Masked\" mode to use your own texture mask.")]
            public Mode mode;

            [Tooltip("Wet Len normal map.")]
            public Texture wetLenTex;

            [Tooltip("Distortion Maks map.")]
            public Texture distortionTex;

            //[ColorUsage(false)]
            //[Tooltip("Vignette color. Use the alpha channel for transparency.")]
            //public Color color;

            //[Tooltip("Sets the vignette center point (screen center is [0.5,0.5]).")]
            //public Vector2 center;

            [Range(0f, 1f), Tooltip("Amount of Wet Lens.")]
            public float intensity;

            [Range(0f, 3f), Tooltip("Distortion Speed of Water.")]
            public float distortionSpeed;

            //[Tooltip("Should the vignette be perfectly round or be dependent on the current aspect ratio?")]
            //public bool rounded;

            public static Settings defaultSettings
            {
                get
                {
                    return new Settings
                    {
                        mode = Mode.UnderWater,
                        //color = new Color(0f, 0f, 0f, 1f),
                        //center = new Vector2(0.5f, 0.5f),
                        intensity = 0.45f,
                        distortionSpeed = 1.0f,
                        wetLenTex = null,
                        distortionTex =null,
                        //rounded = false
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
