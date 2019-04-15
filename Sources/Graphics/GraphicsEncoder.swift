import Metal
import UIKit

open class GraphicsEncoder {
    enum Error: Swift.Error {
        case failedToInitialize
    }
    
    private let vertexBuffer: MTLBuffer
    private let textureBuffer: MTLBuffer
    private let vertexIndexBuffer: MTLBuffer
    private let renderPipelineState: MTLRenderPipelineState
    public let pixelFormat: MTLPixelFormat
    
    /// Vertex coordinates
    ///
    ///    (-1.0, 1.0)       (1.0, 1.0)
    ///     o----------------o
    ///     |                |
    ///     |                |
    ///     |                |
    ///     |                |
    ///     |                |
    ///     |                |
    ///     o----------------o
    ///    (-1.0, -1.0)      (1.0, -1.0)
    ///
    ///                      reference: https://developer.apple.com/documentation/metal/hello_triangle
    open class var vertexData: [Float] {
        return [
            1.0, 1.0,
            1.0, -1.0,
            -1.0, 1.0,
            -1.0, -1.0
        ]
    }
    
    /// Texture coordinates
    ///
    ///    (0.0, 1.0)        (1.0, 1.0)
    ///     o----------------o
    ///     |                |
    ///     |                |
    ///     |                |
    ///     |                |
    ///     |                |
    ///     |                |
    ///     o----------------o
    ///    (0.0, 0.0)        (1.0, 0.0)
    ///
    ///                      reference: https://developer.apple.com/documentation/metal/basic_texturing
    open class var textureData: [Float] {
        return [
            1, 1,
            1, 0,
            0, 1,
            0, 0
        ]
    }
    
    open class var vertexIndexData: [UInt16] {
        return [
            0, 1, 2,
            1, 2, 3
        ]
    }
    
    public init(device: MTLDevice, library: MTLLibrary, pixelFormat: MTLPixelFormat = .bgra8Unorm) throws {
        guard let vertexBuffer = device.makeBuffer(bytes: type(of: self).vertexData),
            let textureBuffer = device.makeBuffer(bytes: type(of: self).textureData),
            let vertexIndexBuffer = device.makeBuffer(bytes: type(of: self).vertexIndexData) else { throw Error.failedToInitialize }
        
        self.vertexBuffer = vertexBuffer
        self.textureBuffer = textureBuffer
        self.vertexIndexBuffer = vertexIndexBuffer
        self.pixelFormat = pixelFormat
        
        let fragmentFunction = library.makeFunction(name: "graphics_fragment")
        let vertexFunction = library.makeFunction(name: "graphics_vertex")
        
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = pixelFormat
        
        self.renderPipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
    }
    
    #if !targetEnvironment(simulator)
    open func encode(commandBuffer: MTLCommandBuffer?, targetDrawable: CAMetalDrawable, presentingTexture: MTLTexture) {
        let renderPassDescriptor = MTLRenderPassDescriptor()
        renderPassDescriptor.colorAttachments[0].texture = targetDrawable.texture
        renderPassDescriptor.colorAttachments[0].loadAction = .clear
        renderPassDescriptor.colorAttachments[0].clearColor = .init(red: 0, green: 0, blue: 0, alpha: 1)
        
        let renderEncoder = commandBuffer?.makeRenderCommandEncoder(descriptor: renderPassDescriptor)
        renderEncoder?.setRenderPipelineState(renderPipelineState)
        renderEncoder?.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder?.setVertexBuffer(textureBuffer, offset: 0, index: 1)
        renderEncoder?.setFragmentTexture(presentingTexture, index: 0)
        renderEncoder?.drawIndexedPrimitives(
            type: .triangle,
            indexCount: type(of: self).vertexIndexData.count,
            indexType: .uint16,
            indexBuffer: vertexIndexBuffer,
            indexBufferOffset: 0
        )
        renderEncoder?.endEncoding()
    }
    #endif
}

private extension MTLDevice {
    func makeBuffer<T>(bytes: [T]) -> MTLBuffer? {
        return makeBuffer(bytes: bytes, length: bytes.count * MemoryLayout.size(ofValue: bytes[0]), options: [])
    }
}
