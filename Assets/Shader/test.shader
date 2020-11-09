Shader "GC/Test"
{
    Properties
    {
        _Albedo("Albedo", 2D) = "white"{}
        _Roughness("Roughness", Range(0, 1)) = 1 
        _F0("F0", Range(0, 1)) = 0.028 //skin F0, from RTR 4rd P322

        _NormalMap("NormalMap", 2D) = "white"{}

        _KSLut("KSLut", 2D) = "white"{}
        _KSBrightness("KSBrightness", float) = 1

        _DiffusionProfileLUT("PreIntegrated Diffusion Profile LUT", 2D) = "white"{}
        _ScatterColor("Scatter Color", Color) = (1, 1, 1, 1)
        _TuneCurvature("Tune Curvature", Range(0.001, 0.1)) = 1.0

        [Space(50)]

        [Toggle] _NormalBlur("Normal Blur", float) = 0
        [KeywordEnum(ALL, SpecularColorOnly, SpecularGrayScaleOnly, ScatterOnly)] _LightMode("Lighting Mode", float) = 0

        [KeywordEnum(Phong, BlinnPhong, PBR)] _Specular("Specular Mode", float) = 0
        [KeywordEnum(CookTorrance, KelemenSzirmayKalos)] _BRDF("BRDF formular", float) = 0
        [KeywordEnum(BlinnPhong, Beckmann, CGX)] _D("Distribution Term in BRDF", float) = 0
        [KeywordEnum(Implicit, Smith)] _G("Geometry Term in BRDF", float) = 0
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM

            #pragma shader_feature _NORMALBLUR_ON

            #pragma multi_compile _LIGHTMODE_ALL _LIGHTMODE_SPECULARCOLORONLY  _LIGHTMODE_SPECULARGRAYSCALEONLY  _LIGHTMODE_SCATTERONLY
            #pragma multi_compile _SPECULAR_PHONG _SPECULAR_BLINNPHONG _SPECULAR_PBR
            #pragma multi_compile _BRDF_COOKTORRANCE _BRDF_KELEMENSZIRMAYKALOS
            #pragma multi_compile _D_BLINNPHONG _D_BECKMANN _D_CGX
            #pragma multi_compile _G_IMPLICIT _G_SMITH

            #pragma vertex vert
            #pragma fragment frag

            struct appdata
            {
                float4 pos:POSITION;
                float3 normal: NORMAL;
                float4 tangent : TANGENT;
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 T2W0 :TEXCOORD1;
                float4 T2W1 :TEXCOORD2;
                float4 T2W2 :TEXCOORD3;
                float4 clipPos:SV_POSITION;
            };

            sampler2D _Albedo;
            float _Roughness;
            float _F0;

            sampler2D _NormalMap;

            float _KSBrightness;

            float3 _ScatterColor;
            float _TuneCurvature;

            #include "UnityCG.cginc"
            #include "gcpbr.cginc"

            v2f vert(appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;
                float3 worldNormal = UnityObjectToWorldNormal(v.normal);
                float3 worldTangent = UnityObjectToWorldDir(v.tangent);
                float3 worldBitangent = cross(worldNormal ,worldTangent) * v.tangent.w;

                float3 worldPos = mul(unity_ObjectToWorld, v.pos);
                o.T2W0 = float4 (worldTangent.x,worldBitangent.x,worldNormal.x,worldPos.x);
                o.T2W1 = float4 (worldTangent.y,worldBitangent.y,worldNormal.y,worldPos.y);
                o.T2W2 = float4 (worldTangent.z,worldBitangent.z,worldNormal.z,worldPos.z);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET
            {
                float3 n = normalize(float3( i.T2W0.z, i.T2W1.z, i.T2W2.z));
                float3 worldPos = float3(i.T2W0.w, i.T2W1.w, i.T2W2.w);

                fixed4 albedo = tex2D(_Albedo, i.uv);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(worldPos));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));

                fixed3 tangetSpaceNormal = UnpackNormal(tex2D(_NormalMap,i.uv));
                fixed3 worldNormalHigh = normalize(float3( dot(i.T2W0.xyz,tangetSpaceNormal),
                                                    dot(i.T2W1.xyz,tangetSpaceNormal),
                                                    dot(i.T2W2.xyz,tangetSpaceNormal)));

                float specular = 1.0;

                #if _SPECULAR_PHONG
                specular = GC_PhongSpecular(viewDir, lightDir, n);
                #elif _SPECULAR_BLINNPHONG
                specular = GC_BlinnPhongSpecular(viewDir, lightDir, n);
                #elif _SPECULAR_PBR
                    #if _BRDF_KELEMENSZIRMAYKALOS
                    specular = GC_KSSpecular(lightDir, viewDir, n, _F0, _Roughness, _KSBrightness);
                    #elif _BRDF_COOKTORRANCE
                    specular = GC_CookTorranceSpecular(lightDir, viewDir, n, _F0, _Roughness);
                    #endif
                #endif

                float3 scatter = GC_PreIntegratedDiffusionProfileScattering(n, worldNormalHigh, worldPos.xyz, lightDir, _TuneCurvature) * _ScatterColor * albedo;

                #if _LIGHTMODE_ALL
                return fixed4(albedo * specular + scatter, 1.0);
                #elif _LIGHTMODE_SCATTERONLY
                return fixed4(scatter, 1.0);
                #elif _LIGHTMODE_SPECULARCOLORONLY
                return albedo * specular;
                #elif _LIGHTMODE_SPECULARGRAYSCALEONLY
                return fixed4(specular, specular, specular, 1.0);
                #endif
            }
            ENDCG
        }
    }
}