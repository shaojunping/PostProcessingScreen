Shader "Hidden/Post FX/Uber Shader"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _AutoExposure ("", 2D) = "" {}
        _BloomTex ("", 2D) = "" {}
        _Bloom_DirtTex ("", 2D) = "" {}
        //_GrainTex ("", 2D) = "" {}
		_OutBlurTex ("", 2D) = "" {}
        _LogLut ("", 2D) = "" {}
        _UserLut ("", 2D) = "" {}
        _Vignette_Mask ("", 2D) = "" {}
        _ChromaticAberration_Spectrum ("", 2D) = "" {}
		_WetLenNorTex ("WetLen Normal", 2D) = "bump" {}
		_DistortionTexture ("_Distortion Texture", 2D) = "white" {}
		_OutColor("Out Color", Color) = (1,1,1,1)
		_SkyScatterTex("", 2D) = "" {}
        //_DitheringTex ("", 2D) = "" {}
    }

    CGINCLUDE

        #pragma target 3.0

        #pragma multi_compile __ UNITY_COLORSPACE_GAMMA
        #pragma multi_compile __ CHROMATIC_ABERRATION
        //#pragma multi_compile __ DEPTH_OF_FIELD DEPTH_OF_FIELD_COC_VIEW
		#pragma multi_compile __ DEPTH_OF_FIELD 
        //#pragma multi_compile __ BLOOM BLOOM_LENS_DIRT
		#pragma multi_compile __ BLOOM 
        #pragma multi_compile __ COLOR_GRADING COLOR_GRADING_LOG_VIEW
        #pragma multi_compile __ USER_LUT
        //#pragma multi_compile __ GRAIN
        //#pragma multi_compile __ VIGNETTE_CLASSIC VIGNETTE_MASKED
		 //#pragma multi_compile __ VIGNETTE_MASKED
		 #pragma multi_compile __ WATER_WETLENS WATER_UNDER
		 #pragma multi_compile __ OUTLINE
		 #pragma multi_compile __ SKYSCATTER
        //#pragma multi_compile __ DITHERING

        #include "UnityCG.cginc"
        #include "Bloom.cginc"
        #include "ColorGrading.cginc"
        //#include "UberSecondPass.cginc"

        // Auto exposure / eye adaptation
        sampler2D _AutoExposure;

		//Wet len 
		sampler2D _WetLenNorTex,_DistortionTexture;
		float _Refraction,_DistortionSpeed;

        // Chromatic aberration
        half _ChromaticAberration_Amount;
        sampler2D _ChromaticAberration_Spectrum;

        // Depth of field
        sampler2D_float _CameraDepthTexture;
        sampler2D _DepthOfFieldTex;
        sampler2D _DepthOfFieldCoCTex;
        float4 _DepthOfFieldTex_TexelSize;
        float3 _DepthOfFieldParams; // x: distance, y: f^2 / (N * (S1 - f) * film_width * 2), z: max coc

        // Bloom
        sampler2D _BloomTex;
        float4 _BloomTex_TexelSize;
        half2 _Bloom_Settings; // x: sampleScale, y: bloom.intensity

        sampler2D _Bloom_DirtTex;
        half _Bloom_DirtIntensity;

        // Color grading & tonemapping
        sampler2D _LogLut;
        half3 _LogLut_Params; // x: 1 / lut_width, y: 1 / lut_height, z: lut_height - 1
        half _ExposureEV; // EV (exp2)

        // User lut
        sampler2D _UserLut;
        half4 _UserLut_Params; // @see _LogLut_Params

		//OutLine
		sampler2D _OutBlurTex;
		fixed4 _OutColor;

		//Sky Scatter
		sampler2D _SkyScatterTex;
		float4 _SkyScatterTex_TexelSize;
		half4 _SunColor;

        // Vignette
        //half3 _Vignette_Color;
        //half2 _Vignette_Center; // UV space
        //half4 _Vignette_Settings; // x: intensity, y: smoothness, z: roundness, w: rounded
        //sampler2D _Vignette_Mask;
        //half _Vignette_Opacity; // [0;1]

        struct VaryingsFlipped
        {
            float4 pos : SV_POSITION;
            float2 uv : TEXCOORD0;
            float2 uvSPR : TEXCOORD1; // Single Pass Stereo UVs
            float2 uvFlipped : TEXCOORD2; // Flipped UVs (DX/MSAA/Forward)
            float2 uvFlippedSPR : TEXCOORD3; // Single Pass Stereo flipped UVs
			half4 rotationUV : TEXCOORD4; //XY:rotationUV,ZW: computed value
        };

        VaryingsFlipped VertUber(AttributesDefault v)
        {
            VaryingsFlipped o;
            o.pos = UnityObjectToClipPos(v.vertex);
            o.uv = v.texcoord.xy;
            o.uvSPR = UnityStereoScreenSpaceUVAdjust(v.texcoord.xy, _MainTex_ST);
            o.uvFlipped = v.texcoord.xy;

        #if UNITY_UV_STARTS_AT_TOP
            if (_MainTex_TexelSize.y < 0.0)
                o.uvFlipped.y = 1.0 - o.uvFlipped.y;
        #endif

            o.uvFlippedSPR = UnityStereoScreenSpaceUVAdjust(o.uvFlipped, _MainTex_ST);

			o.rotationUV =float4(0,0,0,0);

			#if WATER_UNDER
			half rotation_cos = cos(_DistortionSpeed*_Time.g);
			half rotation_sin = sin(_DistortionSpeed*_Time.g);
			half2 rotationUV = (mul(o.uvSPR - half2(0.5,0.5),half2x2(rotation_cos, -rotation_sin, rotation_sin, rotation_cos)) +half2(0.5,0.5));
			o.rotationUV.xy =UnityStereoScreenSpaceUVAdjust(rotationUV, _MainTex_ST);

			half2 componentMask1 = abs(o.uvSPR  *2 -1);
			o.rotationUV.zw =half2(1,1)*(1.0 - pow(max(componentMask1.r,componentMask1.g),2.0))*_Refraction*0.1;
			#endif

            return o;
        }

        half4 FragUber(VaryingsFlipped i) : SV_Target
        {
            float2 uv = i.uv;
            half autoExposure = tex2D(_AutoExposure, uv).r;

            half3 color = (0.0).xxx;
            #if DEPTH_OF_FIELD && CHROMATIC_ABERRATION
            half4 dof = (0.0).xxxx;
            half ffa = 0.0; // far field alpha
            #endif

			half2 uvWaterOffset =half2(0,0);
            //
            // HDR effects
            // ---------------------------------------------------------

            // Chromatic Aberration
            // Inspired by the method described in "Rendering Inside" [Playdead 2016]
            // https://twitter.com/pixelmager/status/717019757766123520
            #if CHROMATIC_ABERRATION
            {
                float2 coords = 2.0 * uv - 1.0;
                float2 end = uv - coords * dot(coords, coords) * _ChromaticAberration_Amount;

                float2 diff = end - uv;
				//int samples = clamp(int(length(_MainTex_TexelSize.zw * diff / 2.0)), 3, 16);
                int samples = clamp(int(length(_MainTex_TexelSize.zw * diff / 2.0)), 3, 8);
                float2 delta = diff / samples;
                float2 pos = uv;
                half3 sum = (0.0).xxx, filterSum = (0.0).xxx;

                #if DEPTH_OF_FIELD
					float2 dofDelta = delta;
					float2 dofPos = pos;
					if (_MainTex_TexelSize.y < 0.0)
					{
						dofDelta.y = -dofDelta.y;
						dofPos.y = 1.0 - dofPos.y;
					}
					half4 dofSum = (0.0).xxxx;
					half ffaSum = 0.0;
                #endif

                for (int i = 0; i < samples; i++)
                {
                    half t = (i + 0.5) / samples;
                    half3 s = tex2Dlod(_MainTex, float4(UnityStereoScreenSpaceUVAdjust(pos, _MainTex_ST), 0, 0)).rgb;
                    half3 filter = tex2Dlod(_ChromaticAberration_Spectrum, float4(t, 0, 0, 0)).rgb;

                    sum += s * filter;
                    filterSum += filter;
                    pos += delta;

                    #if DEPTH_OF_FIELD
						float4 uvDof = float4(UnityStereoScreenSpaceUVAdjust(dofPos, _MainTex_ST), 0, 0);
						half4 sdof = tex2Dlod(_DepthOfFieldTex, uvDof).rgba;
						half scoc = tex2Dlod(_DepthOfFieldCoCTex, uvDof).r;
						scoc = (scoc - 0.5) * 2 * _DepthOfFieldParams.z;
						dofSum += sdof * half4(filter, 1);
						ffaSum += smoothstep(_MainTex_TexelSize.y * 2, _MainTex_TexelSize.y * 4, scoc);
						dofPos += dofDelta;
                    #endif
                }

                color = sum / filterSum;
                #if DEPTH_OF_FIELD
					dof = dofSum / half4(filterSum, samples);
					ffa = ffaSum / samples;
                #endif
            }
            #else
            {
				#if WATER_WETLENS
				{
					half4 wetTex =tex2D(_WetLenNorTex,i.uvFlipped);
					half  wetOffset = UnpackNormal(wetTex).r *_Refraction *wetTex.a;
					half2 sceneUVs = i.uvSPR.xy+ half2(wetOffset,wetOffset);
					color = tex2D(_MainTex, sceneUVs).rgb;

				}
				#elif WATER_UNDER
					half3 DistortionTex = tex2D(_DistortionTexture,i.rotationUV.xy);
					half2 componentMask = abs(i.uvSPR *2 -1);
					uvWaterOffset = half2(DistortionTex.r,DistortionTex.g)*(1.0 - pow(max(componentMask.r,componentMask.g),2.0))*_Refraction*0.1;
					half2 sceneUVs = i.uvSPR.xy +uvWaterOffset ;

					color = tex2D(_MainTex, sceneUVs);

				#else
                color = tex2D(_MainTex, i.uvSPR).rgb;
				#endif
            }
            #endif

            // Apply auto exposure if any
            color *= autoExposure;

            // Gamma space... Gah.
            #if UNITY_COLORSPACE_GAMMA
            {
                color = GammaToLinearSpace(color);
            }
            #endif

			#if DEPTH_OF_FIELD
            {
                #if !CHROMATIC_ABERRATION
					half4 dof = tex2D(_DepthOfFieldTex, i.uvFlippedSPR);
					half coc = tex2D(_DepthOfFieldCoCTex, i.uvFlippedSPR);
					coc = (coc - 0.5) * 2 * _DepthOfFieldParams.z;
					// Convert CoC to far field alpha value.
					float ffa = smoothstep(_MainTex_TexelSize.y * 2, _MainTex_TexelSize.y * 4, coc);
                #endif
                // lerp(lerp(color, dof, ffa), dof, dof.a)
                color = lerp(color, dof.rgb * autoExposure, ffa + dof.a - ffa * dof.a);
            }
            #endif

            // HDR Bloom
            //#if BLOOM || BLOOM_LENS_DIRT
			 #if BLOOM 
            {
                half3 bloom = UpsampleFilter(_BloomTex, i.uvFlippedSPR, uvWaterOffset,_BloomTex_TexelSize.xy, _Bloom_Settings.x) * _Bloom_Settings.y;
                color += bloom;

     //           #if BLOOM_LENS_DIRT
     //           {
     //               half3 dirt = tex2D(_Bloom_DirtTex, i.uvFlipped).rgb * _Bloom_DirtIntensity;
     //               //color += bloom * dirt;
					//color +=  dirt;
     //           }
     //           #endif
            }
            #endif
			//Sky scatter
			#if SKYSCATTER 
            {
				half3 scatter = tex2D(_SkyScatterTex, i.uvFlipped).rgb * _SunColor;
				color += scatter;
			}
			#endif

            // Procedural vignette
            //#if VIGNETTE_CLASSIC
            //{
            //    half2 d = abs(uv - _Vignette_Center) * _Vignette_Settings.x;
            //    d.x *= lerp(1.0, _ScreenParams.x / _ScreenParams.y, _Vignette_Settings.w);
            //    d = pow(d, _Vignette_Settings.z); // Roundness
            //    half vfactor = pow(saturate(1.0 - dot(d, d)), _Vignette_Settings.y);
            //    color *= lerp(_Vignette_Color, (1.0).xxx, vfactor);
            //}

            // Masked vignette
            //#elif VIGNETTE_MASKED

			//#if VIGNETTE_MASKED
   //         {
   //             half vfactor = tex2D(_Vignette_Mask, uv).a;
   //             half3 new_color = color * lerp(_Vignette_Color, (1.0).xxx, vfactor);
   //             color = lerp(color, new_color, _Vignette_Opacity);
   //         }
   //         #endif

            // HDR color grading & tonemapping
            #if COLOR_GRADING_LOG_VIEW
            {
                color *= _ExposureEV;
                color = saturate(LinearToLogC(color));
            }
            #elif COLOR_GRADING
            {
                color *= _ExposureEV; // Exposure is in ev units (or 'stops')

                half3 colorLogC = saturate(LinearToLogC(color));
                color = ApplyLut2d(_LogLut, colorLogC, _LogLut_Params);
            }
            #endif

            //
            // All the following effects happen in LDR
            // ---------------------------------------------------------

            color = saturate(color);

            // Back to gamma space if needed
            #if UNITY_COLORSPACE_GAMMA
            {
                color = LinearToGammaSpace(color);
            }
            #endif

            // LDR user lut
            #if USER_LUT
            {
                color = saturate(color);
                half3 colorGraded;

                #if !UNITY_COLORSPACE_GAMMA
                {
                    colorGraded = ApplyLut2d(_UserLut, LinearToGammaSpace(color), _UserLut_Params.xyz);
                    colorGraded = GammaToLinearSpace(colorGraded);
                }
                #else
                {
                    colorGraded = ApplyLut2d(_UserLut, color, _UserLut_Params.xyz);
                }
                #endif

                color = lerp(color, colorGraded, _UserLut_Params.w);
            }
            #endif

			#if OUTLINE
				fixed4 blurTex =tex2D( _OutBlurTex, i.uvFlipped+uvWaterOffset );

				fixed oneMinueA =1-blurTex.a;
				color +=blurTex.r*oneMinueA*_OutColor.rgb;
			#endif

            //color = UberSecondPass(color, uv);

            // Done !
            return half4(color, 1.0);
        }

    ENDCG

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        // (0)
        Pass
        {
            CGPROGRAM

                #pragma vertex VertUber
                #pragma fragment FragUber

            ENDCG
        }
    }
}
