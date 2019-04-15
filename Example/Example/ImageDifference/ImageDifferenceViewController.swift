import UIKit
import GPUOperator

final class ImageDifferenceViewController: UIViewController {
    private var gpuOperator: GPUOperator?
    private let imageView: UIImageView = {
        let imageView = UIImageView(frame: .zero)
        imageView.contentMode = .scaleAspectFit
        imageView.translatesAutoresizingMaskIntoConstraints = false
        return imageView
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        configure()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        run()
    }
}

extension ImageDifferenceViewController {
    private func configure() {
        gpuOperator = try? GPUOperator()
        view.addSubview(imageView)
        NSLayoutConstraint.activate([
            view.centerXAnchor.constraint(equalTo: imageView.centerXAnchor),
            view.centerYAnchor.constraint(equalTo: imageView.centerYAnchor)
            ])
    }
    
    private func run() {
        let beforeImage = CIImage(image: UIImage(named: "before")!)
        let afterImage = CIImage(image: UIImage(named: "after")!)
        
        let sourceImages = [beforeImage, afterImage].compactMap { $0 }
        try? gpuOperator?.install(kernel: ImageDifference())
        gpuOperator?.commit(sourceImages: sourceImages) { [weak self] image in
            self?.imageView.image = image
        }
    }
}
