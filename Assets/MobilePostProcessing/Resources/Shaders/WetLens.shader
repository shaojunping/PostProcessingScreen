// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'

Shader "Hidden/Post FX/WetLens" {
    Properties {
		_MainTex("Base (RGB)", 2D) = "white" {}
        _Normal ("Normal", 2D) = "bump" {}
        _MainColor ("Main Color", Color) = (1,1,1,1)
		_Refraction("Refraction", Range(0, 1)) = 1
    }
    SubShader {
        Pass {
            Blend SrcAlpha OneMinusSrcAlpha
			ZTest Always Cull Off ZWrite Off
            
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            #include "UnityCG.cginc"
            #pragma target 3.0
			uniform sampler2D _MainTex;
			uniform half4 _MainTex_TexelSize;
            uniform float _Refraction;
            uniform float4 _MainColor;
            uniform sampler2D _Normal; 
			uniform float4 _Normal_ST;
            struct VertexInput {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float2 texcoord0 : TEXCOORD0;
            };
            struct VertexOutput {
                float4 pos : SV_POSITION;
                float2 uv0 : TEXCOORD0;
                float4 posWorld : TEXCOORD1;
                float4 screenPos : TEXCOORD5;
            };
            VertexOutput vert (VertexInput v) {
                VertexOutput o = (VertexOutput)0;
                o.uv0 = v.texcoord0;
                o.posWorld = mul(unity_ObjectToWorld, v.vertex);
                o.pos = mul(UNITY_MATRIX_MVP, v.vertex );

				o.screenPos = o.pos;
				#if UNITY_UV_STARTS_AT_TOP
					if (_MainTex_TexelSize.y < 0.0)
						o.screenPos.y *= -1;
				#endif
                return o;
            }
            float4 frag(VertexOutput i, float facing : VFACE) : COLOR {
                float isFrontFace = ( facing >= 0 ? 1 : 0 );
                float faceSign = ( facing >= 0 ? 1 : -1 );
                i.screenPos = float4( i.screenPos.xy / i.screenPos.w, 0, 0 );
                float3 _Normal_var = UnpackNormal(tex2D(_Normal,TRANSFORM_TEX(i.uv0, _Normal)));
                float refractUV = (_Normal_var.rgb.r*_Refraction);
                float2 sceneUVs = i.screenPos.xy*0.5+0.5 + float2(refractUV,refractUV);
				float4 sceneColor = tex2D(_MainTex, sceneUVs);
                
				return sceneColor;
            }
            ENDCG
        }
    }
    //FallBack "Diffuse"
}
