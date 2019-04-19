import GPUOperator
import Metal

final class Fourier: Kernel {
    static let functionName: String = "fourier"
    
    private var time: Float = 0;
    func encode(withEncoder encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        time += 0.55
        
        if time > 100 { time = 0 }
    }
}
