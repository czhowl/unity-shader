Shader "Unlit/Disolve"
{
	Properties
	{
		_MainTex ("Texture", 2D) = "white" {}
		_DisolveTex ("Disolve Texture", 2D) = "white" {}
		_DisolveY("Current Y of the disolve effect", Float) = 0
		_DisolveThresh("Size of the effect", Range (0.0, 1.0)) = 0.5
		_StartingY("Starting point of the disolve effect", Float) = -10

	}
	SubShader
	{
		Tags { "RenderType"="Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"

			struct appdata
			{
				float4 vertex : POSITION;
				float2 uv : TEXCOORD0;
			};

			struct v2f
			{
				float2 uv : TEXCOORD0;
				float4 vertex : SV_POSITION;
				float3 worldPos : TEXCOORD1;
			};

			sampler2D _MainTex;
			sampler2D _DisolveTex;
			float4 _MainTex_ST;
			float _DisolveY;
			float _DisolveThresh;
			float _StartingY;
			
			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = TRANSFORM_TEX(v.uv, _MainTex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}
			
			fixed4 frag (v2f i) : SV_Target
			{
				// sample the texture

    //            fixed4 col;
				//float transition = _DisolveY - i.worldPos.y;
				//clip(_StartingY + (transition + (tex2D(_DisolveTex, i.uv)) * _DisolveSize));
				//col = tex2D(_MainTex, i.uv);
				//return col;
                
                fixed4 col;
                float transition = _DisolveY - i.worldPos.y;
                clip(tex2D(_DisolveTex, i.uv) - _DisolveThresh);
                col = tex2D(_MainTex, i.uv);
                return col;
			}
			ENDCG
		}
	}
}
