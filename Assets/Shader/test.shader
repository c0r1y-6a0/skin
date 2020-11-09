Shader "GC/Test"
{
    Properties
    {
        _BaseMap("BaseMap", 2D) = "white"{}
        _Roughness("Roughness", Range(0, 1)) = 1 
        _F0("F0", Range(0, 1)) = 0.028 //skin F0, from RTR 4rd P322

        _KSLut("KSLut", 2D) = "white"{}
        _KSBrightness("KSBrightness", float) = 1

        _DiffusionProfileLUT("PreIntegrated Diffusion Profile LUT", 2D) = "white"{}
        _ScatterColor("Scatter Color", Color) = (1, 1, 1, 1)
        _TuneCurvature("Tune Curvature", Range(0.001, 0.1)) = 1.0

        [Space(50)]

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
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 worldNormal:TEXCOORD1;
                float4 clipPos:SV_POSITION;
                float4 worldPos:TEXCOORD2;
            };

            sampler2D _BaseMap;
            float _Roughness;
            float _F0;

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
                o.worldNormal.xyz = UnityObjectToWorldNormal(v.normal);
                o.worldPos = mul(unity_ObjectToWorld, v.pos);
                return o;
            }

            fixed4 frag(v2f i):SV_TARGET
            {
                fixed4 albedo = tex2D(_BaseMap, i.uv);
                float3 lightDir = normalize(UnityWorldSpaceLightDir(i.worldPos.xyz));
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos.xyz));
                float3 n = normalize(i.worldNormal.xyz);

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

                float3 scatter = GC_PreIntegratedDiffusionProfileScattering(n, i.worldPos.xyz, lightDir, _TuneCurvature) * _ScatterColor * albedo;

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