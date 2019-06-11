//
//  Helper.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 03/04/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import FirebaseDatabase

class Helper {
    
    struct Student {
        var name: String
        var id: String
        var verified: Bool
    }
    
    struct Admin {
        var name: String
        var signedPk: String
        var id: String
        var role: String
        var isMain: Bool
        var isVerified: Bool
        var updatedPassword: Bool
    }
    
    struct Request {
        var id: String
        var status: String
        var uid: String
        var index: Int
    }
    
    struct Documents {
        var url: URL
        var date: Date
    }
    
    func alertController(vc: UIViewController, title: String, message: String) {
        DispatchQueue.main.async {
            let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            vc.present(alertController, animated: true, completion: nil)
        }
    }

    func getPublicKey() throws -> SecKey? {
        do {
            let pk = try getPrivateKey()
            let newPublicKey = SecKeyCopyPublicKey(pk as! SecKey)
            return newPublicKey as! SecKey
        } catch {
            
        }
        return nil
    }
    
    func getPrivateKey() throws -> SecKey? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyClass as String: kSecAttrKeyClassPrivate,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecAttrApplicationTag as String: "com.DCApp.keys." + userEmail,
            kSecReturnRef as String: true
        ]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw error.runtimeError("Error")
        }
        return item as! SecKey
    }
    
    enum error: Error {
        case runtimeError(String)
    }

    
    func keyToString(k: SecKey) -> String? {
        var error: Unmanaged<CFError>?
        do {
            if let cfdata = SecKeyCopyExternalRepresentation(k, &error) {
                let data:Data = cfdata as Data
                let b64Key = data.base64EncodedString()
                return b64Key
            }
            return ""
        } catch {
            print("error")
            return ""
        }
    }
    
    func stringToKey(k: String) throws -> SecKey? {
        var error: Unmanaged<CFError>?
        do {
            guard let data = Data.init(base64Encoded: k) else {
                return nil
            }
            
            let keyDict:[String:Any] = [
                kSecClass as String: kSecClassKey,
                kSecAttrKeyClass as String: kSecAttrKeyClassPublic,
                kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
                kSecAttrKeySizeInBits as String: 256,
            ]
            
            guard let publicKeyTmp = SecKeyCreateWithData(data as CFData, keyDict as CFDictionary, nil) else {
                return nil
                
            }
            return publicKeyTmp as SecKey
        } catch {
            print("SOME ERROR")
        }
    }
    
    func sign(digest: Data) -> CFData? {
        var n: CFData?
            var error: Unmanaged<CFError>?
            do {
                let priv = try getPrivateKey()
                let signature = try SecKeyCreateSignature(priv!, .ecdsaSignatureMessageX962SHA256, digest as CFData, &error)
                print("signature of document", signature)
                return signature!
            }
            catch {
                print("COULDN'T SIGN")
            }
        return n
    }

    func encrypt(digest: Data, pk: SecKey) -> CFData? {
        var n: CFData?
        var error: Unmanaged<CFError>?
        do {
            let encrypted = try SecKeyCreateEncryptedData(pk, .eciesEncryptionStandardX963SHA256AESGCM, digest as CFData, &error)
            return encrypted!
        }
        catch {
            print("COULDN'T ENCRYPT")
        }
        return n
    }
    
    func decrypt(encrypted: Data) -> CFData {
        var n: CFData?
        var error: Unmanaged<CFError>?
        do {
            let pk = try getPrivateKey()
            let decrypted = SecKeyCreateDecryptedData(pk!, .eciesEncryptionStandardX963SHA256AESGCM, encrypted as CFData, &error)
            return decrypted!
        } catch {
            print("COULDN'T DECRYPT")
        }
        return n!
    }

    
    func generateKeys() {
        print("Generating keys")
        guard let accessControl =
            SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlocked,
                [],
                nil)
            else {
                fatalError("cannot set access control")
        }
        // 2. Create Key Attributes
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: "com.DCApp.keys." + userEmail,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        // 3. Generate Key Pairs
        var error: Unmanaged<CFError>?
        guard let newPrivateKey =
            SecKeyCreateRandomKey(attributes as CFDictionary, &error) else {
                print(error)
                return
        }
        let newPublicKey = SecKeyCopyPublicKey(newPrivateKey)
    }
    
    func deleteKeys() {
        guard let accessControl =
            SecAccessControlCreateWithFlags(
                kCFAllocatorDefault,
                kSecAttrAccessibleWhenUnlocked,
                [],
                nil)
            else {
                fatalError("cannot set access control")
        }
        let attributes: [String: Any] = [
            kSecClass as String: kSecClassKey,
            kSecAttrKeyType as String: kSecAttrKeyTypeECSECPrimeRandom,
            kSecAttrKeySizeInBits as String: 256,
            kSecPrivateKeyAttrs as String: [
                kSecAttrIsPermanent as String: true,
                kSecAttrApplicationTag as String: "com.DCApp.keys." + userEmail,
                kSecAttrAccessControl as String: accessControl
            ]
        ]
        SecItemDelete(attributes as CFDictionary)
    }
}
