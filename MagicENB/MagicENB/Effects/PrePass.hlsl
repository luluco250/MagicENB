//#region Preprocessor

#include "MagicENB/Utils/Common.hlsl"

#define SMAA_RT_METRICS float4(GetPixelSize(), GetScreenResolution())
#define SMAA_HLSL_4_1
#define SMAA_PRESET_ULTRA
#include "MagicENB/Utils/SMAA.hlsl"

//#endregion

//#region Constants

static const int DebugMode_Disabled = 0;
static const int DebugMode_ShowEdges = 1;
static const int DebugMode_ShowBlend = 2;

//#endregion

//#region Uniforms

int DebugMode
<
	string UIName = "Debug Mode";
	string UIWidget = "slider";
	int UIMin = 0;
	int UIMax = 2;
> = 0;

//#endregion

//#region Textures

/*
 * The scene color.
 *
 * Size: Screen Resolution
 * Format: RGBA16F
 */
Texture2D TextureOriginal;

/*
 * A backbuffer that contains the result of the previous technique, except when
 * the previous technique uses a temporary render target.
 *
 * Size: 1024x1024
 * Format: RGBA64F
 */
Texture2D TextureColor;

/*
 * The scene depth.
 *
 * Size: Screen Resolution
 * Format: R32F
 */
Texture2D TextureDepth;

// TODO: Document TextureJitter.
/*
 * Blue noise.
 *
 * Size: Unknown
 * Format: Unknown
 */
Texture2D TextureJitter; //blue noise

// TODO: Document TextureMask.
/*
 * General mask for skinned objects and amount of sub-surface scattering.
 * Alpha channel indicates objects that have skin:
 *   0.0: Skinned.
 *   1.0: Non-skinned.
 *
 * Size: Screen Resolution (needs confirmation)
 * Format: Unknown
 */
Texture2D TextureMask; //alpha channel is mask for skinned objects (less than 1) and amount of sss

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
 * Format: RGBA16
 */
Texture2D RenderTargetRGBA64;

/*
 * Temporary render target.
 *
 * Size: Screen Resolution
 * Format: RGBA16F
 */
Texture2D RenderTargetRGBA64F;

/*
 * Temporary render target.
 *
 * Size: Screen Resolution
 * Format: R16F
 */
Texture2D RenderTargetR16F;

/*
 * Temporary render target.
 *
 * Size: Screen Resolution
 * Format: R32F
 */
Texture2D RenderTargetR32F;

/*
 * Temporary render target.
 *
 * Size: Screen Resolution
 * Format: RGB32F
 */
Texture2D RenderTargetRGB32F;

Texture2D AreaTex
<
	string ResourceName = "MagicENB/Textures/SMAA_AreaTex.dds";
>;

Texture2D SearchTex
<
	string ResourceName = "MagicENB/Textures/SMAA_SearchTex.dds";
>;

#define ColorTexGamma TextureColor
#define ColorTex RenderTargetRGBA64F
#define DepthTex TextureDepth
#define EdgesTex RenderTargetRGB32F
#define BlendTex RenderTargetRGBA32

//#endregion

//#region States

DepthStencilState DisableDepthStencil
{
    DepthEnable = FALSE;
    StencilEnable = FALSE;
};

DepthStencilState DisableDepthReplaceStencil
{
    DepthEnable = FALSE;
    StencilEnable = TRUE;
    FrontFaceStencilPass = REPLACE;
};

DepthStencilState DisableDepthUseStencil
{
    DepthEnable = FALSE;
    StencilEnable = TRUE;
    FrontFaceStencilFunc = EQUAL;
};

BlendState Blend
{
    AlphaToCoverageEnable = FALSE;
    BlendEnable[0] = TRUE;
    SrcBlend = BLEND_FACTOR;
    DestBlend = INV_BLEND_FACTOR;
    BlendOp = ADD;
};

BlendState NoBlending
{
    AlphaToCoverageEnable = FALSE;
    BlendEnable[0] = FALSE;
};

//#endregion

//#region Shaders

void EdgeDetectionVS(
	float3 v : POSITION,
	out float4 p : SV_POSITION,
	inout float2 uv : TEXCOORD0,
	out float4 offset[3] : TEXCOORD1)
{
	PostProcessVS(v, p, uv);
	SMAAEdgeDetectionVS(uv, offset);
}

float2 LumaEdgeDetectionPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD0,
	float4 offset[3] : TEXCOORD1) : SV_TARGET
{
	return SMAALumaEdgeDetectionPS(uv, offset, ColorTexGamma);
}

void BlendingWeightCalculationVS(
	float3 v : POSITION,
	out float4 p : SV_POSITION,
	inout float2 uv : TEXCOORD0,
	inout float2 pixuv : TEXCOORD1,
	out float4 offset[3] : TEXCOORD2)
{
	PostProcessVS(v, p, uv);
	SMAABlendingWeightCalculationVS(uv, pixuv, offset);
}

float4 BlendingWeightCalculationPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD0,
	float2 pixuv : TEXCOORD1,
	float4 offset[3] : TEXCOORD2) : SV_TARGET
{
	return SMAABlendingWeightCalculationPS(
		uv,
		pixuv,
		offset,
		EdgesTex,
		AreaTex,
		SearchTex,
		0);
}

void NeighborhoodBlendingVS(
	float3 v : POSITION,
	out float4 p : SV_POSITION,
	inout float2 uv : TEXCOORD0,
	out float4 offset : TEXCOORD1)
{
	PostProcessVS(v, p, uv);
	SMAANeighborhoodBlendingVS(uv, offset);
}

float4 NeighborhoodBlendingPS(
	float4 p : SV_POSITION,
	float2 uv : TEXCOORD0,
	float4 offset : TEXCOORD1) : SV_TARGET
{
	switch (DebugMode)
	{
		default:
		case DebugMode_Disabled:
			return SMAANeighborhoodBlendingPS(
				uv,
				offset,
				ColorTex,
				BlendTex);
		case DebugMode_ShowEdges:
			return EdgesTex.Sample(Point, uv);
		case DebugMode_ShowBlend:
			return BlendTex.Sample(Point, uv);
	}
}

//#endregion

//#region Techniques

technique11 MagicENB
<
	string UIName = "MagicENB";
	string RenderTarget = NAMEOF(ColorTex);
>
{
	pass GammaToLinear
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, GammaToLinearPS(
			ColorTexGamma,
			Point)));
	}
}

technique11 MagicENB1 <string RenderTarget = NAMEOF(EdgesTex);>
{
	pass EdgeDetection
	{
		SetVertexShader(CompileShader(vs_5_0, EdgeDetectionVS()));
		SetPixelShader(CompileShader(ps_5_0, LumaEdgeDetectionPS()));
	}
}

technique11 MagicENB2 <string RenderTarget = NAMEOF(BlendTex);>
{
	pass BlendingWeightCalculation
	{
		SetVertexShader(CompileShader(vs_5_0, BlendingWeightCalculationVS()));
		SetPixelShader(CompileShader(ps_5_0, BlendingWeightCalculationPS()));
	}
}

technique11 MagicENB3 //<string RenderTarget = "RenderTargetRGBA32";>
{
	pass NeighborhoodBlending
	{
		SetVertexShader(CompileShader(vs_5_0, NeighborhoodBlendingVS()));
		SetPixelShader(CompileShader(ps_5_0, NeighborhoodBlendingPS()));
	}
}

//#endregion