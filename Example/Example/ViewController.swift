import UIKit

final class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        let viewController = ThundershowerViewController()
        let viewController = CameraViewController()
//        let viewController = ImageDifferenceViewController()
        present(viewController, animated: true)
    }
}
