float GC_PhongSpecular(float3 v, float3 l, float3 n)
{
    return saturate(dot(normalize(reflect(-l, n)), v));
}

float GC_BlinnPhongSpecular(float3 v, float3 l, float3 n)
{
    return saturate(dot(normalize(v + l), normalize(n)));
}

//-----------------pbr-------------

//the schlick approximation of Fresnel Function
float3 GC_PBR_FresnelSchlick(float cosTheta, float3 F0)
{
    return F0 + (1.0 - F0) * pow(1.0 - cosTheta, 5.0);
}

float BlinnPhongNDF(float alpha_p, float cos)
{
    const float PI = 3.14159265;
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
    return lerp(v, 0, step(1.6, a));
}

float SmithG1(float3 m, float v, float lambda)
{
    return max(0, dot(m, v)) / (1 + lambda);
}

float SmithG2(float3 l, float3 v, float3 m, float lambda)
{
    return dot(m, v);
    //return SmithG1(l, m, lambda) * SmithG1(v, m, lambda);
}

//implicit geometry function
float ImplicitG(float3 n, float3 v, float3 l)
{
    return dot(n, l) * dot(n, v);
}

float3 GC_CookTorranceSpecular(float3 l, float3 v, float3 n, float3 F0, float alpha_b)
{
    float3 h = normalize(l + v);
    float3 F = GC_PBR_FresnelSchlick(dot(h, l), F0);
    float D = BeckmannNDF(alpha_b, dot(n, h));

    /*
    float a = Beckmann_a(n, v, alpha_b);
    float lambda = BeckmannLambda(a);
    float G2 = SmithG2(l, v, h, lambda);
    */

    float G2 = ImplicitG(n, v, l);

    return (F * G2 * D)/ (4 * abs(dot(n, l)) * abs(dot(n, v)));
}


