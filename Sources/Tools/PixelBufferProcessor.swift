import Metal
import UIKit

open class PixelBufferProcessor {
    #if !targetEnvironment(simulator)
    var textureCache: CVMetalTextureCache?
    private let pixelFormat: MTLPixelFormat
    
    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {
        self.pixelFormat = pixelFormat
        CVMetalTextureCacheCreate(
            kCFAllocatorDefault,
            nil,
            device,
            nil,
            &textureCache
        )
    }
    
    open func makeTexture(imageBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let cache = textureCache else { return nil }
        let width = CVPixelBufferGetWidth(imageBuffer)
        let height = CVPixelBufferGetHeight(imageBuffer)
        
        var imageTexture: CVMetalTexture?
        let result =  CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            cache,
            imageBuffer,
            nil,
            pixelFormat,
            width,
            height,
            0,
            &imageTexture
        )
        
        if result == kCVReturnSuccess, let _imageTexture = imageTexture {
            return CVMetalTextureGetTexture(_imageTexture)
            
        } else {
            return nil
        }
    }
    #else
    
    /// Just for building for simulator.
    /// Simulator is unsupported.
    init(device: MTLDevice, pixelFormat: MTLPixelFormat) {}
    public func makeTexture(imageBuffer: CVPixelBuffer) -> MTLTexture? { return nil }
    #endif
}
