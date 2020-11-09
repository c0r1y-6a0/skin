
#include "UnityLightingCommon.cginc"

float GC_PhongSpecular(float3 v, float3 l, float3 n)
{
    return saturate(dot(normalize(reflect(-l, n)), v));
}

float GC_BlinnPhongSpecular(float3 v, float3 l, float3 n)
{
    return saturate(dot(normalize(v + l), normalize(n)));
}

//the schlick approximation of Fresnel Function
float GC_PBR_FresnelSchlick(float cosTheta, float F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - max(cosTheta, 0), 5.0);
}

float fresnelReflectance( float cosTheta, float F0 )
{
  	float base = 1.0 - cosTheta;
  	float exponential = pow( base, 5.0 );
  	return exponential + F0 * ( 1.0 - exponential );
}

float BlinnPhongNDF(float alpha_p, float cos)
{
    const float PI = 3.14159265;
    alpha_p = pow(8192, alpha_p);
    return (alpha_p + 2) / (2 * PI) * pow(cos, alpha_p);
}

float BeckmannNDF(float alpha_b, float cos)
{
    const float PI = 3.14159265;
    float alpha_b_square = pow(alpha_b, 2);
    float denominator =  (PI * alpha_b_square * pow(cos, 4));
    float numerator = exp(((pow(cos, 2) - 1)) / (alpha_b_square * pow(cos, 2)));
    return numerator / denominator;
}

float Beckmann_a(float3 n, float3 s, float roughness)
{
    float cos = dot(n, s);
    return cos/(roughness * sqrt(1 - pow(cos, 2)));
}

float BeckmannLambda(float a)
{
    float v = (1 - 1.259*a + 0.396*pow(a, 2))/(3.535*a+2.181*pow(a, 2));
    return lerp(0, v, step(1.6, a));
}

float SmithG1(float3 m, float v, float lambda)
{
    return step(0, dot(m, v)) / (1 + lambda);
}

float SmithG2(float3 l, float3 v, float3 m, float lambda_v, float lambda_l)
{
    return (step(0, dot(m, v)) * step(0, dot(m, l)))/(1 + lambda_v + lambda_l);
}

//implicit geometry function
float ImplicitG(float3 n, float3 v, float3 l)
{
    return dot(n, l) * dot(n, v);
}

//CookTorrance geometry function
float CTG(float3 n, float3 v, float3 h, float3 l)
{
    float nh = dot(n, h);
    float vh = dot(v, h);
    float val1 = min(1, (2 * nh * dot(n, v))/(vh));
    return min(val1, (2 * nh * dot(n, l)) / (vh));
}

sampler2D _KSLut;
//Kelemen/Szirmay-Kalos Specular
//formular: 
// DF/dot(h, h), no geometry function, h is unnormalized half vector
float GC_KSSpecular(float3 l, float3 v, float3 n, float F0, float alpha, float specular_brighness)
{
    float nl = dot(n, l);

    float3 h = l + v;
    float3 normalizedH = normalize(h);
    float nh = dot(n, normalizedH);
    float D = pow( 2.0*tex2D(_KSLut,float2(nh,alpha)), 10.0 );    

    float F = GC_PBR_FresnelSchlick(dot(normalizedH, l), F0);
    float ks = max((D * F / dot(h, h)), 0);
    float val = ks * nl * specular_brighness;
    return lerp(0, val, step(0, nl));
}

float GC_CookTorranceSpecular(float3 l, float3 v, float3 n, float F0, float alpha_b)
{
    float3 h = normalize(l + v);

    float F = GC_PBR_FresnelSchlick(dot(h, l), F0);

    float D = 1.0;
    #if _D_BLINNPHONG
    D = BlinnPhongNDF(alpha_b, dot(n, h));
    #elif _D_BECKMANN
    D = BeckmannNDF(alpha_b, dot(n, h));
    #elif _D_CGX
    //TODO:
    #endif

    float G = 1.0;
    #if _G_IMPLICIT
    G = ImplicitG(n, v, l);
    #elif _G_SMITH
    float a_l = Beckmann_a(n, l, alpha_b);
    float lambda_l = BeckmannLambda(a_l);
    float a_v = Beckmann_a(n, v, alpha_b);
    float lambda_v = BeckmannLambda(a_v);
    G = SmithG2(l, v, h, lambda_v, lambda_l);
    #endif

    return (F * G * D)/ (4 * dot(n, l) * dot(n, v));
}



sampler2D _DiffusionProfileLUT;
float3 GC_PreIntegratedDiffusionProfileScattering(float3 normal, float3 worldPos, float3 lightDir, float TuneCurvature)
{
    fixed curvature = saturate(length(fwidth(normal)) / length(fwidth(worldPos))* TuneCurvature);
    float nl = dot(normal, lightDir) * 0.5 + 0.5;
    //return float3(curvature, curvature, curvature);
    //return float3(nl, nl, nl);
    return tex2D(_DiffusionProfileLUT, float2(nl, curvature)) * _LightColor0.rgb ;

}
