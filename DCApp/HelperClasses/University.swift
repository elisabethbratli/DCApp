//
//  ViewController.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 10/02/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import UIKit
import LocalAuthentication
import FirebaseFirestore
import FirebaseAuth

var document = "Example document. This would normally containt the contents of the requested file."


class University {
    
    var signedPK: Data? //signed student key
    let db = Firestore.firestore()
    var context: LAContext! = LAContext()
    
    func addStudent(pkData: Data, pk: String, id: String){
        do {
            let signature = Helper().sign(digest: pkData)
            print("signature of student", signature)
            var ref: DocumentReference? = nil
            ref = self.db.collection("verifiedStudents").addDocument(data: [
                    "pkSigned": signature,//String(decoding: signature as! Data, as: UTF8.self),
                    "studentId": id,
                    "publicKey": pk
                ]) { err in
                    if let err = err {
                        print("Error adding document: \(err)")
                    } else {
                        print("Document added with ID: \(ref!.documentID)")
                        self.verifyStudent(id: id)
                }
            }
        }
        catch {
            print("COULDN'T ADD STUDENT")
        }
    }
    
    func verifyStudent(id: String) {
        db.collection("students").whereField("studentId", isEqualTo: id).getDocuments()
        {
            (querySnapshot, err) in
            if let err = err
            {
                print("Error getting documents: \(err)");
            } else {
                for document in querySnapshot!.documents {
                    self.db.collection("students").document(document.documentID).updateData([
                        "verified": true
                    ]) { err in
                        if let err = err {
                            print("Error updating document: \(err)")
                        } else {
                            print("Document successfully updated")
                        }
                    }
                }
            }
        }
    }
    
    func sendDataStep1(id: String, vc: UIViewController, title: String, uid: String) {
        db.collection("verifiedStudents").whereField("studentId", isEqualTo: id).getDocuments()
            {
                (querySnapshot, err) in
                if let err = err
                {
                    print("Error getting documents: \(err)");
                } else {
                    for document in querySnapshot!.documents {
                        var pk = document.get("publicKey") as! String
                        //var pkSigned = document.get("pkSigned")
                        let signature = Helper().sign(digest: pk.data(using: .utf8)!)
                        let s = signature as! Data
                        let b64s = s.base64EncodedString()
                        self.sendDataStep2(pk: pk, pkSigned: b64s, vc: vc, id: id, title: title, uid: uid)
                    }
                }
            }
    }
    
    func sendDataStep2(pk: String, pkSigned: String, vc: UIViewController, id: String, title: String, uid: String) {
        do {
            let signature = Helper().sign(digest: document.data(using: .utf8)!)//sign the document
            let s = signature as! Data
            let b64s = s.base64EncodedString()
            self.sendDataStep3(s1: pkSigned, s2: b64s, pk: pk, vc: vc, id: id, title: title, uid: uid)
        }
        catch {
            print("some error")
        }
    }
    
    func sendDataStep3(s1: String, s2: String, pk: String, vc: UIViewController, id: String, title: String, uid: String) { //signing document
        do {
            let uniPk = try Helper().getPublicKey()
            let uniPkString = Helper().keyToString(k: uniPk!)
            let studPk = try Helper().stringToKey(k: pk)
            var dataString = "document:" + document + ",sig1:" + s1 + ",sig2:" + s2 + ",uniPk:"
            dataString += uniPkString!
            let encrypted = Helper().encrypt(digest: dataString.data(using: .utf8)!, pk: studPk!)
            let data = AirDrop(pk: uid, pkData: encrypted as! Data, fileName: title, fileType: "doc")
            let dataToShare = data.exportToFileURL(spkData: encrypted as! Data, spk: uid, sFileName: title, sFileType: "doc")
            let controller = UIActivityViewController(activityItems: [dataToShare!], applicationActivities: nil)
            vc.present(controller, animated: true, completion: nil)
        } catch {
            print("some error")
        }
    }

    func addAdmin(pkData: Data, pk: String, id: String) { //only reachable by main admin
        if (isMainAdmin) {
            let signature = Helper().sign(digest:  pk.data(using: .utf8)!)
            self.db.collection("admins").whereField("id", isEqualTo: id).getDocuments()
                {
                    (querySnapshot, err) in
                    if let err = err
                    {
                        print("Error getting documents: \(err)");
                    } else {
                        for document in querySnapshot!.documents {
                            self.db.collection("admins").document(document.documentID).updateData([
                                "signedPk": signature,
                                "verified": true
                            ]) { err in
                                if let err = err {
                                    print("Error updating document: \(err)")
                                } else {
                                    print("Document successfully updated")
                                }
                            }
                        }
                    }
            }
        }
    }
    
}

