Shader "Journey/RayMarchWithShadow"
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
            uniform int _MaxIterations;
            uniform float _accuracy;
            uniform float _MaxDistance;
            uniform float4 _sphere1, _sphere2, _box1;
            uniform float _box1round;
            //uniform float3 _modInterval;
            uniform float3 _lightDirection, _lightCol;
            uniform float _lightIntensity;
            uniform float4 _mainColor;
            uniform float4 _secondColor, _backgroundColor;
            uniform float4 _shadowColor;
            uniform float _thresh1, _thresh2;
            uniform float _twist;
            uniform float2 _shadowDistance;
            uniform int _isSoftShadow;
            uniform float _shadowIntensity;
            uniform float _ShadowPenumbra;
            
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
            
            float BoxSphere(float3 pos){
                float sphere1 = sdSphere(pos - _sphere1.xyz, _sphere1.w);
                //float box1 = sdBox(pos - _box1.xyz, _box1.www);
                float box1 = sdRoundBox(pos - _box1.xyz, _box1.www, _box1round);
                float combine1 = opSmoothSubtraction(sphere1, box1, _thresh1);
                float sphere2 = sdSphere(pos - _sphere2.xyz, _sphere2.w);
                float combine2 = opSmoothIntersection(sphere2, combine1, _thresh2);
                return combine2;
            }
            
            float distanceField(float3 pos)
            {
                //float modX = pMod1(pos.x, _modInterval.x);
                //float modY = pMod1(pos.y, _modInterval.y);
                //float modZ = pMod1(pos.z, _modInterval.z);
                //float3 twist = opTwist(pos, _twist);
                //float modX = pMod1(twist.x, _modInterval.x);
                //float modY = pMod1(twist.y, _modInterval.y);
                //float modZ = pMod1(twist.z, _modInterval.z);
                
                //float sphere2 = sdSphere(pos - _box1.xyz, _box1.w);
                //
                //float torus = sdTorus(twist - _box1.xyz, float2(_box1.w, 1.0));
                float ground = sdPlane(pos, float4(0,1,0,0));
                float boxSphere = BoxSphere(pos);
                return opU(ground, boxSphere);
            }
            
            float3 getNormal(float3 p)
            {
                const float2 offset = float2(0.001, 0.0);
                float3 n = float3(
                    distanceField(p + offset.xyy) - distanceField(p - offset.xyy),
                    distanceField(p + offset.yxy) - distanceField(p - offset.yxy),
                    distanceField(p + offset.yyx) - distanceField(p - offset.yyx)
                );
                return normalize(n);
            }
            
            float hardShadow(float3 ro, float3 rd, float minTravel, float maxTravel){
                for(float t = minTravel; t < maxTravel; ){
                    float h = distanceField(ro+rd*t);
                    if(h < 0.001){
                        return 0.0;
                    }
                    t += h;
                }
                return 1.0;
            }
            
            float softShadow(float3 ro, float3 rd, float mint, float maxt, float k)
            {
                float result = 1.0;
                for(float t = mint; t < maxt;)
                {
                    float h = distanceField(ro+rd*t);
                    if (h < 0.001)
                    {
                        return 0.0;
                    }
                    result = min(result, k*h/t);
                    t += h;
                }
                return result;
            }
            
            uniform float _aoStepSize;
            uniform float _aoIterations;
            uniform float _aoIntensity;
            
            float ambientOcclusion(float3 p, float3 n){
                float step = _aoStepSize;
                float ao = 0.0;
                float dist;
                for(int i = 0; i <= _aoIterations; i++){
                    dist = step * i;
                    ao += max(0.0, (dist - distanceField(p + n * dist)) / dist);
                }
                return (1.0 - ao * _aoIntensity);
            }
            
            float3 shading(float3 p, float3 n){
                
                float3 result;
                //Diffuse Color
                float3 color = _mainColor.rgb;
                float3 shadowColor = _shadowColor.rgb;
                //Directional Light
                float3 light = (_lightCol * dot(-_lightDirection, n) * 0.5 + 0.5) * _lightIntensity;
                //Shadows
                float shadow;
                if(_isSoftShadow)
                    shadow = softShadow(p, -_lightDirection, _shadowDistance.x, _shadowDistance.y,_ShadowPenumbra) * 0.5 + 0.5;
                else
                    shadow = hardShadow(p, -_lightDirection, _shadowDistance.x, _shadowDistance.y) * 0.5 + 0.5;
                shadow = max(0.0, pow(shadow, _shadowIntensity));
                //Ambient Occlusion
                float ao = ambientOcclusion(p, n);
                result = lerp(_mainColor.rgb, _shadowColor.rgb, clamp(1 - shadow * ao, 0.0, 1.0)) * light * shadow * ao;
                return result;
            }
            
            fixed4 raymarching(float3 _rayOrigin, float3 _rayDirection, float _depth)
            {
                fixed4 result = fixed4(1,1,1,1);
                const int max_iteration = _MaxIterations;
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
                    float d = distanceField(pos);
                    if(d < _accuracy)  //if hit something
                    {
                        //shading
                        float3 n = getNormal(pos);
                        float3 s = shading(pos, n);
                        //float light = dot(-_lightDirection, n);
                        
                        result = fixed4(s, 1);
                        break;
                    }
                    t += d;
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
