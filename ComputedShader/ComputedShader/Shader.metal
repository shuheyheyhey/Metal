//
//  Shader.metal
//  ComputedShader
//
//  Created by Shuhei Yukawa on 2018/09/15.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

#include <metal_stdlib>
#include <simd/simd.h>
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
    float2 texCoords;
};

vertex ColorInOut vertexShader(device float4 *positions [[ buffer(0) ]],
                               device float2 *texCoords [[ buffer(1) ]],
                               uint vid [[ vertex_id ]])
{
    ColorInOut out;
    out.position = positions[vid];
    out.texCoords = texCoords[vid];
    return out;
}
                               
fragment float4 fragmentShader(ColorInOut in [[ stage_in ]],
                               texture2d<float> texture [[ texture(0) ]])
{
    constexpr sampler colorSampler;
    float4 color = texture.sample(colorSampler, in.texCoords);
    return color;
}

constant half3 kRec709Luma = half3(0.2126, 0.7152, 0.0722);

kernel void computedShader(texture2d<half, access::read>  inTexture  [[texture(0)]],
                           texture2d<half, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]])
{
    // Check if the pixel is within the bounds of the output texture
    if((gid.x >= outTexture.get_width()) || (gid.y >= outTexture.get_height()))
    {
        // Return early if the pixel is out of bounds
        return;
    }
    
    half4 inColor  = inTexture.read(gid);
    half  gray     = dot(inColor.rgb, kRec709Luma);
    outTexture.write(half4(gray, gray, gray, 1.0), gid);
}

