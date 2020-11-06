
//预计算Kelemen/Szirmay-Kalos BRDF所使用的NDF
Shader "GC/ks_LUT"
{
    Properties
    {
    }

    SubShader
    {
        Tags { "RenderType"="Opaque" }

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
                float2 uv:TEXCOORD0;
            };

            struct v2f
            {
                float2 uv:TEXCOORD0;
                float4 clipPos:SV_POSITION;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.clipPos = UnityObjectToClipPos(v.pos);
                o.uv = v.uv;
                return o;
            }

            float PHBeckmann(float nDotH, float m)
			{
				float alpha = acos(nDotH);
				float tanAlpha = tan(alpha);
				float value = exp(-(tanAlpha * tanAlpha) / (m * m)) / (m * m * pow(nDotH, 4.0));
				return value;
			}


            fixed4 frag(v2f i):SV_TARGET
            {
                float value = 0.5 * pow(PHBeckmann(i.uv.x, i.uv.y), 0.1);
				return float4(value, value, value, 1.0);
            }
            ENDCG
        }
    }
}