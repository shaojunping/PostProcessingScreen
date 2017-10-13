Shader "TSHD/AlphaTest_VertexLit" {
Properties {
	_Color ("Main Color", Color) = (1,1,1,1)
	_MainTex ("Base (RGB)", 2D) = "white" {}
	_AlphaTex ("Alpha Texture (R)", 2D) = "white" {}
	_Cutoff ("Alpha cutoff", Range(0,1)) = 0.5
}

SubShader {
	Tags {"Queue"="AlphaTest" "IgnoreProjector"="True" "RenderType"="TransparentCutout"}
	LOD 100
	
	// Non-lightmapped
	Pass {
		Tags { 
			"LightMode" = "Vertex"
			 }
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fog
		#include "UnityCG.cginc"
		#include "Lighting.cginc"


		uniform fixed4 _Color;
		uniform fixed _Cutoff;
		uniform sampler2D _AlphaTex;uniform float4 _AlphaTex_ST;
		uniform sampler2D _MainTex;uniform float4 _MainTex_ST;

		struct v2f { 
			float4 pos :SV_POSITION;
			half2  uv : TEXCOORD0;
			UNITY_FOG_COORDS(1)
		};

		v2f vert(appdata_base v)
		{
			v2f o;
			o.pos =mul(UNITY_MATRIX_MVP,v.vertex);
			o.uv =TRANSFORM_TEX(v.texcoord,_MainTex);
			UNITY_TRANSFER_FOG(o,o.pos);
			return o;
		}

		fixed4 frag(v2f i) :COLOR
		{
			fixed4 c =_Color* tex2D(_MainTex,i.uv);
			fixed4 texcol = tex2D(_AlphaTex, i.uv);
			clip( texcol.r - _Cutoff );
			UNITY_APPLY_FOG(i.fogCoord, c);
			return c;
		}
		ENDCG
	}
		
	
	// Lightmapped, encoded as dLDR
	Pass {
		Tags { "LightMode" = "VertexLM" }
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fog
		#include "UnityCG.cginc"
		#include "Lighting.cginc"

		struct appdata_t{
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
		};

		struct v2f { 
			float4 pos :SV_POSITION;
			half2  uv : TEXCOORD0;
			half2  lmuv : TEXCOORD1;
			UNITY_FOG_COORDS(2)
		};

		uniform fixed4 _Color;
		uniform fixed _Cutoff;
		uniform sampler2D _AlphaTex;uniform float4 _AlphaTex_ST;
		uniform sampler2D _MainTex;uniform float4 _MainTex_ST;

		v2f vert(appdata_t v)
		{
			v2f o;
			o.pos =mul(UNITY_MATRIX_MVP,v.vertex);
			o.uv =TRANSFORM_TEX(v.texcoord,_MainTex);
			o.lmuv = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			UNITY_TRANSFER_FOG(o,o.pos);
			return o;
		}

		fixed4 frag(v2f i) :COLOR
		{
			fixed4 c =_Color* tex2D(_MainTex,i.uv);
			fixed4 texcol = tex2D(_AlphaTex, i.uv);
			clip( texcol.r - _Cutoff );
			fixed4 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmuv);
			c.rgb *=DecodeLightmap(lm);
			UNITY_APPLY_FOG(i.fogCoord, c);
			return c;
		}
		ENDCG

	}
	
	// Lightmapped, encoded as RGBM
	Pass {
		Tags { "LightMode" = "VertexLMRGBM" }
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_fog
		#include "UnityCG.cginc"
		#include "Lighting.cginc"

		struct appdata_t{
			float4 vertex : POSITION;
			float2 texcoord : TEXCOORD0;
			float2 texcoord1 : TEXCOORD1;
		};

		struct v2f { 
			float4 pos :SV_POSITION;
			half2  uv : TEXCOORD0;
			half2  lmuv : TEXCOORD1;
			UNITY_FOG_COORDS(2)
		};

		uniform fixed4 _Color;
		uniform fixed _Cutoff;
		uniform sampler2D _AlphaTex;uniform float4 _AlphaTex_ST;
		uniform sampler2D _MainTex;uniform float4 _MainTex_ST;

		v2f vert(appdata_t v)
		{
			v2f o;
			o.pos =mul(UNITY_MATRIX_MVP,v.vertex);
			o.uv =TRANSFORM_TEX(v.texcoord,_MainTex);
			o.lmuv = v.texcoord1.xy * unity_LightmapST.xy + unity_LightmapST.zw;
			UNITY_TRANSFER_FOG(o,o.pos);
			return o;
		}

		fixed4 frag(v2f i) :COLOR
		{
			fixed4 c =_Color* tex2D(_MainTex,i.uv);
			fixed4 texcol = tex2D(_AlphaTex, i.uv);
			clip( texcol.r - _Cutoff );
			fixed4 lm = UNITY_SAMPLE_TEX2D(unity_Lightmap,i.lmuv);
			c.rgb *=DecodeLightmap(lm);
			UNITY_APPLY_FOG(i.fogCoord, c);
			return c;
		}
		ENDCG
	}
	
	// Pass to render object as a shadow caster
	Pass {
		Name "Caster"
		Tags { "LightMode" = "ShadowCaster" }
		
		CGPROGRAM
		#pragma vertex vert
		#pragma fragment frag
		#pragma multi_compile_shadowcaster
		#include "UnityCG.cginc"

		struct v2f { 
			V2F_SHADOW_CASTER;
			float2  uv : TEXCOORD1;
		};

		uniform float4 _AlphaTex_ST;

		v2f vert( appdata_base v )
		{
			v2f o;
			TRANSFER_SHADOW_CASTER_NORMALOFFSET(o)
			o.uv = TRANSFORM_TEX(v.texcoord, _AlphaTex);
			return o;
		}

		uniform sampler2D _AlphaTex;
		uniform fixed _Cutoff;
		uniform fixed4 _Color;

		float4 frag( v2f i ) : SV_Target
		{
			fixed4 texcol = tex2D(_AlphaTex, i.uv );
			clip( texcol.r*_Color.a - _Cutoff );
			
			SHADOW_CASTER_FRAGMENT(i)
		}
		ENDCG

	}
	
}

}