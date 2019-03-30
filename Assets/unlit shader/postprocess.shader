Shader "Custom/postprocess"
{
	Properties
	{
		_MainTex ("rename texture here", 2D) = "white" {}
	}
	SubShader
	{
		// No culling or depth
		Cull Off ZWrite Off ZTest Always

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
			};

			v2f vert (appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.uv = v.uv;
				return o;
			}
			
			sampler2D _MainTex;

			fixed4 frag (v2f i) : SV_Target
			{
				// col = color
				fixed4 col = tex2D(_MainTex, i.uv + float2(cos(i.vertex.y/200 + _Time[1]*10)/300, sin(i.vertex.x/200 + _Time[1]*10)/300));
				// just invert the colors
				col.r = 1 - col.r;
				return col;
			}
			ENDCG
		}
	}
}
