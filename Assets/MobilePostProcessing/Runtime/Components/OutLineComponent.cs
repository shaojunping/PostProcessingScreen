using UnityEngine.Rendering;
namespace UnityEngine.PostProcessing
{
    public sealed class OutLineComponent : PostProcessingComponentRenderTexture<OutLineModel>
    //public sealed class OutLineComponent : PostProcessingComponentCommandBuffer<OutLineModel>
    {

        public override bool active
        {
            get
            {
                return model.enabled
                       && !context.interrupted;
            }
        }

        //public override string GetName()
        //{
        //    return "Render Solid Color Outliner";
        //}
        //public override void PopulateCommandBuffer(CommandBuffer cb)
        //{
        //    cb.ClearRenderTarget(true, true, Color.clear);
        //    var m_outterLineMat = context.materialFactory.Get("Unlit/ColorSel");
        //    if (outRen)
        //        cb.DrawRenderer(outRen, m_outterLineMat);

        //}

        //public override CameraEvent GetCameraEvent()
        //{
        //    return CameraEvent.AfterImageEffectsOpaque;
        //}

        public void Prepare(RenderTexture source, Material uberMaterial, UnityEngine.Rendering.CommandBuffer cb)
        {
            var outLine = model.settings.outLine;
            var blurMaterial = context.materialFactory.Get("Hidden/OutLine");

            blurMaterial.SetVector("_Parameter", new Vector4(outLine.blurSize * 0.5f, -outLine.blurSize * 0.5f, 0.0f, 0.0f));
            int rtW =(int) (source.width * outLine.rtScale);
            int rtH = (int)(source.height * outLine.rtScale);

            RenderTexture rt1 = RenderTexture.GetTemporary(rtW, rtH, 0, source.format);
            rt1.filterMode = FilterMode.Bilinear;

            Graphics.SetRenderTarget(rt1);

            Graphics.ExecuteCommandBuffer(cb);
            //Debug.Log("excues cb!");

            RenderTexture rt2 = context.renderTextureFactory.Get(rtW, rtH, 0, source.format);
            rt2.filterMode = FilterMode.Bilinear;
            blurMaterial.SetVector("_BlurOffsets", new Vector4(outLine.blurSize * 0.5f, -outLine.blurSize * 0.5f, 0.0f, 0.0f));
            Graphics.Blit(rt1, rt2, blurMaterial);
            RenderTexture.ReleaseTemporary(rt1);

            // Push everything to the uber material
            uberMaterial.SetTexture("_OutBlurTex", rt2);
            uberMaterial.SetColor("_OutColor",outLine.outterColor);

            uberMaterial.EnableKeyword("OUTLINE");
            //RenderTexture.ReleaseTemporary(rt2);
        }
    }
}
