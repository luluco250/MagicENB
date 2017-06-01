#include "Magic/Common.fxh"

uniform int iSMAA_EdgeDetectionType <
    string UIName = "SMAA: Edge Detection Type";
    string UIWidget = "quality";
    int UIMin = 0;
    int UIMax = 2;
> = 1; //Luminance, Color, Depth

uniform float fSMAA_EdgeDetectionThreshold <
    string UIName = "SMAA: Edge Detection Threshold";
    string UIWidget = "spinner";
    float UIMin = 0.05;
    float UIMax = 0.20;
> = 0.10;

uniform int iSMAA_MaxSearchSteps <
    string UIName = "SMAA: Max Search Steps";
    string UIWidget = "spinner";
    int UIMin = 0;
    int UIMax = 98;
> = 98;

uniform int iSMAA_MaxSearchStepsDiagonal <
    string UIName = "SMAA: Max Search Steps Diagonal";
    string UIWidget = "spinner";
    int UIMin = 0;
    int UIMax = 16;
> = 16;

uniform int iSMAA_CornerRounding <
    string UIName = "SMAA: Corner Rounding";
    string UIWidget = "spinner";
    int UIMin = 0;
    int UIMax = 100;
> = 0;

uniform int iSMAA_DebugOutput <
    string UIName = "SMAA: Debug Output";
    string UIWidget = "quality";
    int UIMin = 0;
    int UIMax = 2;
> = 0;

Texture2D areaTex <string ResourceName = "Textures/AreaTex.dds";>;
Texture2D searchTex <string ResourceName = "Textures/SearchTex.dds";>;

//SMAA setup
#define SMAA_RT_METRICS float4(pixelsize.x, pixelsize.y, resolution.x, resolution.y)
//#define SMAA_CUSTOM_SL 1
#define SMAA_HLSL_4_1 1
#define SMAA_PRESET_CUSTOM 1

#define SMAA_THRESHOLD fSMAA_EdgeDetectionThreshold
#define SMAA_MAX_SEARCH_STEPS iSMAA_MaxSearchSteps
#define SMAA_MAX_SEARCH_STEPS_DIAGONAL iSMAA_MaxSearchStepsDiagonal
#define SMAA_CORNER_ROUNDING iSMAA_CornerRounding

#include "SMAA/SMAA.fxh"


uniform float fSigma <
    string UIName = "Blur Sigma";
    string UIWidget = "spinner";
    float UIMin = 0.0;
    float UIMax = 100.0;
> = 1.0;

uniform float fScale <
    string UIName = "Blur Scale";
    string UIWidget = "spinner";
    float UIMin = 1.0;
    float UIMax = 10.0;
> = 1.0;

#define BOX_BLUR_SAMPLES 3

static const float2 box_centered_offset = BOX_BLUR_SAMPLES * 0.5;

float3 box_blur(Texture2D tex, float2 uv) {
    float3 col = tex.Sample(Sampler_Linear, uv).rgb;
    float accum = 1.0;

    [unroll]
    for (int x = 1; x < BOX_BLUR_SAMPLES; ++x) {
        [unroll]
        for (int y = 1; y < BOX_BLUR_SAMPLES; ++y) {
            col += tex.Sample(Sampler_Linear, uv + pixelsize * (float2(x, y) - box_centered_offset)).rgb;
            ++accum;
        }
    }

    return col / accum;
}

uniform float fVignette_Intensity <
	string UIName = "Vignette Intensity";
	string UIWidget = "spinner";
	float UIMin = 0;
	float UIMax = 3;
> = 1.0;

uniform float fVignette_Sharpness <
	string UIName = "Vignette Sharpness";
	string UIWidget = "spinner";
	float UIMin = 0.001;
	float UIMax = 10;
> = 1.0;

void Vignette(inout float3 col, float2 uv) {
	col *= 1.0 - pow(distance(uv, 0.5) * fVignette_Intensity, fVignette_Sharpness);
}

float4 PS_PostPass(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    float3 col = TextureColor.Sample(Sampler_Point, uv).rgb;
    Vignette(col, uv);
    return float4(col, 1.0);
}

technique11 Magic <string UIName = "Magic";> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_PostPass()));
    }
}
