import UIKit
import Flutter
import LocalAuthentication

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    print("🔧 DEBUG 모드입니다. makeSecure()는 호출되지 않습니다.")
    #else
    self.window?.makeSecure()   
    #endif

    // 플랫폼 채널 설정
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let osChannel = FlutterMethodChannel(name: "onl.coconut.vault/os",
                                         binaryMessenger: controller.binaryMessenger)
    
    osChannel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      switch call.method {
      case "isDeviceSecure":
        result(isDeviceSecure())
      default:
        result(FlutterMethodNotImplemented)
      }
    })

    // 플러그인 등록
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}

extension UIWindow {
    func makeSecure() {
        let field = UITextField()
        let view = UIView(frame: CGRect(x: 0, y: 0, width: field.frame.self.width, height: field.frame.self.height))
        field.isSecureTextEntry = true
        self.addSubview(field)
        self.layer.superlayer?.addSublayer(field.layer)
        field.layer.sublayers?.last!.addSublayer(self.layer)
        field.leftView = view
        field.leftViewMode = .always
    }
}

func isDeviceSecure() -> Bool {
    let context = LAContext()
    var error: NSError?
    return context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error)
}