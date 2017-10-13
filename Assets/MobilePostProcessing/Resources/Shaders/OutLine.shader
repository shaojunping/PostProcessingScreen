Shader "Hidden/OutLine" {

Properties {
	_MainTex ("", 2D) = "white" {}
}

Category {
	ZTest Always Cull Off ZWrite Off 

	Subshader {
		//ColorMask RA
		Pass {
			CGPROGRAM
			
				#pragma vertex vert
				#pragma fragment frag
				#pragma fragmentoption ARB_precision_hint_fastest

				#include "UnityCG.cginc"

				struct v2f {
					float4 pos : POSITION;
					half2 uv : TEXCOORD0;
					half2 taps[4] : TEXCOORD1;
				};

				float4 _MainTex_TexelSize;
				float4 _BlurOffsets;

				v2f vert (appdata_img v)
				{
					v2f o; 
					o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
					//o.uv = v.texcoord - _BlurOffsets.xy * _MainTex_TexelSize.xy; // hack, see BlurEffect.cs for the reason for this. let's make a new blur effect soon
					o.uv =v.texcoord;
					o.taps[0] = o.uv + _MainTex_TexelSize * _BlurOffsets.xy;
					o.taps[1] = o.uv - _MainTex_TexelSize * _BlurOffsets.xy;
					o.taps[2] = o.uv + _MainTex_TexelSize * _BlurOffsets.xy * half2(1,-1);
					o.taps[3] = o.uv - _MainTex_TexelSize * _BlurOffsets.xy * half2(1,-1);
					return o;
				}
				
				sampler2D _MainTex;
				fixed4 _Color;

				fixed4 frag( v2f i ) : COLOR
				{
					half4 color = tex2D(_MainTex, i.taps[0]);
					color.r += tex2D(_MainTex, i.taps[1]).r;
					color.r += tex2D(_MainTex, i.taps[2]).r;
					color.r+= tex2D(_MainTex, i.taps[3]).r; 
					color.a =tex2D(_MainTex, i.uv).a;
					return color;
				}
			ENDCG
		}
		
	}

	//Subshader {
	//	Pass {
	//		SetTexture [_MainTex] {constantColor [_Color] combine texture * constant alpha}
	//		SetTexture [_MainTex] {constantColor [_Color] combine texture * constant + previous}
	//		SetTexture [_MainTex] {constantColor [_Color] combine texture * constant + previous}
	//		SetTexture [_MainTex] {constantColor [_Color] combine texture * constant + previous}		
	//	}

	//}
}

Fallback off

}
