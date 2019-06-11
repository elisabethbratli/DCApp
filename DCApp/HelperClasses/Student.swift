//
//  ViewController.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 10/02/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import UIKit
import LocalAuthentication


class Student {
    
    var context: LAContext! = LAContext()
    
    func sendDocument(vc: UIViewController, data: String) {
        let arr1 = data.components(separatedBy: ",uniPk:")
        let uniPk = arr1[1]
        let arr2 = arr1[0].components(separatedBy: ",sig2:")
        let sig2 = arr2[1]
        let arr3 = arr2[0].components(separatedBy: ",sig1:")
        let sig1 = arr3[1]
        let arr4 = arr3[0].components(separatedBy: "document:")
        let doc = arr4[1]
        guard let s = Data.init(base64Encoded: sig1) else {
            return
        }
        let studSig = Helper().sign(digest: s)
        
        let ver1 = verify(sig: sig2, pk: uniPk, org: doc)
        let pk = try! Helper().getPublicKey()
        let pkString = Helper().keyToString(k: pk!)
        let ver2 = verify(sig: sig1, pk: uniPk, org: pkString!)
        let ver3 = verify2(sig: studSig!, pk: pk!, org: sig1)
        handleResult(v1: ver1, v2: ver2, v3: ver3, vc: vc)
    }
    
    func handleResult(v1: Bool, v2: Bool, v3: Bool, vc: UIViewController) {
        if (v1 && v2 && v3) {
            Helper().alertController(vc: vc, title: "VERIFIED DOCUMENT!", message: "✅ " + docName + ". All verification processes were successful.")
        } else {
            let title = "Could not verify..."
            var unver = ""
            if (!v2) {
                unver += "signature of student public key"
            }
            if (!v1) {
                unver += "signature of document"
            }
            if (!v3) {
                unver += ", student signature"
            }
            let message = "❌ " + docName + ". The following signatures could not be verified: " + unver
            Helper().alertController(vc: vc, title: "UNVERIFIED DOCUMENT!", message: message)
        }
    }

    func verify2(sig: CFData, pk: SecKey, org: String) -> Bool {
        var error: Unmanaged<CFError>?
        do {
            guard let org1 = Data.init(base64Encoded: org) else {
                return false
            }
            let ver = try SecKeyVerifySignature(pk, .ecdsaSignatureMessageX962SHA256, org1 as! CFData, sig, &error)
            return ver
        } catch {
            print("Something went wrong")
        }
        return false
    }
    
    func verify(sig: String, pk: String, org: String) -> Bool {
        var error: Unmanaged<CFError>?
        do {
            let pubKey = try Helper().stringToKey(k: pk)
            let org1 = org.data(using: .utf8)
            guard let signature = Data.init(base64Encoded: sig) else {
                return false
            }
            let ver = try SecKeyVerifySignature(pubKey!, .ecdsaSignatureMessageX962SHA256, org1 as! CFData, signature as! CFData, &error)
            return ver
        } catch {
            print("Something went wrong")
        }
        return false
    }


}

