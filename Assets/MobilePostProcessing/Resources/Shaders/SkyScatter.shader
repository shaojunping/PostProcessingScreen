Shader "Hidden/SkyScatter" {
	Properties {
		_MainTex ("Base", 2D) = "" {}
		_ColorBuffer ("Color", 2D) = "" {}
		_Skybox ("Skybox", 2D) = "" {}
	}
	
	CGINCLUDE
				
	#include "UnityCG.cginc"
	
	struct v2f {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		#if UNITY_UV_STARTS_AT_TOP
		float2 uv1 : TEXCOORD1;
		#endif		
	};
		
	struct v2f_radial {
		float4 pos : SV_POSITION;
		float2 uv : TEXCOORD0;
		float2 blurVector : TEXCOORD1;
	};
		
	sampler2D _MainTex;
	sampler2D _ColorBuffer;
	sampler2D _Skybox;
	sampler2D_float _CameraDepthTexture;

	uniform half4 _SunThreshold;
		
	uniform half4 _SunColor;
	uniform half4 _BlurRadius4;
	uniform half4 _SunPosition;
	uniform half4 _MainTex_TexelSize;	
	uniform half _SampleRadius;
	half4 _MainTex_ST;
	half4 _ColorBuffer_ST;
	half4 _Skybox_ST;
	half4 _CameraDepthTexture_ST;


	#define SAMPLES_FLOAT 6.0f
	#define SAMPLES_INT 6
			
	v2f vert( appdata_img v ) {
		v2f o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		o.uv = v.texcoord.xy;
		
		#if UNITY_UV_STARTS_AT_TOP
		o.uv1 = v.texcoord.xy;
		if (_MainTex_TexelSize.y < 0)
			o.uv1.y = 1-o.uv1.y;
		#endif				
		
		return o;
	}
		
	half4 fragScreen(v2f i) : SV_Target { 
		half4 colorA = tex2D (_MainTex, UnityStereoScreenSpaceUVAdjust(i.uv.xy, _MainTex_ST));
		#if UNITY_UV_STARTS_AT_TOP
		half4 colorB = tex2D (_ColorBuffer, UnityStereoScreenSpaceUVAdjust(i.uv1.xy, _ColorBuffer_ST));
		#else
		half4 colorB = tex2D (_ColorBuffer, UnityStereoScreenSpaceUVAdjust(i.uv.xy, _ColorBuffer_ST));
		#endif
		half4 depthMask = saturate (colorB * _SunColor);	
		return 1.0f - (1.0f-colorA) * (1.0f-depthMask);	
	}

	
	v2f_radial vert_radial( appdata_img v ) {
		v2f_radial o;
		o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
		
		o.uv.xy =  v.texcoord.xy;
		//o.blurVector = (_SunPosition.xy - v.texcoord.xy) * _BlurRadius4.xy;	
		o.blurVector = _SunPosition.xy - v.texcoord.xy;	
		o.blurVector *=_SampleRadius*half2(1.6,1);
		return o; 
	}
	
	half4 frag_radial(v2f_radial i) : SV_Target 
	{	
		half4 color = half4(0,0,0,0);
		//for(int j = 0; j < SAMPLES_INT; j++)   
		//{	
		//	half4 tmpColor = tex2D(_MainTex, UnityStereoScreenSpaceUVAdjust(i.uv.xy, _MainTex_ST));
		//	color += tmpColor;
		//	i.uv.xy += i.blurVector; 	
		//}
		//return color / SAMPLES_FLOAT;
		half2 oPos =UnityStereoScreenSpaceUVAdjust(i.uv.xy, _MainTex_ST);
		half2 sunDir_2 =i.blurVector;
		color = tex2D (_MainTex, oPos).x;
		color = (color + (tex2D (_MainTex, (oPos + sunDir_2)).x * 0.875));
		color = (color + (tex2D (_MainTex, (oPos + (sunDir_2 * 2.0))).x * 0.75));
		color = (color + (tex2D (_MainTex, (oPos + (sunDir_2 * 3.0))).x * 0.625));
		color = (color + (tex2D (_MainTex, (oPos + (sunDir_2 * 4.0))).x * 0.5));
		color = (color + (tex2D (_MainTex, (oPos + (sunDir_2 * 5.0))).x * 0.375));
		color = (color + (tex2D (_MainTex, (oPos + (sunDir_2 * 6.0))).x * 0.25));
		color = (color + (tex2D (_MainTex, (oPos + (sunDir_2 * 7.0))).x * 0.125));
		color =color / 4.0;
		return color;
	}	
	
	half TransformColor (half4 skyboxValue) {
		return dot(max(skyboxValue.rgb - _SunThreshold.rgb, half3(0,0,0)), half3(1,1,1)); // threshold and convert to greyscale
	}

	half4 frag_nodepth (v2f i) : SV_Target {
		#if UNITY_UV_STARTS_AT_TOP
		float4 sky = (tex2D (_Skybox, UnityStereoScreenSpaceUVAdjust(i.uv1.xy, _Skybox_ST)));
		#else
		float4 sky = (tex2D (_Skybox, UnityStereoScreenSpaceUVAdjust(i.uv.xy, _Skybox_ST)));
		#endif
		
		float4 tex = (tex2D (_MainTex, UnityStereoScreenSpaceUVAdjust(i.uv.xy, _MainTex_ST)));
		
		// consider maximum radius
		#if UNITY_UV_STARTS_AT_TOP
		half2 vec = _SunPosition.xy - i.uv1.xy;
		#else
		half2 vec = _SunPosition.xy - i.uv.xy;		
		#endif
		half dist = saturate (_SunPosition.w - length (vec));			
		
		half4 outColor = 0;		
		
		// find unoccluded sky pixels
		// consider pixel values that differ significantly between framebuffer and sky-only buffer as occluded
		//if (Luminance ( abs(sky.rgb - tex.rgb)) < 0.2)
		//	outColor = TransformColor (sky) * dist;
		outColor =(1-tex.a) * dist;
		
		return outColor;
	}	

	

	ENDCG
	
Subshader {
 //0 
 Pass {
	  ZTest Always Cull Off ZWrite Off

      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment fragScreen
      
      ENDCG
  }
   //1
 Pass {
	  ZTest Always Cull Off ZWrite Off

      CGPROGRAM
      
      #pragma vertex vert_radial
      #pragma fragment frag_radial
      
      ENDCG
  }
       //2
  Pass {
	  ZTest Always Cull Off ZWrite Off

      CGPROGRAM
      
      #pragma vertex vert
      #pragma fragment frag_nodepth
      
      ENDCG
  } 


}


Fallback off
	
} // shader
