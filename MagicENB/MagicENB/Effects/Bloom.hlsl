//#region Preprocessor

#include "MagicENB/Utils/Common.hlsl"

//#endregion

//#region Constants

static const int BlurSamples = 13;
static const float2 Horizontal = float2(1.0, 0.0);
static const float2 Vertical = float2(0.0, 1.0);

//#endregion

//#region Uniforms

float BlurScale
<
	string UIName = "Blur Scale";
	string UIWidget = "spinner";
	float UIMin = 1.0;
	float UIMax = 10.0;
> = 1.0;

float BlurSigma
<
	string UIName = "Blur Sigma";
	string UIWidget = "spinner";
	float UIMin = 1.0;
	float UIMax = 10.0;
> = 1.0;

//#endregion

//#region Textures

/*
 * The scene color, downsampled.
 *
 * Size: 1024x1024
 * Format: RGBA64F or RG11B10F
 */
Texture2D TextureDownsampled;

/*
 * A backbuffer that contains the result of the previous technique, except when
 * the previous technique uses a temporary render target.
 *
 * Size: 1024x1024
 * Format: RGBA64F
 */
Texture2D TextureColor;

/*
 * The scene color.
 *
 * Size: Screen Resolution
 * Format: RGBA16F or RG11B10F
 */
Texture2D TextureOriginal;

/*
 * The scene depth.
 *
 * Size: Screen Resolution
 * Format: R32F
 */
Texture2D TextureDepth;

/*
 * Camera lens aperture, calculated in depth of field.
 *
 * Size: 1x1
 * Format: R32F
 */
Texture2D TextureAperture;

/*
 * Temporary render target.
 *
 * Size: 1024x1024
 * Format: RGBA16F
 */
Texture2D RenderTarget1024;

/*
 * Temporary render target.
 *
 * Size: 512x512
 * Format: RGBA16F
 */
Texture2D RenderTarget512;

/*
 * Temporary render target.
 *
 * Size: 256x256
 * Format: RGBA16F
 */
Texture2D RenderTarget256;

/*
 * Temporary render target.
 *
 * Size: 128x128
 * Format: RGBA16F
 */
Texture2D RenderTarget128;

/*
 * Temporary render target.
 *
 * Size: 64x64
 * Format: RGBA16F
 */
Texture2D RenderTarget64;

/*
 * Temporary render target.
 *
 * Size: 32x32
 * Format: RGBA16F
 */
Texture2D RenderTarget32;

/*
 * Temporary render target.
 *
 * Size: 16x16
 * Format: RGBA16F
 */
Texture2D RenderTarget16;

/*
 * Temporary render target.
 *
 * Size: Screen Resolution
 * Format: RGBA8
 */
Texture2D RenderTargetRGBA32;

/*
 * Temporary render target.
 *
 * Size: Screen Resolution
 * Format: RGBA16F
 */
Texture2D RenderTargetRGBA64F;

//#endregion

//#region Functions

//#endregion

//#region Shaders

float4 BlurPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD,
	uniform Texture2D tex,
	uniform float2 dir) : SV_TARGET
{
	dir.y *= GetAspectRatio();
	float3 color = GaussianBlur1D(
		tex,
		uv,
		dir * BlurScale,
		BlurSamples,
		BlurSigma);

	return float4(color, 1.0);
}

float4 BlendPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float3 bloom = RenderTarget1024.Sample(Linear, uv).rgb;
	bloom += RenderTarget512.Sample(Linear, uv).rgb;
	bloom += RenderTarget256.Sample(Linear, uv).rgb;
	bloom += RenderTarget128.Sample(Linear, uv).rgb;
	bloom += RenderTarget64.Sample(Linear, uv).rgb;
	bloom += RenderTarget32.Sample(Linear, uv).rgb;
	bloom += RenderTarget16.Sample(Linear, uv).rgb;

	bloom /= 7;
	return float4(bloom, 1.0);
}

//#endregion

//#region Techniques

technique11 MagicENB_Bloom <string UIName = "MagicENB";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureDownsampled,
			Horizontal * rcp(1024.0))));
	}
}

technique11 MagicENB_Bloom1 <string RenderTarget = "RenderTarget1024";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(1024.0))));
	}
}

technique11 MagicENB_Bloom2
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			RenderTarget1024,
			Horizontal * rcp(512.0))));
	}
}

technique11 MagicENB_Bloom3 <string RenderTarget = "RenderTarget512";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(512.0))));
	}
}

technique11 MagicENB_Bloom4
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			RenderTarget512,
			Horizontal * rcp(256.0))));
	}
}

technique11 MagicENB_Bloom5 <string RenderTarget = "RenderTarget256";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(256.0))));
	}
}

technique11 MagicENB_Bloom6
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			RenderTarget256,
			Horizontal * rcp(128.0))));
	}
}

technique11 MagicENB_Bloom7 <string RenderTarget = "RenderTarget128";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(128.0))));
	}
}

technique11 MagicENB_Bloom8
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			RenderTarget128,
			Horizontal * rcp(64.0))));
	}
}

technique11 MagicENB_Bloom9 <string RenderTarget = "RenderTarget64";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(64.0))));
	}
}

technique11 MagicENB_Bloom10
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			RenderTarget64,
			Horizontal * rcp(32.0))));
	}
}

technique11 MagicENB_Bloom11 <string RenderTarget = "RenderTarget32";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(32.0))));
	}
}

technique11 MagicENB_Bloom12
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			RenderTarget32,
			Horizontal * rcp(16.0))));
	}
}

technique11 MagicENB_Bloom13 <string RenderTarget = "RenderTarget16";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlurPS(
			TextureColor,
			Vertical * rcp(16.0))));
	}
}

technique11 MagicENB_Bloom14
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, BlendPS()));
	}
}

//#endregion