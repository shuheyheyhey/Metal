//
//  ViewController.swift
//  ComputedShader
//
//  Created by Shuhei Yukawa on 2018/09/15.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Cocoa
import MetalKit

class ViewController: NSViewController, MTKViewDelegate {
    
    private let vertexData: [Float] = [-1, -1, 0, 1,
                                       1, -1, 0, 1,
                                       -1,  1, 0, 1,
                                       1,  1, 0, 1]
    
    private let textureCoordinateData: [Float] = [0, 1,
                                                  1, 1,
                                                  0, 0,
                                                  1, 0]
    
    @IBOutlet weak var metalView: MTKView!
    // ハードウェアとしての GPU を抽象化したプロトコル
    private let device = MTLCreateSystemDefaultDevice()
    // CPU で作成されて GPU で実行されるコマンドを格納するコンテナ -> CommnadBuffer の作成
    private var commandQueue: MTLCommandQueue!
    // レンダリングシェダーを実行するためのパイプライン
    private var renderPipeline: MTLRenderPipelineState!
    // コンピュートシェダーを実行するためのパイプライン
    private var computePipeline: MTLComputePipelineState!
    
    // 入出力用テクスチャ
    private var inputTexture: MTLTexture!
    private var outputTexture: MTLTexture!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        self.setupMetal()
        
        self.loadInputTexture()
        
        self.makeRenderPipeline()
        
        self.makeComputePipeline()
    }

    override var representedObject: Any? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    private func setupMetal() {
        if let metalDevice = self.device {
            self.commandQueue = metalDevice.makeCommandQueue()!
            self.metalView.device = metalDevice
            self.metalView.delegate = self
        }
    }
    
    private func loadInputTexture() {
        let textureLoader = MTKTextureLoader(device: device!)
        self.inputTexture = try! textureLoader.newTexture(
            name: "jyonill",
            scaleFactor: 1,
            bundle: nil)
        self.metalView.colorPixelFormat = inputTexture.pixelFormat
        
        let textureDescriptor = MTLTextureDescriptor()
        textureDescriptor.textureType = .type2D
        //textureDescriptor.pixelFormat = self.inputTexture.pixelFormat
        textureDescriptor.width = self.inputTexture.width
        textureDescriptor.height = self.inputTexture.height
        textureDescriptor.usage = MTLTextureUsage(rawValue: MTLTextureUsage.RawValue(UInt8(MTLTextureUsage.shaderRead.rawValue) | UInt8(MTLTextureUsage.shaderWrite.rawValue) | UInt8(MTLTextureUsage.renderTarget.rawValue)))
        self.outputTexture = self.device!.makeTexture(descriptor: textureDescriptor)
    }
    
    private func makeRenderPipeline() {
        guard let library = device!.makeDefaultLibrary() else {fatalError()}
        let descriptor = MTLRenderPipelineDescriptor()
        descriptor.vertexFunction = library.makeFunction(name: "vertexShader")
        descriptor.fragmentFunction = library.makeFunction(name: "fragmentShader")
        descriptor.colorAttachments[0].pixelFormat = self.metalView.colorPixelFormat
        self.renderPipeline = try! device!.makeRenderPipelineState(descriptor: descriptor)
    }
    
    private func makeComputePipeline() {
        guard let library = device!.makeDefaultLibrary() else {fatalError()}
        let function = library.makeFunction(name: "computedShader")
        self.computePipeline = try! device!.makeComputePipelineState(function: function!)
    }
    
    private func render() {
        let drawable = self.metalView.currentDrawable!
        // コマンドバッファを作成
        guard let commandBuffer = commandQueue.makeCommandBuffer() else {return}
        
        guard let renderPassDescriptor = self.metalView.currentRenderPassDescriptor else {return}
        renderPassDescriptor.colorAttachments[0].texture = drawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = MTLLoadAction.clear;
        renderPassDescriptor.colorAttachments[0].clearColor = MTLClearColorMake(0.0, 0.0, 0.0, 0.0)
        
        // エンコーダ生成
        let renderEncoder =
            commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor)!
        
        guard let renderPipeline = self.renderPipeline else {fatalError()}
        renderEncoder.setRenderPipelineState(renderPipeline)
        
        let vertexBuffer = self.makeCommandBuffer(vertexData)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        
        let textureBuffer = self.makeCommandBuffer(textureCoordinateData)
        renderEncoder.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        
        renderEncoder.setFragmentTexture(self.outputTexture, index: 0)
        
        renderEncoder.drawPrimitives(type: .triangleStrip, vertexStart: 0, vertexCount: 4)
        
        // エンコード完了
        renderEncoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func makeOutputTexture() {
        let drawable = self.metalView.currentDrawable!
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        // コンピュートコマンドエンコーダを作成・・・(1)
        let encoder = commandBuffer.makeComputeCommandEncoder()!
        // コンピュートパイプラインをセット・・・(2)
        encoder.setComputePipelineState(self.computePipeline)
        // テクスチャをセット・・・(3)
        encoder.setTexture(self.inputTexture, index: 0) // 入力
        encoder.setTexture(self.outputTexture, index: 1) // 出力
        // グリッドサイズを計算するディスパッチコールをエンコード・・・(4)
        let threadgroupSize = MTLSize(width: self.inputTexture.width, height: self.inputTexture.height, depth: 1)
        let w = threadgroupSize.width
        let h = threadgroupSize.height
        let threadgroupCount = MTLSize(
            width:  (self.inputTexture.width  + w - 1) / w,
            height: (self.inputTexture.height + h - 1) / h,
            depth: 1
        )
        encoder.dispatchThreadgroups(threadgroupSize, threadsPerThreadgroup: threadgroupCount)
        encoder.endEncoding()
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
    
    private func makeCommandBuffer(_ data: [Float]) -> MTLBuffer {
        let size = data.count * MemoryLayout<Float>.size
        let buffer = self.device!.makeBuffer(bytes: data, length: size)
        return buffer!
    }
    
    // MARK: MTKViewDelegate
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        print("mtkView delegate")
    }
    
    func draw(in view: MTKView) {
        self.makeOutputTexture()
        self.render()
    }
}

