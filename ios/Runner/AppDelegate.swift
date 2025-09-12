import UIKit
import Flutter

@main
@objc class AppDelegate: FlutterAppDelegate {
  private let SECURE_MEMORY_CHANNEL = "secure_memory"

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    #if DEBUG
    print("🔧 DEBUG 모드입니다. makeSecure()는 호출되지 않습니다.")
    #else
    self.window?.makeSecure()   
    #endif

    // 플랫폼 채널 설정 추가
    let controller : FlutterViewController = window?.rootViewController as! FlutterViewController
    let channel = FlutterMethodChannel(name: SECURE_MEMORY_CHANNEL, binaryMessenger: controller.binaryMessenger)
   
    channel.setMethodCallHandler({
      (call: FlutterMethodCall, result: @escaping FlutterResult) -> Void in
      if call.method == "wipe" {
        if let args = call.arguments as? [String: Any],
          let data = args["data"] as? FlutterStandardTypedData {
            
            var buffer = [UInt8](data.data)
            
            // self.debugMemory(&buffer, label: "삭제 전")
      
            memset_s(&buffer, buffer.count, 0, buffer.count)
            
            // self.debugMemory(&buffer, label: "삭제 후")
          }
          result(nil)
      } else {
        result(FlutterMethodNotImplemented)
      }
    })

    // 플러그인 등록
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 메모리 디버깅 함수
  private func debugMemory(_ buffer: inout [UInt8], label: String) {
    let address = UnsafeRawPointer(&buffer)
    let firstBytes = Array(buffer.prefix(8))
    let lastBytes = Array(buffer.suffix(8))
    
    print("""
    🔍 \(label)
    📍 주소: \(address)
    �� 크기: \(buffer.count) bytes
    �� 첫 8바이트: \(formatBytes(firstBytes))
    �� 마지막 8바이트: \(formatBytes(lastBytes))
    """)
  }
  
  // 바이트 배열을 16진수 문자열로 포맷팅
  private func formatBytes(_ bytes: [UInt8]) -> String {
    return bytes.map { String(format: "0x%02X", $0) }.joined(separator: " ")
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