using System;
using UnityEngine.Rendering;

namespace UnityEngine.PostProcessing
{
    [Serializable]
    public class OutLineModel : PostProcessingModel
    {
        [Serializable]
        public struct OutLineSettings
        {
            [Range(0f, 10f),Tooltip("Size of the outline.")]
            public float blurSize;

            [Range(0.3f, 1f), Tooltip("Sample size of outline.")]
            public float rtScale;

            public Color outterColor;

            //public Renderer[] targetsGroup;

            public static OutLineSettings defaultSettings
            {
                get
                {
                    return new OutLineSettings
                    {
                        blurSize = 2.0f,
                        rtScale = 0.7f,
                        outterColor = new Color(0.133f, 1, 0, 1),

                        //targetsGroup = null,
                    };
                }
            }
        }


        [Serializable]
        public struct Settings
        {
            public OutLineSettings outLine;


            public static Settings defaultSettings
            {
                get
                {
                    return new Settings
                    {
                        outLine = OutLineSettings.defaultSettings,
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
