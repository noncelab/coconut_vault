//
//  SecureEnclaveCrypto.swift
//  Runner
//
//  Created by 임은지 on 10/17/25.
//
// SecureEnclaveCrypto.swift
import Foundation
import Security

enum SecureEnclaveError: Error {
    case algorithmNotSupported
}

final class SecureEnclaveCrypto {

    // 1) 키 생성 (P-256, Secure Enclave)
    static func generateSecureEnclaveKey(label: String, userAuthRequired: Bool) throws -> SecKey {
        // kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly: 패스코드 필수, 이 기기 외에서 복원 불가
        // .userPresence: 사용자 인증(Face ID / Touch ID / 패스코드) 없이 사용 불가
        let access = SecAccessControlCreateWithFlags(
            nil,
            kSecAttrAccessibleWhenPasscodeSetThisDeviceOnly,
            userAuthRequired ? [.privateKeyUsage, .userPresence] : [.privateKeyUsage],
            nil
        )!

        let attributes: [String: Any] = [
            kSecAttrKeyType as String:            kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String:      256,
            kSecAttrTokenID as String:            kSecAttrTokenIDSecureEnclave,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String:    true,
                kSecAttrApplicationTag as String: label.data(using: .utf8)!,
                kSecAttrAccessControl as String:  access
            ]
        ]

        var error: Unmanaged<CFError>?
        guard let privateKey = SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
            throw (error!.takeRetainedValue() as Error)
        }
        print("✅ [Secure Enclave] 키 생성 성공: \(privateKey)")
        return privateKey
    }

    // 2) 공개키 가져오기
    // Secure Enclave 내부에는 privateKey만 존재
    // 공개키는 필요할 때마다 추출해서 사용 가능
    static func publicKey(from privateKey: SecKey) -> SecKey? {
        return SecKeyCopyPublicKey(privateKey)
    }

    // 3) 공개키로 암호화 (ECIES / AES-GCM hybrid)
    static func encrypt(with publicKey: SecKey, plaintext: Data) throws -> Data {
        let alg = SecKeyAlgorithm.eciesEncryptionCofactorX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(publicKey, .encrypt, alg) else {
            throw SecureEnclaveError.algorithmNotSupported
        }
        var error: Unmanaged<CFError>?
        guard let cipher = SecKeyCreateEncryptedData(publicKey, alg, plaintext as CFData, &error) else {
            throw (error!.takeRetainedValue() as Error)
        }
        return cipher as Data
    }

    // 4) 개인키로 복호화
    static func decrypt(with privateKey: SecKey, ciphertext: Data) throws -> Data {
        let alg = SecKeyAlgorithm.eciesEncryptionCofactorX963SHA256AESGCM
        guard SecKeyIsAlgorithmSupported(privateKey, .decrypt, alg) else {
            throw SecureEnclaveError.algorithmNotSupported
        }
        var error: Unmanaged<CFError>?
        guard let plain = SecKeyCreateDecryptedData(privateKey, alg, ciphertext as CFData, &error) else {
            throw (error!.takeRetainedValue() as Error)
        }
        return plain as Data
    }

    // (옵션) 같은 label로 이미 만든 키 재사용하고 싶을 때
    static func loadPrivateKey(label: String) -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String:             kSecClassKey,
            kSecAttrKeyType as String:       kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrApplicationTag as String: label.data(using: .utf8)!,
            kSecReturnRef as String:         true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        print("load status: \(status)")
        return status == errSecSuccess ? (item as! SecKey) : nil
    }

    static func deleteKey(label: String) throws {
        let query: [String: Any] = [
            kSecClass as String:             kSecClassKey,
            kSecAttrKeyType as String:        kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrApplicationTag as String: label.data(using: .utf8)!,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
             throw NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                            userInfo: [NSLocalizedDescriptionKey: "Failed to delete key (\(status))"])
        }
        print("✅ [Secure Enclave] 키 삭제 성공: \(label)")
    }

    // Delete all Secure Enclave EC keys owned by this app
    static func deleteAllKeys() throws {
        let query: [String: Any] = [
            kSecClass as String:             kSecClassKey,
            kSecAttrKeyType as String:        kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrTokenID as String:        kSecAttrTokenIDSecureEnclave,
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
             throw NSError(domain: NSOSStatusErrorDomain, code: Int(status),
                            userInfo: [NSLocalizedDescriptionKey: "Failed to delete key (\(status))"])
        }
        print("✅ [Secure Enclave] 모든 키 삭제 성공")
    }
}
