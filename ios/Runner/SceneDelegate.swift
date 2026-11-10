import Flutter
import UIKit

// iOS 27 SDK부터 UIScene 라이프사이클을 쓰지 않는 앱은 실행 즉시 종료되므로 Scene에서 창을 만든다.
class SceneDelegate: FlutterSceneDelegate {
    override func scene(
        _ scene: UIScene,
        willConnectTo session: UISceneSession,
        options connectionOptions: UIScene.ConnectionOptions
    ) {
        guard let windowScene = scene as? UIWindowScene,
              let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }

        super.scene(scene, willConnectTo: session, options: connectionOptions)
        let controller = appDelegate.flutterEngine.viewController
            ?? FlutterViewController(engine: appDelegate.flutterEngine, nibName: nil, bundle: nil)
        let sceneWindow = window ?? UIWindow(windowScene: windowScene)
        sceneWindow.rootViewController = controller
        window = sceneWindow
        appDelegate.window = sceneWindow
#if DEBUG
        print("🔧 DEBUG mode. makeSecure() is not applied.")
#else
        sceneWindow.makeSecure()
#endif
        sceneWindow.makeKeyAndVisible()
    }

    override func sceneDidDisconnect(_ scene: UIScene) {
        if let appDelegate = UIApplication.shared.delegate as? AppDelegate,
           appDelegate.window === window {
            appDelegate.window = nil
        }
        window = nil
    }
}
