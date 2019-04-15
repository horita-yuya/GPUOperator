import UIKit
import GPUOperator

final class CameraViewController: UIViewController {
    private let renderingView = RenderingView(frame: .zero)
    private var gpuOperator: GPUOperator?
    private var isFiltered: Bool = false
    private lazy var camera: Camera = .init(gpuOperator: gpuOperator)

    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
        configureGpu()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        camera.start()
        renderingView.run()
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        isFiltered.toggle()
        isFiltered ?
            try? gpuOperator?.install(kernel: Monochrome()):
            gpuOperator?.reset()
    }
}

extension CameraViewController {
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
    }
}
