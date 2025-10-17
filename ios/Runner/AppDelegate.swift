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
        print("🔧 DEBUG mode. makeSecure() is not applied.")
#else
        self.window?.makeSecure()
#endif
        
        let controller: FlutterViewController = window?.rootViewController as! FlutterViewController
        let osChannel = FlutterMethodChannel(name: "onl.coconut.vault/os", binaryMessenger: controller.binaryMessenger)
        let teeChannel = FlutterMethodChannel(name: "onl.coconut.vault/trusted_execution_environment", binaryMessenger: controller.binaryMessenger)
        
        osChannel.setMethodCallHandler { call, result in
            switch call.method {
            case "isDeviceSecure":
                result(isDeviceSecure())
            case "isJailbroken":
                result(isDeviceJailbroken())
            default:
                result(FlutterMethodNotImplemented)
            }
        }
        
        installTEEHandler(teeChannel)
        
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

func isDeviceJailbroken() -> Bool {
#if targetEnvironment(simulator)
    return false
#else
    // 탈옥 흔적 파일 확인
    let jailbreakPaths = [
        "/Applications/Cydia.app",
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",
        "/usr/sbin/sshd",
        "/etc/apt",
        "/private/var/lib/apt/"
    ]
    if jailbreakPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
        return true
    }
    
    // 루트 영역에 쓰기 시도
    let testPath = "/private/" + UUID().uuidString
    do {
        try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(atPath: testPath)
        return true
    } catch {
        // 쓰기 실패는 정상
    }
    
    // URL scheme을 통한 Cydia 등 확인
    if let url = URL(string: "cydia://package/com.example.package"), UIApplication.shared.canOpenURL(url) {
        return true
    }
    
    // sandbox 경로가 비정상적인 경우
    if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Preferences") {
        return true
    }
    
    return false
#endif
}

// MARK: - Handler
func installTEEHandler(_ teeChannel: FlutterMethodChannel) {
    teeChannel.setMethodCallHandler { call, result in
        switch call.method {
            
        case "generateKey":
            guard let alias = stringArg(call, "alias"), !alias.isEmpty else {
                result(FlutterError(code: "ARG", message: "alias required or empty", details: nil))
                return
            }
            let userAuthRequired = boolArg(call, "userAuthRequired", true)
            do {
                // If a key already exists for this alias, delete it first, then create a new one
                if SecureEnclaveCrypto.loadPrivateKey(label: alias) != nil {
                   try SecureEnclaveCrypto.deleteKey(label: alias)
                }
                _ = try SecureEnclaveCrypto.generateSecureEnclaveKey(label: alias, userAuthRequired: userAuthRequired)
                result(nil)
            } catch {
                result(FlutterError(code:"GEN_FAIL", message: error.localizedDescription, details:nil))
            }
            
        case "encrypt":
            guard let alias = stringArg(call, "alias"), !alias.isEmpty else {
                result(FlutterError(code: "ARG", message: "alias required or empty", details: nil))
                return
            }
            let plaintext = readBytesArg(call, "plaintext")
            guard !plaintext.isEmpty else {
                result(FlutterError(code: "ARG", message: "plaintext empty", details: nil))
                return
            }
            
            do {
                guard let privateKey = try SecureEnclaveCrypto.loadPrivateKey(label: alias) else {
                    result(FlutterError(code:"PRV_KEY_NOT_FOUND", message: "private key not found", details:nil))
                  return
                }
                guard let publicKey = try SecureEnclaveCrypto.publicKey(from: privateKey) else {
                    result(FlutterError(code:"PUB_KEY_NOT_FOUND", message: "public key not found", details:nil))
                    return
                }
                let ciphertext = try SecureEnclaveCrypto.encrypt(with: publicKey, plaintext: plaintext)
                let response: [String: Any] = [
                    "ciphertext": FlutterStandardTypedData(bytes: ciphertext),
                    "alg": "ecies-x963-sha256-aesgcm"
                ]
                result(response)
            } catch {
                result(FlutterError(code:"ENC_FAIL", message: error.localizedDescription, details:nil))
            }
            
        case "decrypt":
            guard let alias = stringArg(call, "alias"), !alias.isEmpty else {
                result(FlutterError(code: "ARG", message: "alias required or empty", details: nil))
                return
            }
            let ciphertext = readBytesArg(call, "ciphertext")
            guard !ciphertext.isEmpty else {
                result(FlutterError(code: "ARG", message: "ciphertext empty", details: nil))
                return
            }
            
            do {
                guard let privateKey = try SecureEnclaveCrypto.loadPrivateKey(label: alias) else {
                    result(FlutterError(code:"PRV_KEY_NOT_FOUND", message: "private key not found", details:nil))
                    return
                }
                let plaintext = try SecureEnclaveCrypto.decrypt(with: privateKey, ciphertext: ciphertext)
                result(FlutterStandardTypedData(bytes: plaintext))
            } catch {
                result(FlutterError(code:"DEC_FAIL", message: error.localizedDescription, details:nil))
            }
            
        case "deleteKey":
            guard let alias = stringArg(call, "alias"), !alias.isEmpty else {
                result(FlutterError(code: "ARG", message: "alias required or empty", details: nil))
                return
            }

            do {
              try SecureEnclaveCrypto.deleteKey(label: alias)
              result(nil)
            } catch {
              result(FlutterError(code:"DEL_FAIL", message: error.localizedDescription, details:nil))
            }
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
}

private func readBytesArg(_ call: FlutterMethodCall, _ key: String) -> Data {
    guard let args = call.arguments as? [String: Any] else { return Data() }
    if let buf = args[key] as? FlutterStandardTypedData { return buf.data }
    if let arr = args[key] as? [UInt8] { return Data(arr) }
    return Data()
}

private func boolArg(_ call: FlutterMethodCall, _ key: String, _ def: Bool = false) -> Bool {
    ((call.arguments as? [String: Any])?[key] as? Bool) ?? def
}

private func stringArg(_ call: FlutterMethodCall, _ key: String) -> String? {
    (call.arguments as? [String: Any])?[key] as? String
}
