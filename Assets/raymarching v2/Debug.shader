Shader "Hidden/Debug"
{

    SubShader
    {
        Cull Off ZWrite Off ZTest Always

        Pass
        {
            HLSLPROGRAM

            #pragma target 3.5

            #pragma vertex vert
            #pragma fragment frag

            //#include "Packages/com.unity.postprocessing/PostProcessing/Shaders/StdLib.hlsl"
            //#include "HLSLSupport.cginc"
            #include "UnityCG.cginc"

            //TEXTURE2D_SAMPLER2D(_MainTex, sampler_MainTex);
            uniform sampler2D _MainTex;
            uniform sampler2D_float _CameraDepthTexture, sampler_CameraDepthTexture;
            half4 _MainTex_ST;
            uniform float4 _CamWorldSpace;
            uniform float4x4 _CamFrustum,  _CamToWorld;
            uniform int _MaxIterations;
            uniform float _MaxDistance;
            uniform float _MinDistance;
            float4 _Tint;

            uniform float4 _MainTex_TexelSize;

            struct AttributesDefault
            {
                float3 vertex : POSITION;
                half2 texcoord : TEXCOORD0;
            };

            struct VaryingsDefault
            {
                float4 pos : SV_POSITION;
                float2 uv : TEXCOORD0;
                float2 uvStereo : TEXCOORD4;
                //float2 uvStereo : TEXCOORD1;
                float2 uv_depth : TEXCOORD1;
                float4 interpolatedRay : TEXCOORD2;
                float3 wPos : TEXCOORD3;
            };

            struct v2f
            {
             float4 vertex : SV_POSITION;
             float2 texcoord : TEXCOORD0;
             float2 texcoordStereo : TEXCOORD1;
             float4 ray : TEXCOORD2;
            };

            float LinearEyeDepth135( float z )
            {
                return LinearEyeDepth( z );
            }
            // Vertex manipulation
            float2 TransformTriangleVertexToUV(float2 vertex)
            {
                float2 uv = (vertex + 1.0) * 0.5;
                return uv;
            }

            //VaryingsDefault vert(AttributesDefault v  )
            //{
            //  VaryingsDefault o;
            //  v.vertex.z = 0.1;
            //  o.wPos =  mul(UNITY_MATRIX_VP, v.vertex);
            //  o.pos = float4(v.vertex.xy, 0.0, 1.0);
            //  o.uv = TransformTriangleVertexToUV(v.vertex.xy);
            //  o.uv_depth = v.texcoord.xy;

            //  #if UNITY_UV_STARTS_AT_TOP
            //      o.uv = o.uv * float2(1.0, -1.0) + float2(0.0, 1.0);
            //  #endif

            //  o.uvStereo = TransformStereoScreenSpaceTex(o.uv, 1.0);

            //  #if UNITY_UV_STARTS_AT_TOP
            //      if (_MainTex_TexelSize.y < 0)
            //          o.uv.y = 1 - o.uv.y;
            //  #endif

            //  //int frustumIndex = v.texcoord.x + (2 * o.uv.y);
            //  //o.interpolatedRay = _CamFrustum[frustumIndex];
            //  //o.interpolatedRay.w = frustumIndex;

            //  int index = (o.uv.x / 2) + o.uv.y;
            //  o.interpolatedRay = _CamFrustum[index];
            //  //o.interpolatedRay /= abs(o.interpolatedRay.z);
            //  //o.interpolatedRay = mul(_CamToWorld, o.interpolatedRay);

            //  return o;
            //}

            v2f vert(AttributesDefault v  )
            {
                v2f o;
                v.vertex.z = 0.1;
                //o.vertex = mul(UNITY_MATRIX_VP, v.vertex);
                o.vertex = float4(v.vertex.xy, 0.0, 1.0);
                o.texcoord = TransformTriangleVertexToUV(v.vertex.xy);

                //#if UNITY_UV_STARTS_AT_TOP
                //  o.texcoord = o.texcoord * float2(1.0, -1.0) + float2(0.0, 1.0);
                //#endif

                o.texcoordStereo = TransformStereoScreenSpaceTex(o.texcoord, 1.0);

                //#if UNITY_UV_STARTS_AT_TOP
                //  if (_MainTex_TexelSize.y < 0)
                //      o.texcoord.y = 1 - o.texcoord.y;
                //#endif

                //int index = v.texcoord.x + (2 * o.texcoord.y);
                int index = (o.texcoord.x / 2) + o.texcoord.y;
                o.ray = _CamFrustum[index];

                return o;
            }

            float sdSphere(float3 position, float3 origin, float radius)
            {
                return distance(position, origin) - radius;
            }

            float sdf_sphere(float3 p, float3 c, float r) 
             {
                 return distance(p, c) - r;
             }

            fixed4 raymarching(float3 rayOrigin, float3 rayDirection) {
                fixed4 result = float4(1, 1, 1, 1);
                float t = 0.01; // Distance Traveled from ray origin (ro) along the ray direction (rd)

                for (int i = 0; i < _MaxIterations; i++)
                {
                    if (t > _MaxDistance)
                    {
                        result = float4(rayDirection, 1); // color backround from ray direction for debugging
                        break;
                    }

                    float3 p = rayOrigin + rayDirection * t;    // This is our current position
                    //float3 p = float3(5, 0, 0) + (float3(1, 0, 0) * t);   // This is our current position
                    //float d = sdSphere(p, float3(1, 0, 0), 2); // should be a sphere at (0, 0, 0) with a radius of 1
                    float d = sdf_sphere(p, float3(0, 0, 0), 1);
                    if (d <= _MinDistance) // We have hit something
                    {
                        // shading
                        result = float4(1, 1, 1, 1); // yellow sphere should be drawn at (0, 0, 0)
                        break;
                    }

                    //t += max(0.01, 0.02 * 2);
                    t += d;
                }

                return result;
            }

            fixed4 rm (float3 ro, float3 rd) {
                fixed4 result = float4(0, 0, 0, 1);
                float t = 0;

                for (int i = 0; i < 100; i++) {
                    float3 p = ro + rd * t;
                    float d = sdf_sphere(p, float3(0, 0, 0), 0.8);
                    if (d <= _MinDistance) // We have hit something
                    {
                        // shading
                        result = float4(1, 1, 0, 1); // yellow sphere should be drawn at (0, 0, 0)
                        break;
                    }

                    t += d;
                }

                return result;
            }

            float4 frag(v2f i) : SV_Target
            {
                //float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(i.uv ));
                //float dpth = Linear01Depth(rawDepth);

                //float depth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, sampler_CameraDepthTexture, i.uvStereo);
                //depth = Linear01Depth(depth);

                //float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uvStereo);
                //float dpth = Linear01Depth(rawDepth);

                ////float4 wsDir = normalize(i.interpolatedRay);
                //float3 wsDir = normalize(i.interpolatedRay);
                //float4 wsPos = _CamWorldSpace;
                ////fixed4 result = raymarching(_CamWorldSpace, normalize(i.interpolatedRay.xyz));
                //fixed4 result = rm(_CamWorldSpace, normalize(i.interpolatedRay.xyz));
                //return result;

                //float dpth = Linear01Depth(rawDepth);
                //return raymarching(_WorldSpaceCameraPos, normalize(i.interpolatedRay));

                return raymarching(_CamWorldSpace, normalize(i.ray));

                //half4 sceneColor = tex2D(_MainTex, UnityStereoTransformScreenSpaceTex(i.uv));

                //// Reconstruct world space position & direction
                //// towards this screen pixel.
                //float rawDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, UnityStereoTransformScreenSpaceTex(i.uv ));

                //float dpth = Linear01Depth(rawDepth);
                //float4 wsDir = dpth * i.interpolatedRay;
                //float4 wsPos = _CamWorldSpace + wsDir;

                //return wsPos;
                //return raymarching(wsPos, wsDir);
            }

            ENDHLSL
        }
    }
}