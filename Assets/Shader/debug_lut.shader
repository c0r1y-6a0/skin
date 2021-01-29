Shader "GC/lut"
{
    Properties
    {
        _LutTex("LUT", 2D) = "white"{}
        _Tint("Tint", Color) = (1,1,1,1)
        _Cur("Radius", Float) = 1.0
    }
    SubShader
    {
        Tags { "RenderType" = "Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityStandardBRDF.cginc"
            #include "AutoLight.cginc"		

            sampler _LutTex;
            float _Cur;
            float3 _Tint;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float3 worldNormal : VAR_NORMAL;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.worldNormal = mul(unity_ObjectToWorld,v.vertex);
                return o;
            }

            float4 sss_color(float nl)
            {
                nl = nl * 0.5 + 0.5;
                float curvature = 1/_Cur;
                return tex2D(_LutTex, float2(nl, curvature));
            }

            float Gaussian(float v, float r)
            {
                return exp( -(r * r) / (2.0 * v)) / sqrt(2.0 * UNITY_PI * v);
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
                    a += 0.01;
                }
                return totalLight / totalWeights;
            }

            fixed3 frag(v2f i) : SV_Target
            {
                float3 worldNormal = i.worldNormal;

                float NdotL = saturate(dot(worldNormal, _WorldSpaceLightPos0));
                //return sss_color(NdotL);
                return IntegrateDiffuseScatteringOnRing(NdotL,  _Cur) * _Tint;
            }
            ENDCG
        }
    }
}
