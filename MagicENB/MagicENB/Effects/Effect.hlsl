//#region Preprocessor

#include "MagicENB/Utils/Common.hlsl"
#include "MagicENB/Utils/ACES.hlsl"

//#endregion

//#region Constants

//#endregion

//#region Uniforms

float Exposure
<
	string UIName = "Exposure";
	string UIWidget = "spinner";
	float UIMin = -3.0;
	float UIMax = 3.0;
> = 0.0;

float BloomAmount
<
	string UIName = "Bloom Amount";
	string UIWidget = "spinner";
	float UIMin = 0.0;
	float UIMax = 1.0;
> = 1.0;

// TODO: Document these parameters.
/*
 * Skyrim SE parameters.
 */
float4 Params01[7];

/*
 * x: Bloom amount.
 * y: Lens amount.
 * z: Unused.
 * w: Unused.
 */
float4 ENBParams01;

//#endregion

//#region Textures

Texture2D TextureColor;
Texture2D TextureBloom;
Texture2D TextureLens;
Texture2D TextureDepth;
Texture2D TextureAdaptation;
Texture2D TextureAperture;
Texture2D TexturePalette;

//#endregion

//#region Shaders

float4 MainPS(float4 p : SV_POSITION, float2 uv : TEXCOORD) : SV_TARGET
{
	float3 color = TextureColor.Sample(Point, uv).rgb;

	float3 bloom = TextureBloom.Sample(Linear, uv).rgb;
	float bloomAmount = 1.0 + BloomAmount * ENBParams01.x;
	color = lerp(color, bloom, log2(bloomAmount));

	// float bloomAmount = BloomAmount * ENBParams01.x;
	// color += bloom * bloomAmount;

	float adapt = TextureAdaptation.Sample(Point, uv).x;
	color.rgb *= exp2(Exposure) / max(adapt, 0.0001);

	color = ACESFitted(color);
	color = pow(abs(color), GammaInv);
	return float4(color, 1.0);
}

//#endregion

//#region Technique

technique11 Draw <string UIName = "MagicENB";>
{
	pass
	{
		SetVertexShader(CompileShader(vs_5_0, PostProcessVS()));
		SetPixelShader(CompileShader(ps_5_0, MainPS()));
	}
}

//#endregion