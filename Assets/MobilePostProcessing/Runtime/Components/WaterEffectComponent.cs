namespace UnityEngine.PostProcessing
{
    public sealed class WaterEffectComponent : PostProcessingComponentRenderTexture<WaterEffectModel>
    {
        static class Uniforms
        {
            internal static readonly int _WaterEffect_WetLenTex = Shader.PropertyToID("_WetLenNorTex");
            internal static readonly int _WaterEffect_DistortionTex = Shader.PropertyToID("_DistortionTexture");
            internal static readonly int _WaterEffect_Refraction = Shader.PropertyToID("_Refraction");
            internal static readonly int _WaterEffect_Speed = Shader.PropertyToID("_DistortionSpeed");
        }

        public override bool active
        {
            get
            {
                return model.enabled
                       && !context.interrupted;
            }
        }

        public override void Prepare(Material uberMaterial)
        {
            var settings = model.settings;

            if(settings.mode == WaterEffectModel.Mode.WetLens)
                    uberMaterial.EnableKeyword("WATER_WETLENS");
            else
                if(settings.mode == WaterEffectModel.Mode.UnderWater)
                    uberMaterial.EnableKeyword("WATER_UNDER");
            uberMaterial.SetTexture(Uniforms._WaterEffect_WetLenTex, settings.wetLenTex);
            uberMaterial.SetFloat(Uniforms._WaterEffect_Refraction, settings.intensity);
            uberMaterial.SetTexture(Uniforms._WaterEffect_DistortionTex, settings.distortionTex);
            uberMaterial.SetFloat(Uniforms._WaterEffect_Speed, settings.distortionSpeed);

        }
    }
}
