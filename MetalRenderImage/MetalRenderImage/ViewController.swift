//
//  ViewController.swift
//  MetalRenderImage
//
//  Created by Shuhei Yukawa on 2018/08/17.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

//
//  ViewController.swift
//  MetalPractice
//
//  Created by Shuhei Yukawa on 2018/08/17.
//  Copyright © 2018年 Shuhei Yukawa. All rights reserved.
//

import Foundation
import AppKit
import MetalKit

class ViewController: NSViewController, MTKViewDelegate {
    private let device = MTLCreateSystemDefaultDevice()! // 強制アンラップをすべきでないけどまぁ、サンプルなので
    private var commandQueue: MTLCommandQueue!
    private var texture: MTLTexture!
    
    @IBOutlet private weak var mtkView: MTKView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.commandQueue = device.makeCommandQueue()
        self.mtkView.device = device
        self.mtkView.delegate = self
        self.mtkView.framebufferOnly = false
        self.loadTexture()
        
        mtkView.enableSetNeedsDisplay = true
        // ビューの更新依頼 → draw(in:)が呼ばれる
        mtkView.setNeedsDisplay(view.visibleRect)
    }
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        
    }
    
    func draw(in view: MTKView) {
        print("draw")
        let drawable = view.currentDrawable!
        
        // コマンドバッファを作成
        let commandBuffer = commandQueue.makeCommandBuffer()!
        
        //        drawable.texture = texture              // ビルドエラー
        // コピーするサイズを計算
        let w = min(texture.width, drawable.texture.width)
        let h = min(texture.height, drawable.texture.height)
        //        print("texture: \(texture)\ndrawable.texture: \(drawable.texture)")
        // MTLBlitCommandEncoderを作成
        let blitEncoder = commandBuffer.makeBlitCommandEncoder()!
        
        // コピーコマンドをエンコード
        blitEncoder.copy(from: texture,         // コピー元テクスチャ
            sourceSlice: 0,
            sourceLevel: 0,
            sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
            sourceSize: MTLSizeMake(w, h, texture.depth),
            to: drawable.texture,  // コピー先テクスチャ
            destinationSlice: 0,
            destinationLevel: 0,
            destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
        
        // エンコード完了
        blitEncoder.endEncoding()
        
        // 表示するドローアブルを登録
        commandBuffer.present(drawable)
        
        // コマンドバッファをコミット（エンキュー）
        commandBuffer.commit()
        
        // 完了まで待つ
        commandBuffer.waitUntilCompleted()
    }
    
    private func loadTexture() {
        let textureLoader = MTKTextureLoader(device: device)
        texture = try! textureLoader.newTexture(
            name: "icon",
            scaleFactor: 1.0,//view.window!.backingScaleFactor,
            bundle: nil)
        mtkView.colorPixelFormat = texture.pixelFormat
    }
}


