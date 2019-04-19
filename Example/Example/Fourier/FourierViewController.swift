import UIKit
import GPUOperator

final class FourierViewController: UIViewController, ShaderViewControlelr {
    let renderingView = RenderingView(frame: .zero)
    private var gpuOperator: GPUOperator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        configureGpu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? gpuOperator?.install(kernel: Fourier())
        renderingView.run()
    }
}

extension FourierViewController {
    private func configureGpu() {
        gpuOperator = try? GPUOperator()
        renderingView.gpuOperator = gpuOperator
    }
}
