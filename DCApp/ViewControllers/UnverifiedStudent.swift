//
//  SignUp.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 15/02/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import UIKit
import Firebase
import LocalAuthentication
import FirebaseFirestore

class SignedInStudent: UIViewController {
    var studentInfo: AirDrop?
    var student: Student?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        student = Student()
    }
    
    @IBAction func signOut(_ sender: Any) {
        DispatchQueue.main.async {
            do {
                try Auth.auth().signOut()
                self.performSegue(withIdentifier: "logOutSegue", sender: self)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
    }
    
    var context = LAContext()
    
    @IBAction func connectToUni(_ sender: Any) {
        var error: NSError?
        context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in
                if success {
                    self.sendPK()
                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    self.signOut(self) //TODO: bare signerer brukeren ut. Skal vi ha noe annet kanskje?
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            self.signOut(self)
        }
    }
    
    func sendPK() {
        var error: Unmanaged<CFError>?
        var pkData: SecKey?
        var pk: String?
        var data: Data?
        
        do {
            pkData = try Helper().getPublicKey()
            if (pkData == nil) {
                Helper().generateKeys()
                pkData = try Helper().getPublicKey()
            }
            pk = Helper().keyToString(k: pkData!)
            data = SecKeyCopyExternalRepresentation(pkData!, &error) as! Data
        } catch {
            print("ERROR")
        }
        let db = Firestore.firestore()
        let currentUserUID = Auth.auth().currentUser!.uid
        let ref = db.collection("students").document(currentUserUID)
        ref.getDocument(source: .cache) { (document, error) in
            if let document = document {
                let id = document.get("studentId")
                self.studentInfo = AirDrop(pk: pk!, pkData: data!, fileName: id as! String, fileType: "student")
                let dataToShare = self.studentInfo!.exportToFileURL(spkData: data!, spk: pk!, sFileName: id as! String, sFileType: "student")
                let controller = UIActivityViewController(activityItems: [dataToShare!], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            } else {
                print("Document does not exist")
            }
        }
    }
    

}
