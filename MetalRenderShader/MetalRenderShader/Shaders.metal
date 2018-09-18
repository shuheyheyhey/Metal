//
//  default.metal
//  MetalRenderShader
//
//  Created by Shuhei Yukawa on 2018/09/05.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

struct ColorInOut
{
    float4 position [[ position ]];
};

vertex ColorInOut vertexShader(device float4 *positions [[ buffer(0) ]],
                               uint           vid       [[ vertex_id ]])
{
    ColorInOut out;
    out.position = positions[vid];
    return out;
}

fragment float4 fragmentShader(ColorInOut in [[ stage_in ]],
                               device float4 *buffer [[ buffer(0)]])
{
    return buffer[0];
}
