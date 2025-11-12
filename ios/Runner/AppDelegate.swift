import UIKit
import Flutter
import LocalAuthentication
import Foundation
import Darwin

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
        let teeChannel = FlutterMethodChannel(name: "onl.coconut.vault/secure_module", binaryMessenger: controller.binaryMessenger)
        
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
    let testPath = "/private/" + UUID().uuidString
    do {
        try "test".write(toFile: testPath, atomically: true, encoding: .utf8)
        try FileManager.default.removeItem(atPath: testPath)
        return true
    } catch {
        // 정상
    }

    let jailbreakPaths = [
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/bin/bash",  
        "/usr/sbin/sshd",  
        "/etc/apt",  
        "/private/var/lib/apt/",  
        "/private/var/lib/cydia",  
        "/private/var/mobile/Library/SBSettings", 
        "/private/var/tmp/cydia.log",  
        "/Applications/RockApp.app", 
        "/Applications/Icy.app",
        "/Applications/MxTube.app",
        "/Applications/IntelliScreen.app",
        "/Applications/FakeCarrier.app",
        "/Applications/WinterBoard.app",
        "/usr/libexec/cydia",
        "/usr/libexec/ssh-keysign",
        "/usr/bin/cycript",
        "/usr/local/bin/cycript",
        "/usr/lib/libcycript.dylib",
        "/System/Library/LaunchDaemons/com.ikey.bbot.plist",
        "/System/Library/LaunchDaemons/com.saurik.Cydia.Startup.plist",
        "/bin/sh",  
        "/usr/bin/ssh", 
        "/var/lib/cydia", 
        "/var/cache/apt", 
        "/var/lib/apt", 
        "/var/log/syslog",
        "/etc/ssh/sshd_config", 
        "/private/etc/apt",
        "/private/var/lib/dpkg",
        "/private/var/lib/apt", 
        "/private/var/mobile/Library/SBSettings/Themes",
        "/private/var/stash",
        "/private/var/cache/apt",
        "/private/var/lib/apt",
        "/private/var/mobile/Library/Caches/com.apple.mobile.installation.plist", 
        "/private/var/mobile/Library/Preferences/com.saurik.Cydia.plist",
        "/private/var/root/Library/Caches/com.apple.mobile.installation.plist"
    ]
    if jailbreakPaths.contains(where: { FileManager.default.fileExists(atPath: $0) }) {
        return true
    }
    
    let jailbreakURLs = [
        "cydia://",  
        "sileo://",  
        "zbra://", 
        "installer://", 
        "sileo://package"
    ]
    for urlString in jailbreakURLs {
        if let url = URL(string: urlString), UIApplication.shared.canOpenURL(url) {
            return true
        }
    }
    
    if !FileManager.default.fileExists(atPath: NSHomeDirectory() + "/Library/Preferences") {
        return true
    }

    let systemPaths = [
        "/Applications",
        "/usr/libexec",
        "/usr/bin",
        "/bin"
    ]
    for path in systemPaths {
        if FileManager.default.isWritableFile(atPath: path) {
            return true
        }
    }

    let suspiciousLibraries = [
        "/Library/MobileSubstrate/MobileSubstrate.dylib",
        "/usr/lib/libsubstrate.dylib",
        "/usr/lib/libsubstrate.0.dylib"
    ]
    for libPath in suspiciousLibraries {
        if FileManager.default.fileExists(atPath: libPath) {
            if dlopen(libPath, RTLD_NOW) != nil {
                dlclose(dlopen(libPath, RTLD_NOW)!)
                return true
            }
        }
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
            } catch let error as NSError {
                if error.domain == LAErrorDomain {
                    switch error.code {
                        case LAError.userCancel.rawValue:
                            // 사용자가 생체인증 취소 버튼 클릭
                            result(FlutterError(code:"USER_CANCEL", message: "User cancelled biometric authentication", details:nil))
                        default:
                            result(FlutterError(code:"DEC_FAIL", message: error.localizedDescription, details:nil))
                    }
                }
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
        
        case "deleteKeys":
            guard let args = call.arguments as? [String: Any],
                  let aliasList = args["aliasList"] as? [String] else {
                result(FlutterError(code: "ARG", message: "alias list required", details: nil))
                return
            }

            guard !aliasList.isEmpty else {
                result(nil)
                return
            }
            
            do {
                try SecureEnclaveCrypto.deleteKeys(labels: aliasList)
                result(nil)
            } catch {
                result(FlutterError(code:"DEL_KEYS_FAIL", message: error.localizedDescription, details:nil))
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
