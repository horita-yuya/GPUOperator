import UIKit
import GPUOperator

final class ThundershowerViewController: UIViewController {
    private let renderingView = RenderingView(frame: .zero)
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
    private func configure() {
        view.addSubview(renderingView)
        renderingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: renderingView.topAnchor),
            view.leadingAnchor.constraint(equalTo: renderingView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: renderingView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: renderingView.bottomAnchor)
            ])
    }
    
    private func configureGpu() {
        gpuOperator = try? GPUOperator()
        renderingView.gpuOperator = gpuOperator
        renderingView.isRoughnessAcceptable = true
    }
}
