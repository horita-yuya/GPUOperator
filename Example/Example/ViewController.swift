import UIKit
import GPUOperator

final class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        let viewController = ThundershowerViewController()
        let viewController = FourierViewController()
//        let viewController = CameraViewController()
//        let viewController = ImageDifferenceViewController()
        present(viewController, animated: true)
    }
}

protocol ShaderViewControlelr {
    var renderingView: RenderingView { get }
}

extension ShaderViewControlelr where Self: UIViewController {
    func configure() {
        view.addSubview(renderingView)
        renderingView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            view.topAnchor.constraint(equalTo: renderingView.topAnchor),
            view.leadingAnchor.constraint(equalTo: renderingView.leadingAnchor),
            view.trailingAnchor.constraint(equalTo: renderingView.trailingAnchor),
            view.bottomAnchor.constraint(equalTo: renderingView.bottomAnchor)
            ])
    }
}
