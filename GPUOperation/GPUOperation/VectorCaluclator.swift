//
//  GPUOperation.swift
//  GPUOperation
//
//  Created by Shuhei Yukawa on 2018/09/20.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation
import Metal

struct ThreadSize {
    var threadCountPerGroup: MTLSize
    var threadGroupCount: MTLSize
    
    public init(threadCountPerGroup: MTLSize, threadGroupCount: MTLSize) {
        self.threadGroupCount = threadCountPerGroup
        self.threadCountPerGroup = threadGroupCount
    }
}

struct Matrix {
    var matrix: [Float]
    var x: Int
    var y: Int
    
    public init(_ matrix: [Float], x: Int, y: Int) {
        self.matrix = matrix
        self.x = x
        self.y = y
    }
}

class VectorCaluclator {
    // 出力用
    var output: Matrix!
    
    // GPU を抽象化したプロトコル
    private let device = MTLCreateSystemDefaultDevice()!
    
    // GPU で実行するコマンドを格納するコンテナ
    private let commandQueue: MTLCommandQueue!
    
    // コンピュートシェダーを実行するためんのパイプライン
    private var computePipeline: MTLComputePipelineState!
    
    init() {
        self.commandQueue = device.makeCommandQueue()!
        self.setUpPipeline()
    }
    
    public func compute(rInputMatrix: Matrix, lInputMatrix: Matrix) {
        // アウトプット用
        var maxSize = rInputMatrix.y * lInputMatrix.x
        var outputMatrix: [Float] = Array.init(repeating: 0.0, count: maxSize)
        // コマンドバッファを作成
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        // コンピュートコマンドエンコーダを作成
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        // コンピュートパイプラインをセット
        encoder.setComputePipelineState(self.computePipeline)
        
        // 値をセット
        let inRawMat = self.makeMTLBuffer(rInputMatrix.matrix)
        let inLineMat = self.makeMTLBuffer(lInputMatrix.matrix)
        let outMat = self.makeMTLBuffer(outputMatrix)
        var raw = rInputMatrix.x //「行」のみだが「列」も同じ値という体で
        var row = rInputMatrix.y // 行の高さ
        var line = lInputMatrix.x // 列の幅
        
        
        encoder.setBuffer(inRawMat, offset: 0, index: 0)
        encoder.setBuffer(inLineMat, offset: 0, index: 1)
        encoder.setBuffer(outMat, offset: 0, index: 2)
        encoder.setBytes(&row, length: 1 * MemoryLayout<Int>.size, index: 3)
        encoder.setBytes(&line, length: 1 * MemoryLayout<Int>.size, index: 4)
        encoder.setBytes(&raw, length: 1 * MemoryLayout<Int>.size, index: 5)
        encoder.setBytes(&maxSize, length: 1 * MemoryLayout<Int>.size, index: 6)
        
        // グリッドサイズを計算するディスパッチコールをエンコード
        let thread = self.createThreadSize(w: rInputMatrix.x, h: lInputMatrix.y)
        encoder.dispatchThreadgroups(thread.threadGroupCount, threadsPerThreadgroup: thread.threadCountPerGroup)
        
        encoder.endEncoding()
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        // 結果格納
        let p = outMat.contents().bindMemory(to: Float.self, capacity: inputVec.count)
        for i in 0..<maxSize {
            outputMatrix[i] = p[i]
        }
        self.output = Matrix(outputMatrix, x: lInputMatrix.x, y: rInputMatrix.y)
    }
    
    private func setUpPipeline() {
        guard let library = device.makeDefaultLibrary() else {
            fatalError("Could not get library.")
        }
        guard let function = library.makeFunction(name: "matrixMultiply") else {
            fatalError("Could not make function.")
        }
        do {
            self.computePipeline = try device.makeComputePipelineState(function: function)
        } catch let err {
            fatalError(err.localizedDescription)
        }
    }
    
    private func makeMTLBuffer(_ data: [Float]) -> MTLBuffer {
        let size = data.count * MemoryLayout<Float>.size
        let buffer = self.device.makeBuffer(bytes: data, length: size)
        return buffer!
    }
    
    private func createThreadSize(w: Int, h: Int) -> ThreadSize {
        // スレッドグループ数
        var threadGroupWidth = 1
        var threadGroupHeight = 1
        if w * h > self.computePipeline.threadExecutionWidth {
            // 同時実行可能数よりも大きい場合は X x Y のグループを作成する
            threadGroupWidth = ((w * h) / self.computePipeline.threadExecutionWidth) / 2
            threadGroupHeight = ((w * h) / self.computePipeline.threadExecutionWidth) / 2
        }
        let threadGroupCount = MTLSize(width: threadGroupWidth, height: threadGroupHeight, depth: 1)
        
        // スレッドグループ内でのスレッド数の決定
        let threadWidthPerGroup = self.computePipeline.threadExecutionWidth
        let threadHeightPerGroup = self.computePipeline.maxTotalThreadsPerThreadgroup / threadWidthPerGroup
        let threadCountPerGroup = MTLSize(
            width:  threadWidthPerGroup,
            height: threadHeightPerGroup,
            depth: 1
        )
        
        return ThreadSize(threadCountPerGroup: threadCountPerGroup, threadGroupCount: threadGroupCount)
    }
    
}
