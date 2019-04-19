import UIKit
import GPUOperator

final class ThundershowerViewController: UIViewController, ShaderViewControlelr {
    let renderingView = RenderingView(frame: .zero)
    private var gpuOperator: GPUOperator?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        configureGpu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        try? gpuOperator?.install(kernel: Thundershower())
        renderingView.run()
    }
}

extension ThundershowerViewController {
    private func configureGpu() {
        gpuOperator = try? GPUOperator()
        renderingView.gpuOperator = gpuOperator
        renderingView.isRoughnessAcceptable = true
    }
}
