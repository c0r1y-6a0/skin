Shader "GC/Test"
{
    Properties
    {
        _BaseMap("BaseMap", 2D) = "white"{}
        _Roughness("Roughness", Range(0, 1)) = 1 
        _F0("F0", Range(0, 1)) = 0.028 //skin F0, from RTR 4rd P322
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
            #include "gcpbr.cginc"

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
                fixed4 color = tex2D(_BaseMap, i.uv);
                float3 lightDir = normalize(_WorldSpaceLightPos0.xyz);
                float3 viewDir = normalize(UnityWorldSpaceViewDir(i.worldPos.xyz));
                float3 n = normalize(i.worldNormal.xyz);
                //float co = GC_BlinnPhongSpecular(viewDir, lightDir, n);
                //float co = GC_PhongSpecular(viewDir, lightDir, i.worldNormal.xyz);

                float co = GC_CookTorranceSpecular(lightDir, viewDir, n, _F0, _Roughness);
                return color * fixed4(co, co, co, 1.0);
            }
            ENDCG
        }
    }
}