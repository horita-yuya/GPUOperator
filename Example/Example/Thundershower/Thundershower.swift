import Metal
import GPUOperator

final class Thundershower: Kernel {
    static let functionName: String = "thundershower"
    
    private var time: Float = 0
    
    func encode(withEncoder encoder: MTLComputeCommandEncoder) {
        encoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
        time += 0.025
    }
}
