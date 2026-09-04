import UIKit
import SpriteKit

class GameViewController: UIViewController {
    private var didStartGame = false
    private weak var splashView: UIView?

    override func loadView() {
        let root = UIView()
        root.backgroundColor = .black
        root.isOpaque = true
        view = root
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        let splash = UIImageView(image: UIImage(named: "LaunchBackdrop"))
        splash.backgroundColor = .black
        splash.isOpaque = true
        splash.contentMode = .scaleAspectFill
        splash.clipsToBounds = true
        splash.frame = view.bounds
        splash.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(splash)
        splashView = splash
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        startGameIfNeeded()
    }

    private func startGameIfNeeded() {
        guard !didStartGame else { return }
        didStartGame = true

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.backgroundColor = .black
        skView.isOpaque = true
        skView.allowsTransparency = false
        skView.showsFPS = false
        skView.showsNodeCount = false
        skView.preferredFramesPerSecond = 60
        skView.ignoresSiblingOrder = true
        view.insertSubview(skView, at: 0)

        let scene = GameScene(size: CGSize(width: 1080, height: 1920))
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
        splashView?.removeFromSuperview()
        splashView = nil
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override var shouldAutorotate: Bool { false }
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
