//#region Preprocessor

#include "MagicENB/Utils/Common.hlsl"

//#endregion

//#region Constants

static const float DownSampleSize = 256.0;
static const float DownSampleSizeInv = rcp(DownSampleSize);

static const float DrawSize = 16.0;
static const float DrawSizeInv = rcp(DrawSize);

static const int BlurSamples = 16;

static const float AdaptationScale = 10.0;

//#endregion

//#region Uniforms

/*
 * x: AdaptationMin
 * y: AdaptationMax
 * z: AdaptationSensitivity
 * w: AdaptationTime * time elapsed
 */
float4 AdaptationParameters;

//#endregion

//#region Textures

Texture2D TextureCurrent;
Texture2D TexturePrevious;

//#endregion

//#region Shaders

/*
 * TextureCurrent: 256x256 RGBA16F or RG11B10
 * Output: 16x16 R32F
 */
float DownSamplePS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float3 color = BoxBlur2D(
		TextureCurrent,
		uv,
		DownSampleSizeInv * (DownSampleSize * DrawSizeInv),
		BlurSamples);

	float gray = dot(color, LumaWeights);
	return gray;
}

/*
 * TextureCurrent: 16x16 R32F
 * TexturePrevious: 1x1 R32F
 * Output: 1x1 R32F
 */
float DrawPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float adapt = BoxBlur2D(TextureCurrent, uv, DrawSizeInv, BlurSamples).x;
	adapt *= AdaptationParameters.z * AdaptationScale;
	//adapt = ApplyContrast(adapt, AdaptationParameters.z * 2.0);

	//adapt *= 1.0 + AdaptationParameters.z;
	adapt = clamp(adapt, AdaptationParameters.x, AdaptationParameters.y);

	float last =  TexturePrevious.Sample(Point, 0).x;
	adapt = lerp(last, adapt, AdaptationParameters.w);

	return adapt;
}

//#endregion

//#region Technique

technique11 Downsample
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, DownSamplePS()));
	}
}

technique11 Draw
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, DrawPS()));
	}
}

//#endregion