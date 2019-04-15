/// Kernel function protocol
///
/// - functionName: Specify kernel function defined in .metal
///
/// - byteEncode(encoder:): Use for encoding variable changing every frame, like time.
///
///   Example:
///       private var time: Float = 0
///       public func encode(withEncoder encoder: MTLComputeCommandEncoder) {
///           encoder.setBytes(&time, length: MemoryLayout<Float>.size, index: 0)
///           time += 0.025
///       }
import Metal
public protocol Kernel {
    static var functionName: String { get }
    func encode(withEncoder encoder: MTLComputeCommandEncoder)
}

public extension Kernel {
    func encode(withEncoder encoder: MTLComputeCommandEncoder) {}
}
