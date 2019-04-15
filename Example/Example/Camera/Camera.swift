import AVFoundation
import GPUOperator

final class Camera: NSObject {
    private let captureSession = AVCaptureSession()
    private weak var gpuOperator: GPUOperator?
    
    init(gpuOperator: GPUOperator?) {
        self.gpuOperator = gpuOperator
        super.init()
        
        self.gpuOperator?.graphicsEncoder = try! Processor(device: gpuOperator!.device, library: gpuOperator!.frameworkBundleLibrary)
        configure()
    }
    
    private func configure() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            guard granted else { return }
        }
        
        guard let device = AVCaptureDevice.default(for: .video) else { return }
        
        let captureInput = try! AVCaptureDeviceInput(device: device)
        captureSession.beginConfiguration()
        guard captureSession.canAddInput(captureInput) else { return }
        captureSession.addInput(captureInput)
        
        let output = AVCaptureVideoDataOutput()
        
        output.videoSettings = [
            kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_32BGRA)
        ]
        output.setSampleBufferDelegate(self, queue: .init(label: "camera"))
        
        guard captureSession.canAddOutput(output) else { return }
        captureSession.addOutput(output)
        captureSession.commitConfiguration()
    }
    
    func start() {
        captureSession.startRunning()
    }
}

extension Camera: AVCaptureVideoDataOutputSampleBufferDelegate {
    func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
        guard connection.videoOrientation == .portrait else { return connection.videoOrientation = .portrait }
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
        gpuOperator?.compute(pixelBuffer: pixelBuffer)
    }
}

extension Camera {
    final class Processor: GraphicsEncoder {
        override class var textureData: [Float] {
            return [
                1.0, 0.0,
                1.0, 1.0,
                0.0, 0.0,
                0.0, 1.0
            ]
        }
    }
}
