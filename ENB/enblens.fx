#include "Magic/Common.fxh"
#include "Magic/Blur.fxh"

uniform float fScale <
	string UIName = "Blur Scale";
	string UIWidget = "spinner";
	float UIMin = 1.0;
	float UIMax = 100.0;
> = 1.0;

float get_scale(float i) {
	return pow(2, i + 1);
}

float4 PS_First(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD,
	uniform float2 scale
) : SV_Target {
	return float4(circle_blur(TextureDownsampled, 1.0 - uv, scale), 1.0);
}

float4 PS_Blur(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD,
	uniform Texture2D input,
	uniform float2 scale
) : SV_Target {
	return float4(circle_blur(input, uv, scale), 1.0);
}

float4 PS_Blend(
	float4 pos	: SV_POSITION,
	float2 uv	: TEXCOORD
) : SV_Target {
	float3 col  = RenderTarget1024.Sample(Sampler_Linear, uv).rgb;
		   col += RenderTarget512.Sample(Sampler_Linear, uv).rgb;
		   col += RenderTarget256.Sample(Sampler_Linear, uv).rgb;
		   col += RenderTarget128.Sample(Sampler_Linear, uv).rgb;
		   col += RenderTarget64.Sample(Sampler_Linear, uv).rgb;
		   col += RenderTarget32.Sample(Sampler_Linear, uv).rgb;
		   col += RenderTarget16.Sample(Sampler_Linear, uv).rgb;
	col /= 7.0;
	return float4(col, 1.0);
}

technique11 Magic <
	string UIName = "Magic";
	string RenderTarget = "RenderTarget1024";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_First(get_scale(1))));
	}
}

technique11 Magic1 <
	string RenderTarget = "RenderTarget512";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget1024, get_scale(2))));
	}
}

technique11 Magic2 <
	string RenderTarget = "RenderTarget256";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget512, get_scale(3))));
	}
}

technique11 Magic3 <
	string RenderTarget = "RenderTarget128";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget256, get_scale(4))));
	}
}

technique11 Magic4 <
	string RenderTarget = "RenderTarget64";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget128, get_scale(5))));
	}
}

technique11 Magic5 <
	string RenderTarget = "RenderTarget32";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget64, get_scale(6))));
	}
}

technique11 Magic6 <
	string RenderTarget = "RenderTarget16";
> {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget32, get_scale(7))));
	}
}

technique11 Magic7 {
	pass {
		SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
		SetPixelShader(CompileShader(ps_5_0, PS_Blend()));
	}
}
