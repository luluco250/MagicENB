#include "Magic/Common.fxh"

uniform float fBloom_Intensity <
    string UIName = "Bloom Intensity";
    string UIWidget = "Spinner";
    float UIMin = 0;
    float UIMax = 3;
> = 1.0;

uniform float fBloom_Threshold <
    string UIName = "Bloom Threshold";
    string UIWidget = "spinner";
    float UIMin = 1;
    float UIMax = 6;
> = 2.0;

uniform float fAdapt_Sensitivity <
    string UIName = "Adaptation Sensitivity";
    string UIWidget = "Spinner";
    float UIMin = 0;
    float UIMax = 3;
> = 1.0;

uniform float fExposure <
    string UIName = "Exposure";
    string UIWidget = "Spinner";
    float UIMin = 0;
    float UIMax = 10;
> = 1.0;

uniform bool bWhiteFix <
    string UIName = "White Fix";
> = false;

uniform float fWhitePoint <
    string UIName = "White Point";
    string UIWidget = "Spinner";
    float UIMin = 0;
    float UIMax = 3;
> = 1.0;

uniform bool bDisplayBloom <
    string UIName = "Display Bloom Texture";
> = false;

float3 invert(float3 col) {
    return 1.0 - col;
}

float4 tonemap_hable(float4 col, float exposure) {
    static const float A = 0.15;
	static const float B = 0.50;
	static const float C = 0.10;
	static const float D = 0.20;
	static const float E = 0.02;
	static const float F = 0.30;
	static const float W = 11.2;

	static const float white_scale = 1.0 / ((W * (A * W + C * B) + D * E) / (W * (A * W + B) + D * F)) - E / F;

    col = pow(col, 2.2);
    //col *= 16;

	col *= exposure;
	col = ((col * (A * col + C * B) + D * E) / (col * (A * col + B) + D * F)) - E / F;
	
	return col * white_scale;
}

float4 PS_Effect(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    float4 col = float4(TextureColor.Sample(Sampler_Point, uv).rgb, fWhitePoint);
    float3 bloom = TextureBloom.Sample(Sampler_Linear, uv).rgb;
    bloom = pow(bloom, fBloom_Threshold) * fBloom_Intensity;
    //bloom *= bloom; //a little bit of hardcoded thresholding won't hurt
    
    col.rgb = bDisplayBloom ? bloom : col.rgb + bloom;
    //col.rgb += bloom * fBloom_Intensity;

    float exposure = TextureAdaptation.Sample(Sampler_Point, 0).x * fAdapt_Sensitivity;
    exposure = fExposure / max(exposure, 0.00001);

    //we'll use the alpha to determine the white point
    //after tonemapping we'll brighten the image to reach the white point
    col = tonemap_hable(col, exposure);
    col = bWhiteFix ? col / max(col.a, 0.000001) : col;
    
    return float4(col.rgb, 1.0);
}

technique11 Effect <string UIName = "Magic";> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Effect()));
    }
}
