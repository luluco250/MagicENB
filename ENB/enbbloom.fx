#include "Magic/Common.fxh"
#include "Magic/Blur.fxh"

//Code ahead

uniform float fBloom_Curve <
    string UIName = "Bloom Curve";
    string UIWidget = "spinner";
    float UIMin = 1.0;
    float UIMax = 10.0;
> = 1.0;

float get_scale(float i) {
    //return pow(3, i);
    return pow(2, i + 1);
}

float4 PS_First(
    float4 pos  : SV_POSITION,
    float2 uv   : TEXCOORD
) : SV_Target {
    //float3 col = TextureDownsampled.Sample(Sampler_Linear, uv).rgb;
    float3 col = gaussian_blur(TextureDownsampled, uv, get_scale(1));
    col = pow(col, fBloom_Curve);
    return float4(col, 1.0);
}

float4 PS_Blur(
    float4 pos	: SV_POSITION,
    float2 uv	: TEXCOORD,
    uniform Texture2D input,
    uniform float scale
) : SV_Target {
    //float3 col = input.Sample(Sampler_Linear, uv).rgb;
    float3 col = gaussian_blur(input, uv, scale);
    return float4(col, 1.0);
}

float4 PS_Blend(
    float4 pos	: SV_POSITION,
    float2 uv	: TEXCOORD
) : SV_Target {
    float3 bloom  = RenderTarget1024.Sample(Sampler_Linear, uv).rgb;
		   bloom += RenderTarget512.Sample(Sampler_Linear, uv).rgb;
		   bloom += RenderTarget256.Sample(Sampler_Linear, uv).rgb;
		   bloom += RenderTarget128.Sample(Sampler_Linear, uv).rgb;
		   bloom += RenderTarget64.Sample(Sampler_Linear, uv).rgb;
		   bloom += RenderTarget32.Sample(Sampler_Linear, uv).rgb;
		   bloom += RenderTarget16.Sample(Sampler_Linear, uv).rgb;
	bloom /= 7;
	bloom = pow(bloom, 1.0 / fBloom_Curve);
	return float4(bloom, 1.0);
}

technique11 MagicBloom <
    string UIName = "Magic";
    string RenderTarget = "RenderTarget1024";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_First()));
    }
}

technique11 MagicBloom1 <
    string RenderTarget = "RenderTarget512";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget1024, get_scale(2))));
    }
}

technique11 MagicBloom2 <
    string RenderTarget = "RenderTarget256";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget512, get_scale(3))));
    }
}

technique11 MagicBloom3 <
    string RenderTarget = "RenderTarget128";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget256, get_scale(4))));
    }
}

technique11 MagicBloom4 <
    string RenderTarget = "RenderTarget64";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget128, get_scale(5))));
    }
}

technique11 MagicBloom5 <
    string RenderTarget = "RenderTarget32";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget64, get_scale(6))));
    }
}

technique11 MagicBloom6 <
    string RenderTarget = "RenderTarget16";
> {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blur(RenderTarget32, get_scale(7))));
    }
}

technique11 MagicBloom7 {
    pass {
        SetVertexShader(CompileShader(vs_5_0, VS_PostProcess()));
        SetPixelShader(CompileShader(ps_5_0, PS_Blend()));
    }
}
