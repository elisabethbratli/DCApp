/*
 See LICENSE folder for this sample’s licensing information.
 
 Abstract:
 Login view controller.
 */

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

var userEmail: String = ""

class ViewController: UIViewController {

    @IBOutlet weak var nameText: UITextField!
    @IBOutlet weak var studentNumberText: UITextField!
    @IBOutlet weak var eMail: UITextField!
    @IBOutlet weak var password: UITextField!
    @IBOutlet weak var verifyPassword: UITextField!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    
    @IBAction func goToLogIn(_ sender: Any) {
        performSegue(withIdentifier: "logInSegue", sender: self)
    }
    
    @IBAction func createMainAdmin(_ sender: Any) {
        guard let emailText = eMail.text, !emailText.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter your email.")
            return }
        
        guard let passwordText = password.text, !passwordText.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter a password.")
            return }
        
        if (verifyPassword.text != password.text) {
            Helper().alertController(vc: self, title: "Error", message: "Passwords are not identical.")
            return }
        
        guard let name = nameText.text, !name.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter your name.")
            return }
        
        let id = "0"
        
        if emailText != "" && passwordText != "" {
            Auth.auth().createUser(withEmail: emailText, password: passwordText, completion: { (user, error) in
                if error == nil {
                    userEmail = emailText
                    Helper().generateKeys()
                    let data = Helper.Admin(name: name, signedPk: "", id: id, role: "main", isMain: true, isVerified: true, updatedPassword: true)
                    self.saveAdmin(data: data, uid: (user?.user.uid)!)
                    Helper().alertController(vc: self, title: "Main admin created", message: "Go to log in to sign in with the main admin.")
                } else {
                    Helper().alertController(vc: self, title: "Error", message: error?.localizedDescription ?? "")
                    print("An error occured. Sorry about that...")
                    print(error)
                }
            })
        }
    }
    
    func saveAdmin(data: Helper.Admin, uid: String) {
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
    
    @IBAction func createUser(_ sender: Any) {
        guard let emailText = eMail.text, !emailText.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter your email.")
            return }
        
        guard let passwordText = password.text, !passwordText.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter a password.")
            return }
        
        if (verifyPassword.text != password.text) {
            Helper().alertController(vc: self, title: "Error", message: "Passwords are not identical.")
            return }
        
        guard let name = nameText.text, !name.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter your name.")
            return }
        
        guard let studentNumber = studentNumberText.text, !studentNumber.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter a valid student number.")
            return }

        if emailText != "" && passwordText != "" {
            Auth.auth().createUser(withEmail: emailText, password: passwordText, completion: { (user, error) in
                if error == nil {
                    userEmail = emailText
                    //Helper().generateKeys()
                    let data = Helper.Student(name: name, id: studentNumber, verified: false)
                    self.saveUserToDB(data: data, uid: (user?.user.uid)!)
                    self.performSegue(withIdentifier: "signUpSegue2", sender: self)
                } else {
                    Helper().alertController(vc: self, title: "Error", message: error?.localizedDescription ?? "")
                    print("An error occured. Sorry about that...")
                    print(error)
                }
            })
        }
    }
    
    func saveUserToDB(data: Helper.Student, uid: String) {
        let db = Firestore.firestore()
        db.collection("students").document(uid).setData([
            "studentId": data.id,
            "name": data.name,
            "verified": data.verified
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                print("Document added with ID: \(uid)")
            }
        }
    }
}
