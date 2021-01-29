Shader "GC/fast-transluency"
{
    Properties
    {
        _Color ("Color", Color) = (1,1,1,1)
        _MainTex ("Albedo (RGB)", 2D) = "white" {}
        _Glossiness ("Smoothness", Range(0,1)) = 0.5
        _Metallic ("Metallic", Range(0,1)) = 0.0

        _Translucency_Power("Translucency Power", Range(0, 1)) = 0.2
        _Translucency_Scale("Translucency Scale", Float) = 1.0
        _Translucency_Distortion("Translucency Distortion", Range(0, 1)) = 1.0
        [Toggle(ONLY_STANDARD)]_TT("No Translucency", Float) = 1.0
        [Toggle(DIY_MODE)]_TT2("DIY", Float) = 1.0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 200

        CGPROGRAM
        // Physically based Standard lighting model, and enable shadows on all light types
        #pragma surface surf StandardTranslucent fullforwardshadows
        #pragma shader_feature ONLY_STANDARD


        // Use shader model 3.0 target, to get nicer looking lighting
        #pragma target 3.0

        sampler2D _MainTex;

        struct Input
        {
            float2 uv_MainTex;
        };

        half _Glossiness;
        half _Metallic;
        fixed4 _Color;

        float _Translucency_Power;
        float _Translucency_Scale;
        float _Translucency_Distortion;

        // Add instancing support for this shader. You need to check 'Enable Instancing' on materials that use the shader.
        // See https://docs.unity3d.com/Manual/GPUInstancing.html for more information about instancing.
        // #pragma instancing_options assumeuniformscaling
        UNITY_INSTANCING_BUFFER_START(Props)
        // put more per-instance properties here
        UNITY_INSTANCING_BUFFER_END(Props)


        
        #include "UnityPBSLighting.cginc"
        inline fixed4 LightingStandardTranslucent(SurfaceOutputStandard s, fixed3 viewDir, UnityGI gi)
        {
            // Original colour
            fixed4 pbr = LightingStandard(s, viewDir, gi);
            #if ONLY_STANDARD
                return pbr;
            #endif
            
            // ...
            // Alter "pbr" here to include the new light
            // ...
            float3 L = gi.light.dir;
            float3 V = viewDir;
            float3 N = s.Normal;
            
            float3 H = normalize(L + N * _Translucency_Distortion);
            float I = pow(saturate(dot(V, -H)), _Translucency_Power) * _Translucency_Scale;
            pbr.rgb = pbr.rgb + _LightColor0 * I;
            
            return pbr;
        }
        
        void LightingStandardTranslucent_GI(SurfaceOutputStandard s, UnityGIInput data, inout UnityGI gi)
        {
            LightingStandard_GI(s, data, gi); 
        }

        void surf (Input IN, inout SurfaceOutputStandard o)
        {
            // Albedo comes from a texture tinted by color
            fixed4 c = tex2D (_MainTex, IN.uv_MainTex) * _Color;
            o.Albedo = c.rgb;
            // Metallic and smoothness come from slider variables
            o.Metallic = _Metallic;
            o.Smoothness = _Glossiness;
            o.Alpha = c.a;
        }
        ENDCG
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" "LightMode" = "ForwardBase" }
        LOD 100
        Cull Off

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            #pragma shader_feature DIY_MODE;

            sampler2D _MainTex;

            float _Translucency_Power;
            float _Translucency_Scale;
            float _Translucency_Distortion;

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 normal : VAR_NORMAL;
                float3 worldPos : VAR_WORLD_POS;
            };

            v2f vert(appdata_full i)
            {
                v2f v;
                v.vertex = UnityObjectToClipPos(i.vertex);
                v.normal = UnityObjectToWorldNormal(i.normal);
                v.worldPos = mul(unity_ObjectToWorld, i.vertex);
                return v;
            }

            float4 frag(v2f i) : SV_Target
            {
                float3 normal = normalize(i.normal);
                float3 viewDir = normalize(UnityWorldToViewPos(i.worldPos));
                float3 H = normalize(_WorldSpaceLightPos0 + normal* _Translucency_Distortion);
                H = mul(UNITY_MATRIX_V, float4(H, 0)).xyz;
                float vh = dot(viewDir, H);
                #ifdef DIY_MODE
                    float I = pow((vh + 1), _Translucency_Power) / pow(2, _Translucency_Power) * _Translucency_Scale;
                #else
                    float I = pow(vh * 0.5 + 0.5, _Translucency_Power) * _Translucency_Scale;
                #endif
                return I * _LightColor0;
            }
            ENDCG
        }
    }

    
    FallBack "Diffuse"
}
