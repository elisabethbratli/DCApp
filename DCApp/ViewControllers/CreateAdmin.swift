//
//  CreateAdmin.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 10/04/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import UIKit
import Firebase
import LocalAuthentication
import FirebaseFirestore

class CreateAdmin: UIViewController {

    @IBOutlet weak var nameTextField: UITextField!
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var roleTextField: UITextField!
    @IBOutlet weak var idTextField: UITextField!
    @IBOutlet weak var pwdTextField: UITextField!
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    @IBAction func cancel(_ sender: Any) {
        self.performSegue(withIdentifier: "backToAdminSegue", sender: self)
    }
    
    @IBAction func createAdmin(_ sender: Any) {
         let name = nameTextField.text
         let email = emailTextField.text
         let role = roleTextField.text
         let id = idTextField.text
         let password = pwdTextField.text
        if (name == "" || email == "" || role == "" || id == "" || password == "") {
            let alertController = UIAlertController(title: "Please fill in all fields.", message: "All fields must have a value", preferredStyle: .alert)
            let defaultAction = UIAlertAction(title: "OK", style: .cancel, handler: nil)
            alertController.addAction(defaultAction)
            self.present(alertController, animated: true, completion: nil)
            return
         } else {
            let alert = UIAlertController(title: "Are you sure your want to create a new admin?", message: "", preferredStyle: .alert)
            let submit = UIAlertAction(title: "Yes", style: .default, handler: { (action) -> Void in
                let newAdmin = Helper.Admin(name: name!, signedPk: "", id: id!, role: role!, isMain: false, isVerified: false, updatedPassword: false)
                self.saveAdmin(admin: newAdmin, email: email!, password: password!)
            })
            let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
            })
            alert.addAction(cancel)
            alert.addAction(submit)
            present(alert, animated: true, completion: nil)
        }
    }
    
    var context = LAContext()
    func saveAdmin(admin: Helper.Admin, email: String, password: String) { //https://codeburst.io/biometric-authentication-using-swift-bb2a1241f2be
        var newUID: String = ""
        context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthentication, error: &error) {
            let reason = "Authenticate"
            context.evaluatePolicy(.deviceOwnerAuthentication, localizedReason: reason ) { success, error in
                if success {
                    Auth.auth().createUser(withEmail: email, password: password, completion: { (user, error) in
                        if error == nil {
                            newUID = (user?.user.uid)!
                            self.backToAdmin(admin: admin, newUID: newUID)
                        } else {
                            Helper().alertController(vc: self, title: "Error", message: error?.localizedDescription ?? "")
                            print(error as Any)
                            return
                        }
                    })

                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    SingedInUni().signOut(self)
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            SingedInUni().signOut(self)
        }
        
        
    }
    
    func backToAdmin(admin: Helper.Admin, newUID: String) {
        try! Auth.auth().signOut()
        Auth.auth().signIn(withEmail: "bratli95@gmail.com", password: "sisisi") { (user, error) in
            if let error = error {
                print(error.localizedDescription)
                Helper().alertController(vc: self, title: "Error", message: "Ooops... Something went wrong.")
                return
            } else if user != nil {
                self.saveUserToDB(data: admin, uid: newUID)
                self.performSegue(withIdentifier: "backToAdminSegue", sender: self)
            }
        }
    }
    
    func saveUserToDB(data: Helper.Admin, uid: String) {
        let db = Firestore.firestore()
        db.collection("admins").document(uid).setData([
            "name": data.name,
            "signedPk": data.signedPk,
            "role": data.role,
            "id": data.id,
            "isMain": data.isMain,
            "isVerified": data.isVerified,
            "updatedPassword": data.updatedPassword
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(uid)")
            }
        }
    }

}
