//
//  ViewController.swift
//  MetalRenderShader
//
//  Created by Shuhei Yukawa on 2018/09/05.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation
import AppKit
import MetalKit
import Accelerate

class ViewController: NSViewController, MTKViewDelegate {
    private let device = MTLCreateSystemDefaultDevice()!
    private var commandQueue: MTLCommandQueue!
    private var vertexBuffer: MTLBuffer!
    private var colorBuffer: MTLBuffer!
    private var renderPipeline: MTLRenderPipelineState!
    private let renderPassDescriptor = MTLRenderPassDescriptor()
    
    private let vertexData: [Float] = [
        -1.0, -1.0, 0.0, 1.0,
        1.0, -1.0, 0.0, 1.0,
        -1.0,  1.0, 0.0, 1.0
    ]
    
    private let colorData: [Float] = [1, 1, 1, 1]
    
    @IBOutlet private weak var mtkView: MTKView!
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
    }
    
    func draw(in view: MTKView) {
        // ドローアブルを取得
        guard let drawable = view.currentDrawable else {return}
        
        // コマンドバッファを作成
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {fatalError()}
        
        //
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        
        // エンコーダ生成
        let renderEncoder =
            commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        guard let renderPipeline = renderPipeline else {fatalError()}
        renderEncoder.setRenderPipelineState(renderPipeline)
        let vertex = self.ramdomVertexData(origin: vertexData)
        let color = self.getRandomColorData();
        
        self.makeBuffers(vertex, color)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        renderEncoder.setFragmentBuffer(colorBuffer, offset: 0, index: 0)
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // エンコード完了
        renderEncoder.endEncoding()
        
        // 表示するドローアブルを登録
        commandBuffer.present(drawable)
        
        // コマンドバッファをコミット（エンキュー）
        commandBuffer.commit()
        
        // 完了まで待つ
        commandBuffer.waitUntilCompleted()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        // コマンドキュー初期化
        self.commandQueue = device.makeCommandQueue()
        
        self.mtkView.device = device
        self.mtkView.delegate = self
        
        self.makeBuffers(vertexData, colorData)
        self.makePipeline()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func makeBuffers(_ data: [Float], _ color: [Float]) {
        let size = data.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: data, length: size)
        
        let colorSize = color.count * MemoryLayout<Float>.size
        colorBuffer = device.makeBuffer(bytes: color, length: colorSize)
    }
    
    private func makePipeline() {
        guard let library = device.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = .bgra8Unorm
        renderPipeline = try! device.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func ramdomVertexData(origin: [Float]) -> [Float] {
        let x = self.getRandomNumber(Min: -1, Max: 1)
        let y = self.getRandomNumber(Min: -1, Max: 1)
        let random: [Float] = [
            x, y, 0, 1,
            x, y, 0, 1,
            x, y, 0, 1,
        ]
        
        let matrixA = la_matrix_from_float_buffer(origin, 3, 4, 4, la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        let matrixB = la_matrix_from_float_buffer(random, 3, 4, 4, la_hint_t(LA_NO_HINT), la_attribute_t(LA_DEFAULT_ATTRIBUTES))
        let inner = la_elementwise_product(matrixB, matrixA)
        var result: [Float] = [Float](repeating: 0.0, count: Int(3 * 4))
        la_matrix_to_float_buffer(&result, 4, inner)
        return result;
    }
    
    private func getRandomColorData() -> [Float] {
        let x = self.getRandomNumber(Min: 0, Max: 1)
        let y = self.getRandomNumber(Min: 0, Max: 1)
        let z = self.getRandomNumber(Min: 0, Max: 1)
        let w = self.getRandomNumber(Min: 0, Max: 1)
        return [x, y, z, w]
        
    }
    
    func getRandomNumber(Min _Min : Float, Max _Max : Float)-> Float {
        return ( Float(arc4random_uniform(UINT32_MAX)) / Float(UINT32_MAX) ) * (_Max - _Min) + _Min
        
    }


}

