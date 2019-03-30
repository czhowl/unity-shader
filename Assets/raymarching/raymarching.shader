Shader "Journey/raymarching"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
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
            #pragma target 3.0
            
            #include "UnityCG.cginc"
            #include "DistanceFunctions.cginc"

            sampler2D _MainTex;
            uniform sampler2D _CameraDepthTexture;
            uniform float4x4 _CamFrustum, _CamToWorld;
            uniform float _MaxDistance;
            uniform float4 _sphere1, _box1;
            uniform float3 _modInterval;
            uniform float3 _lightDirection;
            uniform float4 _mainColor;
            uniform float4 _secondColor, _backgroundColor;
            uniform float4 _shadowColor;
            uniform float _thresh;
            uniform float _twist;
            
            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 pos : SV_POSITION;
                float3 ray : TEXCOORD1;
            };

            v2f vert (appdata v)
            {
                v2f o;
                half index = v.vertex.z;
                v.vertex.z = 0;
                o.pos = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv.xy;

                o.ray = _CamFrustum[(int)index].xyz;

                o.ray /= abs(o.ray.z);

                o.ray = mul(_CamToWorld, o.ray);

                return o;
            }
            
            float2 distanceField(float3 pos)
            {
                //float modX = pMod1(pos.x, _modInterval.x);
                //float modY = pMod1(pos.y, _modInterval.y);
                //float modZ = pMod1(pos.z, _modInterval.z);
                float3 twist = opTwist(pos, _twist);
                //float modX = pMod1(twist.x, _modInterval.x);
                //float modY = pMod1(twist.y, _modInterval.y);
                //float modZ = pMod1(twist.z, _modInterval.z);
                float sphere1 = sdSphere(pos - _sphere1.xyz, _sphere1.w);
                //float sphere2 = sdSphere(pos - _box1.xyz, _box1.w);
                //float box1 = sdBox(pos - _box1.xyz, _box1.www);
                float torus = sdTorus(twist - _box1.xyz, float2(_box1.w, 1.0));
                float mix =  clamp( 0.5 + 0.5*(sphere1 - torus)/2.0, 0.0, 1.0 );
                return float2(opSmoothUnion(sphere1, torus, _thresh), mix);
            }
            
            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(
                    distanceField(p + offset.xyy).x - distanceField(p - offset.xyy).x,
                    distanceField(p + offset.yxy).x - distanceField(p - offset.yxy).x,
                    distanceField(p + offset.yyx).x - distanceField(p - offset.yyx).x
                );
                return normalize(n);
            }
            
            fixed4 raymarching(float3 _rayOrigin, float3 _rayDirection, float _depth)
            {
                fixed4 result = fixed4(1,1,1,1);
                const int max_iteration = 164;
                float t = 0;   //distance travelled along the ray direction
                
                for(int i = 0; i < max_iteration; i++)
                {
                    if (t > _MaxDistance || t >= _depth)
                    {
                        //draw environment
                        result = fixed4(_rayDirection, 0);
                        break;
                    }
                    
                    float3 pos = _rayOrigin + _rayDirection * t;
                    //check for hit in distanceField
                    float2 d = distanceField(pos);
                    if(d.x < 0.01)  //if hit something
                    {
                        //shading
                        float3 n = getNormal(pos);
                        float light = dot(-_lightDirection, n);
                        //result = fixed4(_mainColor.rgb * light,1);
                        result = fixed4(lerp(lerp(_mainColor.rgb, _secondColor.rgb , d.y), _shadowColor.rgb, 0.4 - light),1);
                        break;
                    }
                    t += d.x;
                }
                
                return result;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float depth = LinearEyeDepth(tex2D(_CameraDepthTexture, i.uv).r);
                depth *= length(i.ray);
                //background colors
                fixed3 col = tex2D(_MainTex, i.uv);
                col = _backgroundColor.rgb;
                float3 rayDirection = normalize(i.ray.xyz);
                float3 rayOrigin = _WorldSpaceCameraPos;
                fixed4 result = raymarching(rayOrigin, rayDirection, depth);
                return fixed4(col * (1.0 - result.w) + result.xyz * result.w, 1.0);
            }
            ENDCG
        }
    }
}
