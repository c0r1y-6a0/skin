Shader "GC/showuv2"
{
    Properties
    {
        _MainTex("Albedo", 2D) = "white"{}
        _NormalTex("NormalMap", 2D) = "white"{}
        _LutTex("LUT", 2D) = "white"{}
        _Smoothness("SmoothNess", Range(0, 1)) = 0.3
        _Co("CO", Float) = 10
		_SpecularColor ("SpecularColor", Color) = (0,0,0,1)
		_SpecularScale("SpecularScale", Range(0,20)) = 1
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

            float _Co;
            float _Smoothness;
            sampler _LutTex;

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _NormalTex;
            float4 _NormalTex_ST;

			float _SpecularScale;
			fixed4 _SpecularColor;

            struct appdata
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
                float4 tangent : TANGENT;
                float4 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
            };

            struct v2f
            {
                float4 vertex : SV_POSITION;
                float4 uv : TEXCOORD0;
                float2 uv2 : TEXCOORD1;
                float4 T2W0 :TEXCOORD2;
                float4 T2W1 :TEXCOORD3;
                float4 T2W2 :TEXCOORD4;
            };

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv.xy = TRANSFORM_TEX(v.uv, _MainTex);
                o.uv.zw = TRANSFORM_TEX(v.uv, _NormalTex);
                o.uv2 = v.uv2;

                float3 worldPos = mul(unity_ObjectToWorld,v.vertex);
                float3 worldNormal = normalize(UnityObjectToWorldNormal(v.normal));
                float3 worldTangent = normalize(UnityObjectToWorldDir(v.tangent));
                float3 worldBitangent = normalize(cross(worldNormal ,worldTangent) * v.tangent.w);

                //tangent->world normal translate matrix
                o.T2W0 = float4 (worldTangent.x,worldBitangent.x,worldNormal.x,worldPos .x);
                o.T2W1 = float4 (worldTangent.y,worldBitangent.y,worldNormal.y,worldPos .y);
                o.T2W2 = float4 (worldTangent.z,worldBitangent.z,worldNormal.z,worldPos .z);

                return o;
            }

            float4 sss_color(v2f i, float nl)
            {
                nl = nl * 0.5 + 0.5;
                float curvature = i.uv2.x/ _Co;
                //return curvature;
                return tex2D(_LutTex, float2(nl, curvature));
            }

            float3 GetWorldNormal(v2f i)
            {
                fixed4 tangentNormal = tex2D(_NormalTex,i.uv.zw);
                fixed3 bump = UnpackNormal(tangentNormal);
                fixed3 worldNormal = normalize(float3( dot(i.T2W0.xyz,bump), dot(i.T2W1.xyz,bump), dot(i.T2W2.xyz,bump))); 
                return worldNormal;
            }

            float fresnelReflectance( float3 H, float3 V, float F0 )
            {
                float base = 1.0 - dot( V, H );
                float exponential = pow( base, 5.0 );
                return exponential + F0 * ( 1.0 - exponential );
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float4 albedo = tex2D(_MainTex, i.uv);

                float3 worldNormal = GetWorldNormal(i);

                float perceptualRoughness = 1 - _Smoothness;
				float roughness = perceptualRoughness * perceptualRoughness;

                float3 worldPos  = float3(i.T2W0.w,i.T2W1.w,i.T2W2.w);
                fixed3 viewDir = normalize(UnityWorldSpaceViewDir(worldPos));
                float3 floatVector = normalize(_WorldSpaceLightPos0.xyz + viewDir);  //半角向量

                float NdotL = saturate(dot(worldNormal, _WorldSpaceLightPos0));
                float NdotV = saturate(dot(worldNormal, viewDir));
                float NdotH = saturate(dot(worldNormal, floatVector));
                float LdotH = saturate(dot(_WorldSpaceLightPos0, floatVector));

                float alpha = roughness;
                float G_L = NdotL + sqrt((NdotL - NdotL * alpha) * NdotL + alpha);
                float G_V = NdotV + sqrt((NdotV - NdotV * alpha) * NdotV + alpha);
                float G = G_L * G_V;
                float3 F0 = 0.028;
                fixed F = fresnelReflectance(floatVector, viewDir, 0.028);
                float alpha2 = alpha * alpha;
                float denominator = (NdotH * NdotH) * (alpha2 - 1) + 1;
                float D = alpha2 / (UNITY_PI * denominator * denominator);
                float3 specularColor = D * G * NdotL * F;

				float4 specular = float4(specularColor * FresnelTerm(_SpecularColor, LdotH) * _SpecularScale, 1);

                float4 directDiffuse = sss_color(i, NdotL);
                //return directDiffuse;
                float4 diffuseColor = albedo.rgba;

                fixed attenuation = LIGHT_ATTENUATION(i);//投影
                float4 lightColor = _LightColor0.rgba;
                float4 attenColor = attenuation * lightColor;

                return directDiffuse * diffuseColor * attenColor;// + specular;
            }
            ENDCG
        }
    }
}
