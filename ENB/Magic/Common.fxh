#ifndef COMMON_FXH
#define COMMON_FXH

//Preprocessor Magic

#define STR(X) #X
#define TOSTRING(X) STR(X)

//Configurations

#define BLUR_SAMPLES 5

//ENB Parameters
//x = generic timer in range 0..1, period of 16777216 ms (4.6 hours), y = average fps, w = frame time elapsed (in seconds)
float4	Timer;
//x = Width, y = 1/Width, z = aspect, w = 1/aspect, aspect is Width/Height
float4	ScreenSize;
//changes in range 0..1, 0 means full quality, 1 lowest dynamic quality (0.33, 0.66 are limits for quality levels)
float	AdaptiveQuality;
//x = current weather index, y = outgoing weather index, z = weather transition, w = time of the day in 24 standart hours. Weather index is value from weather ini file, for example WEATHER002 means index==2, but index==0 means that weather not captured.
float4	Weather;
//x = dawn, y = sunrise, z = day, w = sunset. Interpolators range from 0..1
float4	TimeOfDay1;
//x = dusk, y = night. Interpolators range from 0..1
float4	TimeOfDay2;
//changes in range 0..1, 0 means that night time, 1 - day time
float	ENightDayFactor;
//changes 0 or 1. 0 means that exterior, 1 - interior
float	EInteriorFactor;

//ENB Debug Parameters
//keyboard controlled temporary variables. Press and hold key 1,2,3...8 together with PageUp or PageDown to modify. By default all set to 1.0
float4	tempF1; //0,1,2,3
float4	tempF2; //5,6,7,8
float4	tempF3; //9,0
// xy = cursor position in range 0..1 of screen;
// z = is shader editor window active;
// w = mouse buttons with values 0..7 as follows:
//    0 = none
//    1 = left
//    2 = right
//    3 = left+right
//    4 = middle
//    5 = left+middle
//    6 = right+middle
//    7 = left+right+middle (or rather cat is sitting on your mouse)
float4	tempInfo1;
// xy = cursor position of previous left mouse button click
// zw = cursor position of previous right mouse button click
float4	tempInfo2;

//Game and Mod Parameters
float4 Params01[7];
float4 ENBParams01;

//Textures

//Common, almost every effect file uses these
Texture2D TextureColor;
Texture2D TextureOriginal;
Texture2D TextureDepth;

//enbeffect.fx
Texture2D TextureBloom;
Texture2D TextureLens;

//enbeffect.fx, enbbloom.fx, enblens.fx
Texture2D TextureDownsampled;

//enbdepthoffield.fx, enbeffect.fx
Texture2D TextureAdaptation;

//enbbloom.fx, enbdepthoffield.fx, enbeffect.fx, enblens.fx
Texture2D TextureAperture;

//enbbloom.fx, enblens.fx
Texture2D RenderTarget1024;    //RGBA16F 1024x1024
Texture2D RenderTarget512;     //RGBA16F  512x512
Texture2D RenderTarget256;     //RGBA16F  256x256
Texture2D RenderTarget128;     //RGBA16F  128x128
Texture2D RenderTarget64;      //RGBA16F   64x64
Texture2D RenderTarget32;      //RGBA16F   32x32
Texture2D RenderTarget16;      //RGBA16F   16x16

//enbdepthoffield.fx, enbbloom.fx, enblens.fx
Texture2D RenderTargetRGBA32;  //RGBA32 ScreenSize
Texture2D RenderTargetRGBA64F; //RGBA64F ScreenSize

//enbadaptation.fx, enbdepthoffield.fx
Texture2D TextureCurrent; //RGBA16F or RGB11 256x256 or 16x16
Texture2D TexturePrevious; //R32F 1x1

//enbdepthoffield.fx
Texture2D TextureFocus;
Texture2D RenderTargetRGB32F;

//enbdepthoffield.fx, enbeffectpostpass.fx
Texture2D RenderTargetRGBA64;
Texture2D RenderTargetR16F;
Texture2D RenderTargetR32F;

//Samplers
SamplerState Sampler_Linear {
    Filter = MIN_MAG_MIP_LINEAR;
    AddressU = Clamp;
    AddressV = Clamp;
};

SamplerState Sampler_Point {
    Filter = MIN_MAG_MIP_POINT;
    AddressU = Clamp;
    AddressV = Clamp;
};

//Helper Variables

static const float2 resolution = float2(ScreenSize.x, ScreenSize.x * ScreenSize.w);
static const float2 pixelsize = 1.0 / resolution;

static const float pi = 3.1415926535897932384626433832795;
static const float doublepi = 6.283185307179586476925286766559;

//Helper Functions

float get_lum(float3 col) {
    return max(col.r, max(col.g, col.b));
}

float get_average(float3 col) {
    return dot(col, 0.333); //1.0 / 3.0
}

float get_luma(float3 col) {
    return dot(col, float3(0.299, 0.587, 0.114));
}

float get_luma_linear(float3 col) {
    return dot(col, float3(0.2126, 0.7152, 0.0722));
}

float3 clamp_magnitude(float3 v, float m) {
    float len = length(v);
    return (v / len) * clamp(len, -m, m);
}

//static const float sigma = float(BLUR_SAMPLES) / 2.0;
static const float sigma = sqrt(BLUR_SAMPLES);

//Taken from here: https://en.wikipedia.org/wiki/Gaussian_blur#Mathematics
float gaussian_function(float2 i) {
    return (1.0 / (doublepi * sigma * sigma)) * exp(-((i.x * i.x + i.y * i.y) / (2.0 * sigma * sigma)));
}

static const float2 centered_offset = float(BLUR_SAMPLES) * 0.5;

float3 gaussian_blur(Texture2D tex, float2 uv, float scale) {    
    float2 ps = pixelsize * scale;

    float2 coord = 0.0;
    float weight = gaussian_function(coord);
    float3 col = tex.Sample(Sampler_Linear, uv).rgb * weight;
    float accum = weight;

    [unroll]
    for (int x = 1; x <= BLUR_SAMPLES; ++x) {
        [unroll]
        for (int y = 1; y <= BLUR_SAMPLES; ++y) {
            coord = float2(x, y) - centered_offset;
            weight = gaussian_function(coord);
            col += tex.Sample(Sampler_Linear, uv + ps * coord).rgb * weight;
            accum += weight;
        }
    }

    return col / accum;
}

//Helper Shaders

void VS_PostProcess(
    float3 vertex	: POSITION,
    out float4 pos	: SV_POSITION,
    inout float2 uv	: TEXCOORD
) {
    pos = float4(vertex, 1.0);
}

float4 PS_DisplayTexture(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD,
	uniform Texture2D input
) : SV_Target {
	return input.Sample(Sampler_Point, uv);
}

float4 PS_ClearTexture(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD
) : SV_Target {
	return 0;
}

static const float gamma = 2.2;
static const float gamma_inverse = 1.0 / gamma;

float4 PS_GammaToLinear(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD,
	uniform Texture2D input
) : SV_Target {
	float4 col = input.Sample(Sampler_Point, uv);
	col.rgb = pow(col.rgb, gamma_inverse);
	return col;
}

float4 PS_LinearToGamma(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD,
	uniform Texture2D input
) : SV_Target {
	float4 col = input.Sample(Sampler_Point, uv);
	col.rgb = pow(col.rgb, gamma);
	return col;
}

#endif //ENB_COMMON_FXH