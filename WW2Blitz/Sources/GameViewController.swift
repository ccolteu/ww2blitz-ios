import UIKit
import SpriteKit

class GameViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black

        let skView = SKView(frame: view.bounds)
        skView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        skView.backgroundColor = .black
        skView.showsFPS = false
        skView.showsNodeCount = false
        // Match Android's 60 Hz Choreographer loop (ProMotion would otherwise run at 120).
        skView.preferredFramesPerSecond = 60
        skView.ignoresSiblingOrder = true
        view.addSubview(skView)

        // Android canvas is 1080×1920 px. Keep that virtual size so speeds and UI match.
        let scene = GameScene(size: CGSize(width: 1080, height: 1920))
        scene.scaleMode = .aspectFit
        skView.presentScene(scene)
        UIApplication.shared.isIdleTimerDisabled = true
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .portrait }
    override var prefersStatusBarHidden: Bool { true }
    override var prefersHomeIndicatorAutoHidden: Bool { true }
}
