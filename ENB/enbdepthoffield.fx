#include "Magic/Common.fxh"
#include "Magic/Preprocessor.fxh"

//This comes before bloom, effect and postpass
//Used to be called enbprepass.fx for a reason
//You can do more than just DoF here

//Let's setup SMAA

Texture2D areaTex <string ResourceName = "Magic/Textures/AreaTex.dds";>;
Texture2D searchTex <string ResourceName = "Magic/Textures/SearchTex.dds";>;

#define SMAA_RT_METRICS float4(pixelsize, resolution)
#define SMAA_HLSL_4_1
#define SMAA_PRESET_ULTRA
#define SMAA_PREDICATION 1
#include "Magic/SMAA.fxh"

//ENB forces the use of these shaders on this file
//RenderTargets are not available to them

float4 PS_Aperture(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    return 0;
}

float4 PS_ReadFocus(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    return 0;
}

float4 PS_Focus(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    return 0;
}

//Now we can proceed with our own stuff
//RenderTargets now available

#define colorTexGamma TextureColor
#define colorTex RenderTargetRGBA64F
#define depthTex TextureDepth
#define edgesTex RenderTargetRGB32F
#define blendTex RenderTargetRGBA32

void VS_SMAA_EdgeDetection(
	float3 vertex			: POSITION,
	out float4 pos			: SV_POSITION,
	inout float2 uv			: TEXCOORD0,
	out float4 offset[3]	: TEXCOORD1
) {
	VS_PostProcess(vertex, pos, uv);
	SMAAEdgeDetectionVS(uv, offset);
}

float2 PS_SMAA_EdgeDetection(
	float4 pos			: SV_POSITION,
	float2 uv			: TEXCOORD0,
	float4 offset[3]	: TEXCOORD1
) : SV_Target {
	return SMAAColorEdgeDetectionPS(uv, offset, colorTexGamma, depthTex);
}

void VS_SMAA_BlendingWeightCalculation(
	float3 vertex			: POSITION,
	out float4 pos			: SV_POSITION,
	inout float2 uv			: TEXCOORD0,
	out float2 pixuv		: TEXCOORD1,
	out float4 offset[3]	: TEXCOORD2
) {
	VS_PostProcess(vertex, pos, uv);
	SMAABlendingWeightCalculationVS(uv, pixuv, offset);
}

float4 PS_SMAA_BlendingWeightCalculation(
	float4 pos			: SV_POSITION,
	float2 uv			: TEXCOORD0,
	float2 pixuv		: TEXCOORD1,
	float4 offset[3]	: TEXCOORD2
) : SV_Target {
	return SMAABlendingWeightCalculationPS(uv, pixuv, offset, edgesTex, areaTex, searchTex, 0);
}

void VS_SMAA_NeighborhoodBlending(
	float3 vertex		: POSITION,
	out float4 pos		: SV_POSITION,
	inout float2 uv		: TEXCOORD0,
	out float4 offset	: TEXCOORD1
) {
	VS_PostProcess(vertex, pos, uv);
	SMAANeighborhoodBlendingVS(uv, offset);
}

float4 PS_SMAA_NeighborhoodBlending(
	float4 pos		: SV_POSITION,
	float2 uv		: TEXCOORD0,
	float4 offset	: TEXCOORD1
) : SV_Target {
	return SMAANeighborhoodBlendingPS(uv, offset, colorTex, blendTex);
}

float4 PS_Magic(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    float3 col = TextureColor.Sample(Sampler_Point, uv).rgb;
    return float4(col, 1.0);
}

//Again, ENB forces us to do this

technique11 Aperture {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Aperture()));
    }
}

technique11 ReadFocus {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_ReadFocus()));
    }
}

technique11 Focus {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Focus()));
    }
}

//Now we can proceed with our own techniques

DepthStencilState DisableDepthStencil {
	DepthEnable = FALSE;
	StencilEnable = FALSE;
};

DepthStencilState DisableDepthReplaceStencil {
	DepthEnable = FALSE;
	StencilEnable = TRUE;
	FrontFaceStencilPass = REPLACE;
};

DepthStencilState DisableDepthUseStencil {
	DepthEnable = FALSE;
	StencilEnable = TRUE;
	FrontFaceStencilFunc = EQUAL;
};

BlendState Blend {
	AlphaToCoverageEnable = FALSE;
	BlendEnable[0] = TRUE;
	SrcBlend = BLEND_FACTOR;
	DestBlend = INV_BLEND_FACTOR;
	BlendOp = ADD;
};

BlendState NoBlending {
	AlphaToCoverageEnable = FALSE;
	BlendEnable[0] = FALSE;
};

//Make linear color texture

/*technique11 Magic <
	string UIName = "Magic";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_GammaToLinear(TextureColor)));
	}
}*/

technique11 Magic <
	string UIName = "Magic";
	string RenderTarget = TOSTRING(colorTex);
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_GammaToLinear(colorTexGamma)));
	}
}

//SMAA EdgeDetection
technique11 Magic1 <
	string RenderTarget = TOSTRING(edgesTex);
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_SMAA_EdgeDetection()));
        SetPixelShader(CompileShader(ps_5_0, PS_SMAA_EdgeDetection()));
    }
}

//SMAA BlendingWeightCalculation
technique11 Magic2 <
	string RenderTarget = TOSTRING(blendTex);
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_SMAA_BlendingWeightCalculation()));
		SetPixelShader(CompileShader(ps_5_0, PS_SMAA_BlendingWeightCalculation()));
	}
}

//SMAA NeighborhoodBlending
technique11 Magic3 {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_SMAA_NeighborhoodBlending()));
		SetPixelShader(CompileShader(ps_5_0, PS_SMAA_NeighborhoodBlending()));
	}
}

technique11 Magic4 {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_LinearToGamma(TextureColor)));
	}
}

/*technique11 Magic5 {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_DisplayTexture(edgesTex)));
	}
}*/
