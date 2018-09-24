//
//  Shader.metal
//  GPUOperation
//
//  Created by Shuhei Yukawa on 2018/09/20.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

#include <metal_stdlib>
using namespace metal;

kernel void matrixMultiply(constant float *matA [[buffer(0)]],
                           constant float *matB [[buffer(1)]],
                           device float *outMat [[buffer(2)]],
                           constant int &row [[buffer(3)]],
                           constant int &line [[buffer(4)]],
                           constant int &raw [[buffer(5)]],
                           constant int &maxSize [[buffer(6)]],
                           uint2 gid [[thread_position_in_grid]])
{
    if (maxSize < gid.x) {
        return;
    }
    int w = maxSize / row;
    int x = gid.x / w;
    int y = gid.x % line;
    for (int i = 0; i < raw; i++) {
        outMat[gid.x] += matA[(x * raw)+ i] * matB[y + (w * i)];
    }
}
