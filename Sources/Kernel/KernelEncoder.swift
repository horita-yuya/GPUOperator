import Metal

open class AnyKernelEncoder {
    func encode(buffer: MTLCommandBuffer?, destinationTexture: MTLTexture, sourceTextures: [MTLTexture] = []) {
        fatalError("absolute method is called")
    }
}

open class KernelEncoder<K: Kernel>: AnyKernelEncoder {
    enum Error: Swift.Error {
        case failedToInitialize
    }
    
    public let kernel: Kernel
    public let computePipelineState: MTLComputePipelineState
    
    public init(device: MTLDevice, library: MTLLibrary, kernel: K) throws {
        guard let kernelFunction = library.makeFunction(name: K.functionName) else { throw Error.failedToInitialize }
        
        self.kernel = kernel
        self.computePipelineState = try device.makeComputePipelineState(function: kernelFunction)
    }
    
    /// Encoding process
    ///
    /// - Note: Shareing data between GPU and CPU in shared memory.
    ///
    /// - Note: In MSL, the texture data corresponding to destinationTexture must be set to [[ texture(0) ]].
    ///         Define the texture data as readable and writable in MSL, like `texture2d<half, access::read_write>`
    ///
    /// - Example:
    ///       kernel void sample_kernel_function(texture2d<half, access::read_write> dest [[ texture(0) ]],
    ///                                          uint2 gid [[ thread_position_in_grid ]])
    open override func encode(buffer: MTLCommandBuffer?, destinationTexture: MTLTexture, sourceTextures: [MTLTexture] = []) {
        guard let encoder = buffer?.makeComputeCommandEncoder() else { return }
        
        encoder.setComputePipelineState(computePipelineState)
        
        encoder.setTexture(destinationTexture, index: 0)
        for (index, sourceTexture) in sourceTextures.enumerated() {
            encoder.setTexture(sourceTexture, index: index + 1)
        }
        
        kernel.encode(withEncoder: encoder)
        
        let config = makeThreadgroupsConfig(
            textureWidth: destinationTexture.width,
            textureHeight: destinationTexture.height,
            threadExecutionWidth: computePipelineState.threadExecutionWidth,
            maxTotalThreadsPerThreadgroup: computePipelineState.maxTotalThreadsPerThreadgroup
        )
        
        encoder.dispatchThreadgroups(config.threadgroupsPerGrid, threadsPerThreadgroup: config.threadsPerThreadgroup)
        encoder.endEncoding()
    }
    
    private func makeThreadgroupsConfig(
        textureWidth: Int,
        textureHeight: Int,
        threadExecutionWidth: Int,
        maxTotalThreadsPerThreadgroup: Int
        ) -> (threadgroupsPerGrid: MTLSize, threadsPerThreadgroup: MTLSize) {
        
        let w = threadExecutionWidth
        let h = maxTotalThreadsPerThreadgroup / w
        
        let threadsPerThreadgroup = MTLSizeMake(w, h, 1)
        let horizontalThreadgroupCount = (textureWidth + w - 1) / w
        let verticalThreadgroupCount = (textureHeight + h - 1) / h
        let threadgroupsPerGrid = MTLSizeMake(horizontalThreadgroupCount, verticalThreadgroupCount, 1)
        
        return (threadgroupsPerGrid: threadgroupsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
    }
}
