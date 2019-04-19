import Metal
import UIKit

#if targetEnvironment(simulator)
public typealias GPUOperatorDrawable = Void
#else
public typealias GPUOperatorDrawable = CAMetalDrawable
#endif

open class GPUOperator {
    enum Error: Swift.Error {
        case failedToConfigure
    }
    
    /// Encoder for kernel function
    ///
    /// Note: Has `MTLComputePipelineState` for parallel computations.
    public var kernelEncoder: AnyKernelEncoder?
    
    /// Encoder for graphics functions, vertex and fragment
    ///
    /// Note: Has `MTLRenderPipelineState` for rendering graphics.
    public var graphicsEncoder: GraphicsEncoder
    
    public var pixelBufferProcessor: PixelBufferProcessor
    
    public let device: MTLDevice
    public let commandQueue: MTLCommandQueue
    
    /// MTLLibrary for main bundle
    ///
    /// - Note: Custom shader implemented in main project will be contained.
    public let mainBundleLibrary: MTLLibrary
    
    /// MTLLibrary for this framework bundle
    ///
    /// - Note: Default shader implementation will be contained. (comming soon)
    public let frameworkBundleLibrary: MTLLibrary
    
    /// The destination texture rendered in view finally.
    ///
    /// - Note: processed by kernel and fragment function in `commit(drawable:)`
    private var destinationTexture: MTLTexture!
    
    
    /// The source textures which are used for performing computations.
    ///
    /// - Note: In compute shaders, read this texture pixels and write to `destinationTexture` pixel.
    private var sourceTextures: [MTLTexture] = []
    
    public init() throws {
        guard let device = MTLCreateSystemDefaultDevice(), let commandQueue = device.makeCommandQueue() else { throw Error.failedToConfigure }
        
        let frameworkBundleLibrary = try device.makeDefaultLibrary(bundle: .init(for: GPUOperator.self))
        self.device = device
        self.frameworkBundleLibrary = frameworkBundleLibrary
        self.mainBundleLibrary = try device.makeDefaultLibrary(bundle: .main)
        
        kernelEncoder = try PassThroughEncoder(device: device, library: frameworkBundleLibrary)
        graphicsEncoder = try .init(device: device, library: frameworkBundleLibrary)
        pixelBufferProcessor = .init(device: device, pixelFormat: graphicsEncoder.pixelFormat)
        self.commandQueue = commandQueue
    }
    
    /// Install a kernel encoded in `commit(drawable:)` below.
    ///
    /// - Note: Specify bundle contains your target kernel function if needed.
    ///         Expecially for other framework bundle.
    ///
    /// - Note: main budle { Bundle.main } and framework bundle { Bundle(for: GPUOperator.self) } are supported defaultly.
    open func install<K: Kernel>(kernel: K, bundle: Bundle? = nil) throws {
        switch bundle {
        case let specifiedBundle?:
            let specifiedBundleLibrary = try device.makeDefaultLibrary(bundle: specifiedBundle)
            kernelEncoder = try KernelEncoder(device: device, library: specifiedBundleLibrary, kernel: kernel)
            
        case .none where mainBundleLibrary.functionNames.contains(K.functionName):
            kernelEncoder = try KernelEncoder(device: device, library: mainBundleLibrary, kernel: kernel)
            
        default:
            kernelEncoder = try KernelEncoder(device: device, library: frameworkBundleLibrary, kernel: kernel)
        }
    }
    
    /// Reset the kernel.
    open func reset() {
        kernelEncoder = try? PassThroughEncoder(device: device, library: frameworkBundleLibrary)
    }
    
    /// Commit a command buffer for souceImages witout rendering.
    ///
    /// - Note: Only RGB is supported now.
    open func commit(sourceImages: [CIImage], completion: ((UIImage) -> ())? = nil) {
        #if !targetEnvironment(simulator)
        guard let firstSourceImage = sourceImages.first,
            let destinationTexture = makeEmptyTexture(width: .init(firstSourceImage.extent.width), height: .init(firstSourceImage.extent.height)) else { return }
        
        let commandBuffer = commandQueue.makeCommandBuffer()
        let context = CIContext(mtlDevice: device)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        
        let sourceTextures = sourceImages.compactMap { sourceImage -> MTLTexture? in
            guard let texture = makeEmptyTexture(width: .init(sourceImage.extent.width), height: .init(sourceImage.extent.height)) else { return nil }
            context.render(sourceImage, to: texture, commandBuffer: commandBuffer, bounds: sourceImage.extent, colorSpace: colorSpace)
            return texture
        }
        
        kernelEncoder?.encode(buffer: commandBuffer, destinationTexture: destinationTexture, sourceTextures: sourceTextures)
        commandBuffer?.addCompletedHandler { hand in
            guard let finalCiImage = CIImage(mtlTexture: destinationTexture, options: nil) else { return }
            let finalImage = UIImage(ciImage: finalCiImage, scale: UIScreen.main.nativeScale, orientation: .up)
            DispatchQueue.main.async {
                completion?(finalImage)
            }
        }
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        #endif
    }
    
    /// Commit a command buffer.
    ///
    /// - Note: This method will perform expectedly on except simulator due to CAMetalDrawable.
    open func commit(drawable: GPUOperatorDrawable) {
        #if !targetEnvironment(simulator)
        let commandBuffer = commandQueue.makeCommandBuffer()
        
        if destinationTexture == nil {
            destinationTexture = makeEmptyTexture(width: drawable.texture.width, height: drawable.texture.height)
        }
    
        kernelEncoder?.encode(buffer: commandBuffer, destinationTexture: destinationTexture, sourceTextures: sourceTextures)
        graphicsEncoder.encode(commandBuffer: commandBuffer, targetDrawable: drawable, presentingTexture: destinationTexture)
        
        commandBuffer?.present(drawable)
        commandBuffer?.commit()
        commandBuffer?.waitUntilCompleted()
        #endif
    }
    
    /// Generates a texture from CVPixelBuffer and cache it.
    ///
    /// - Note: This method is used for creating and caching texture from CVPixelBuffer.
    ///         The rendering method `func commit(drawable:)` will use them.
    @discardableResult
    open func compute(pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        guard let bufferTexture = pixelBufferProcessor.makeTexture(imageBuffer: pixelBuffer) else { return nil }
        
        destinationTexture = makeEmptyTexture(width: bufferTexture.width, height: bufferTexture.height)
        sourceTextures = [bufferTexture]
        return bufferTexture
    }
    
    /// Generates a texture with `GraphicsEncoder.pixelFormat`
    open func makeEmptyTexture(width: Int, height: Int) -> MTLTexture? {
        let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: graphicsEncoder.pixelFormat,
            width: width,
            height: height,
            mipmapped: false
        )
        
        textureDescriptor.usage = [.shaderRead, .shaderWrite]
        return device.makeTexture(descriptor: textureDescriptor)
    }
}

private final class PassThroughKernel: Kernel {
    static let functionName: String = "pass_through"
}

private final class PassThroughEncoder: KernelEncoder<PassThroughKernel> {
    override func encode(buffer: MTLCommandBuffer?, destinationTexture: MTLTexture, sourceTextures: [MTLTexture] = []) {
        guard !sourceTextures.isEmpty else { return }
        super.encode(buffer: buffer, destinationTexture: destinationTexture, sourceTextures: sourceTextures)
    }
    
    convenience init(device: MTLDevice, library: MTLLibrary) throws {
        try self.init(device: device, library: library, kernel: .init())
    }
}
