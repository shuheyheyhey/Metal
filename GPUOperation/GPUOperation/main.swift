//
//  main.swift
//  GPUOperation
//
//  Created by Shuhei Yukawa on 2018/09/20.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation

let inputMat:[Float] = [ 1, 2, 3, 4,
                         5, 6, 7, 8,
                         9, 10, 11, 12,
                         13, 14, 15, 16,
                         17, 18, 19, 20]
let matA = Matrix(inputMat, x: 4, y: 5)

let inputVec:[Float] = [ 1, 5, 9,
                         2, 6, 10,
                         3, 7, 11,
                         4, 8, 12]
let matB = Matrix(inputVec, x: 3, y: 4)

let vectorCaluclator = VectorCaluclator()
vectorCaluclator.compute(rInputMatrix: matA, lInputMatrix: matB)
print(vectorCaluclator.output)
