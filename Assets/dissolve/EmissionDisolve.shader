Shader "Custom/EmissionDisolve"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0
        _DisolveTex ("Disolve Texture", 2D) = "white" {}
        _DisolveThresh("Size of the effect", Range (0.0, 1.0)) = 0.5
        _EmissionAmount("Emission amount", float) = 2.0
        _BurnSize("Burn Size", Range(0.0, 1.0)) = 0.15
        [HDR]_BurnColor("Burn Color", Color) = (1,1,1,1)
        _BurnRamp("Burn Ramp (RGB)", 2D) = "white" {}
        _DisolveY("Current Y of the disolve effect", Float) = 0
        _StartingY("Starting point of the disolve effect", Float) = -10
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf Standard fullforwardshadows

        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;
        sampler2D _DisolveTex;
        sampler2D _BurnRamp;
        float _DisolveThresh;
        float _BurnSize;
        float _EmissionAmount;
        fixed4 _BurnColor;
        float _DisolveY;
        float _StartingY;

        struct Input
        {
            float2 uv_MainTex;
            float3 worldPosAdj;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;
        
        void vert (inout appdata_full v, out Input o) {
            UNITY_INITIALIZE_OUTPUT(Input,o);
            o.worldPosAdj =  mul (unity_ObjectToWorld, v.vertex.xyz);
        }
        
        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
            // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            fixed4 col;
            half test;
            //float transition = _DisolveY - IN.worldPosAdj.y;
            //test = _StartingY + (transition + (tex2D(_DisolveTex, IN.uv_MainTex)) * _DisolveThresh);
            test = tex2D(_DisolveTex, IN.uv_MainTex).rgb - _DisolveThresh;
            clip(test);
            // Albedo comes from a texture tinted by color
            if (test < _BurnSize && _DisolveThresh > 0) {
                o.Emission = tex2D(_BurnRamp, float2(test * (1 / _BurnSize), 0)) * _BurnColor * _EmissionAmount;
            }
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }
    FallBack "Diffuse"
}
