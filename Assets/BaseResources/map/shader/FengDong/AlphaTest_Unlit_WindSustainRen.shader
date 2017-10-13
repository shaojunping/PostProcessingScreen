// Upgrade NOTE: replaced '_Object2World' with 'unity_ObjectToWorld'
// Upgrade NOTE: replaced '_World2Object' with 'unity_WorldToObject'

Shader "TSHD/AlphaTest_Unlit_WindSustainRen" {
    Properties {
        _Color ("Grass tint", Color) = (1.0,1.0,1.0,1.0) 
        _MainTex ("Diffuse(RGB)", 2D) = "white" {}

        _Wind("Wind params（XZ for Direction,W for Weight Scale)",Vector) = (1,1,1,1)
        _ColliderForce ("Collider Force(Control by Script)", float) = 0.0
        _WindEdgeFlutterFreqScale("Wind Freq Scale",float) = 0.5

        _SpecColor ("Specular Color", Color) = (0.5, 0.5, 0.5, 0)
	    _Shininess ("Shininess", Range (0.01, 1)) = 0.078125
         _Cutoff("Alpha cutoff", Range(0,1)) = 0.5

         [HideInInspector]_PlayerForce("XYZ for PlayerPos,W for PlayerForce Weight",Vector) =(0,0,0,0)
         [HideInInspector]_DirForce("XYZ for Wind Direction,W for PlayerForce Weight",Vector) =(0,0,0,0)
         [HideInInspector]_ForceWeight("Force Weight",float)=0.0 //All force weight
    }
    SubShader {
        	Tags {"Queue"="AlphaTest"  "RenderType"="TransparentCutout"}
            //Cull Off
        CGPROGRAM
        //#pragma surface surf BlinnPhong alphatest:_Cutoff vertex:vert noforwardadd exclude_path:prepass 
        #pragma surface surf Lambert alphatest:_Cutoff vertex:vert noforwardadd exclude_path:prepass 
            sampler2D _MainTex; 
            float4 _Wind,_PlayerForce,_DirForce;
            float _WindEdgeFlutterFreqScale,_ForceWeight,_Shininess,_ColliderForce;
            float4 _Color;
      
            struct Input {
	            float2 uv_MainTex;
            };
            
            void vert (inout appdata_full v, out Input o) {
                UNITY_INITIALIZE_OUTPUT(Input,o);

                half4 posWorld= mul(unity_ObjectToWorld, v.vertex);
               half	windTime 	= _Time.y *_WindEdgeFlutterFreqScale*10;
                
                half3 pForce = normalize(posWorld.xyz -_PlayerForce.xyz) *_PlayerForce.w*2;     
                half3 wForce =_DirForce.xyz*_DirForce.w;

                posWorld.x += cos(windTime) *sin(posWorld.z+windTime)* (_Wind.w +_ColliderForce) * v.color.a *0.1;
                posWorld.z += sin(windTime)*cos(posWorld.z+windTime)  * (_Wind.w +_ColliderForce)* v.color.a*0.1;          

                posWorld.xz +=(pForce.xz+wForce.xz)*v.color.a*_ForceWeight;    
                
                half4 posObj =mul(unity_WorldToObject, posWorld);
				v.vertex = float4(posObj.x,posObj.y,posObj.z,v.vertex.w);
            }

            void surf (Input IN, inout SurfaceOutput o) {
	            half4  tex = tex2D(_MainTex, IN.uv_MainTex);
	            half4  c = tex * _Color;
	            o.Albedo = c.rgb;
	            o.Gloss = tex.a;
                //o.Emission = c.rgb*c.a;
                o.Alpha = tex.a * _Color.a;
                //o.Alpha = tex.a ;
	            o.Specular = _Shininess;
            }
            ENDCG
            }

   Fallback "Legacy Shaders/Transparent/Cutout/VertexLit"
   //Fallback "TSHD/AlphaTest_VertexLit"
}
