
//预计算diffusion profile
Shader "GC/DiffusionProfile"
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

            float Gaussian(float v, float r)
            {
                return exp( -(r * r) / (2 * v)) / sqrt(2.0 * UNITY_PI * v);
            }

            float3 Scatter(float r)
            {
                return Gaussian(0.0064 * 1.414, r) * float3(0.233, 0.455, 0.649) 
                + Gaussian(0.0484 * 1.414, r) * float3(0.100, 0.336, 0.344)
                + Gaussian(0.1870 * 1.414, r) * float3(0.118, 0.198, 0.000)
                + Gaussian(0.5670 * 1.414, r) * float3(0.113, 0.007, 0.007)
                + Gaussian(1.9900 * 1.414, r) * float3(0.358, 0.004, 0.000)
                + Gaussian(7.4100 * 1.414, r) * float3(0.078, 0.000, 0.000);
            }

            float3 IntegrateDiffuseScatteringOnRing(float cosTheta, float skinRadius)
            {
                float theta = acos(cosTheta);
                float3 totalWeights = 0;
                float3 totalLight = 0;

                float a = -(UNITY_PI / 2);
                while( a <= (UNITY_PI / 2))
                {
                    float sampleAngle = theta + a;
                    float diffuse = saturate(cos(sampleAngle));
                    float sampleDist = abs(2.0 * skinRadius*sin(a * 0.5));
                    float3 weights = Scatter(sampleDist);

                    totalWeights += weights;
                    totalLight += diffuse * weights;
                    a += 0.1;
                }
                return totalLight / totalWeights;
            }


            fixed4 frag(v2f i):SV_TARGET
            {
                float3 r = 1.0 / (i.uv.y + 0.0001);
                float3 color = IntegrateDiffuseScatteringOnRing(lerp(-1, 1, i.uv.x), r);
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}