//
//  LogIn.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 21/02/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import UIKit
import Firebase
import FirebaseDatabase
import FirebaseFirestore

var isAdmin: Bool = false

class LogIn: UIViewController {
    
    @IBOutlet weak var eMailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    
    override func viewDidLoad() {
        isAdmin = false
        super.viewDidLoad()
    }
    
    @IBAction func goToSignIn(_ sender: Any) { //TODO: change to sign UP
        performSegue(withIdentifier: "signUpSegue", sender: self)
    }
    
    @IBAction func signIn(_ sender: Any) {
        guard let email = eMailTextField.text, !email.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter your email.")
            return }
        guard let password = passwordTextField.text, !password.isEmpty else {
            Helper().alertController(vc: self, title: "Error", message: "Please enter a password.")
            return }
        
            Auth.auth().signIn(withEmail: email, password: password) { (user, error) in
                if let error = error {
                    print(error.localizedDescription)
                    Helper().alertController(vc: self, title: "Error", message: "Username or password is incorrect.")
                    return
                }
                else if user != nil {
                    userEmail = email
                    //Helper().generateKeys()
                    let currentUserUID = Auth.auth().currentUser!.uid
                    let db = Firestore.firestore()
                    var ref = db.collection("students").document(currentUserUID)
                    
                    ref.getDocument { (document, error) in
                        if let document = document, document.exists {
                            ref.getDocument(source: .cache) { (document, error) in
                                if let document = document {
                                    let verified: Bool! = document.get("verified") as? Bool //TODO: skal det være as eller as? ?
                                    if verified {
                                        if (try! Helper().getPublicKey() == nil) {
                                            DispatchQueue.main.async {
                                                do {
                                                    try Auth.auth().signOut()
                                                } catch let signOutError as NSError {
                                                    print ("Error signing out: %@", signOutError)
                                                }
                                            }
                                            Helper().alertController(vc: self, title: "Wrong device / user", message: "This user does not have any cryptographic keys associated with this device." )
                                        } else {
                                            self.performSegue(withIdentifier: "verifiedStudentSegue", sender: self)
                                        }
                                    } else {
                                        self.performSegue(withIdentifier: "logInStudentSegue", sender: self)
                                    }
                                } else {
                                    print("Document does not exist in cache")
                                }
                            }
                        } else {
                            ref = db.collection("admins").document(currentUserUID)
                            ref.getDocument { (document, error) in
                                if let document = document, document.exists {
                                    isAdmin = true
                                    self.performSegue(withIdentifier: "logInUniSegue", sender: self)
                                } else {
                                    print("Document does not exist")
                                    Helper().alertController(vc: self, title: "Error", message: "The user does not exist.")
                                    return
                                }
                            }
                        }
                    }
                }
            }
        }
    }
