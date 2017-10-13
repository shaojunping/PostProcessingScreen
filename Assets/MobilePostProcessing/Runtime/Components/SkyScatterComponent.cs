namespace UnityEngine.PostProcessing
{
    public sealed class SkyScatterComponent : PostProcessingComponentRenderTexture<SkyScatterModel>
    {
        static class Uniforms
        {
            internal static readonly int _SkyScatter_SunPosition = Shader.PropertyToID("_SunPosition");
            internal static readonly int _SkyScatte_SampleRadius = Shader.PropertyToID("_SampleRadius");
            internal static readonly int _SkyScatter_SunColor = Shader.PropertyToID("_SunColor");
            internal static readonly int _SkyScatterTex = Shader.PropertyToID("_SkyScatterTex");
        }

        public override bool active
        {
            get
            {
                return model.enabled
                       && !context.interrupted;
            }
        }

        public  void Prepare(RenderTexture source, Material uberMaterial,Camera cam,Transform objTran)
        {
            var settings = model.settings;
            uberMaterial.EnableKeyword("SKYSCATTER");
            var material = context.materialFactory.Get("Hidden/SkyScatter");

            int divider = 8;
            if (settings.resolution == SkyScatterModel.SunShaftsResolution.Normal)
                divider = 4;
            else if (settings.resolution == SkyScatterModel.SunShaftsResolution.High)
                divider = 2;

            var tw = context.width / divider;
            var th = context.height / divider;

            var useRGBM = Application.isMobilePlatform;
            var rtFormat = useRGBM
                ? RenderTextureFormat.Default
                : RenderTextureFormat.DefaultHDR;

            Vector3 v = Vector3.one * 0.5f;
            if (objTran)
                v = cam.WorldToViewportPoint(objTran.position);
            else
                v = new Vector3(0.5f, 0.8f, 0.0f);

            material.SetVector("_SunPosition", new Vector4(v.x, v.y, v.z, settings.maxRadius));
            material.SetFloat("_SampleRadius", settings.sampleRadius);

            RenderTexture lrColorB;
            //Use in Uber mat
            RenderTexture ScatterRT = context.renderTextureFactory.Get(tw, th, 0);
            ScatterRT.filterMode = FilterMode.Bilinear;
            Graphics.Blit(source, ScatterRT, material, 2);

            lrColorB = RenderTexture.GetTemporary(tw, th, 0);
            lrColorB.filterMode = FilterMode.Bilinear;
            Graphics.Blit(ScatterRT, lrColorB, material, 1);

            Graphics.Blit(lrColorB, ScatterRT, material, 1);
            RenderTexture.ReleaseTemporary(lrColorB);

            if (v.z >= 0.0f)
                uberMaterial.SetVector(Uniforms._SkyScatter_SunColor, new Vector4(settings.sunColor.r, settings.sunColor.g, settings.sunColor.b, settings.sunColor.a) * settings.sunShaftIntensity);
            else
                uberMaterial.SetVector(Uniforms._SkyScatter_SunColor, Vector4.zero); // no backprojection !
            uberMaterial.SetFloat(Uniforms._SkyScatte_SampleRadius, settings.sampleRadius);
            //uberMaterial.SetColor(Uniforms._SkyScatter_SunColor, settings.sunColor);
            uberMaterial.SetTexture(Uniforms._SkyScatterTex, ScatterRT);

        }
    }
}
