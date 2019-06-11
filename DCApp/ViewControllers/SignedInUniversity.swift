//
//  SignedInUni.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 09/04/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import Foundation
import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore
import LocalAuthentication

var isMainAdmin = false

class SingedInUni: UIViewController, UITableViewDataSource, UITableViewDelegate {
    
    override func viewDidLoad() {
        let currentUser = Auth.auth().currentUser
        uni = University()
        if (currentUser != nil && isAdmin) {
            let db = Firestore.firestore()
            let ref = db.collection("admins").document(currentUser!.uid)
            ref.getDocument(source: .cache) { (document, error) in
                if let document = document {
                    let isMain: Bool! = document.get("isMain") as? Bool
                    if isMain {
                        if (try! Helper().getPublicKey() == nil) {
                            let alert = UIAlertController(title: "Wrong device / user", message: "This user does not have any cryptographic keys associated with this device.", preferredStyle: .actionSheet)
                            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                self.signOut(self)
                            }))
                            self.present(alert, animated: true, completion: {
                            })
                        }
                        isMainAdmin = true
                        self.createAdminButton.isHidden = false
                    } else {
                        isMainAdmin = false
                        self.createAdminButton.isHidden = true
                        self.verifyAdminButton.isHidden = true
                        let verified: Bool! = document.get("isVerified") as? Bool
                        if !verified {
                            self.tableViewContainer.isHidden = true
                            self.verifyAdminButton.isHidden = false
                        } else {
                            if (try! Helper().getPublicKey() == nil) {
                                let alert = UIAlertController(title: "Wrong device / user", message: "This user does not have any cryptographic keys associated with this device.", preferredStyle: .actionSheet)
                                alert.addAction(UIAlertAction(title: "OK", style: .default, handler: { (_) in
                                    self.signOut(self)
                                }))
                                self.present(alert, animated: true, completion: {
                                })
                            }
                        }
                        let updatedPassword: Bool = document.get("updatedPassword") as? Bool ?? true
                        if !updatedPassword {
                            self.verifyAdminButton.isHidden = false
                            self.updatePassword()
                        }
                    }
                }
            }
        }
        listenToUpdates()
        super.viewDidLoad()
    }
    
    func editRequest(req: Helper.Request) {
        //https://medium.com/swift-india/uialertcontroller-in-swift-22f3c5b1dd68
        let alert = UIAlertController(title: "Document request from " + req.id, message: "Please select an option", preferredStyle: .actionSheet)
        if (req.status != "accepted") {
            alert.addAction(UIAlertAction(title: "Accept", style: .default, handler: { (_) in
                self.biometrics(req: req, newStatus: "accepted")
            }))
        }
        
        if (req.status != "completed") {
            alert.addAction(UIAlertAction(title: "Sign and send", style: .default, handler: { (_) in
                self.nameDoc(req: req)
            }))
        }
        
        if (req.status != "cancelled") {
            alert.addAction(UIAlertAction(title: "Cancel request", style: .destructive, handler: { (_) in
                self.biometrics(req: req, newStatus: "cancelled")
            }))
        }
        
        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
        }))
        
        self.present(alert, animated: true, completion: {
            print("completion block")
        })
    }
    
    func nameDoc(req: Helper.Request) { //https://code.tutsplus.com/tutorials/create-a-custom-alert-controller-in-ios-10-swift-3--cms-27589
        let alert = UIAlertController(title: "Name the document." ,message: "The name should be descriptive.", preferredStyle: .alert)
        let loginAction = UIAlertAction(title: "OK", style: .default, handler: { (action) -> Void in
            let title = alert.textFields![0]
            if ((title.text)!.count > 0) {
                self.biometrics(req: req, newStatus: "completed", docName: title.text!)
            } else {
                Helper().alertController(vc: self, title: "Enter a title.", message: "Title cannot be empty.")
            }
        })
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
        })
        alert.addTextField { (textField: UITextField) in
            textField.keyboardAppearance = .dark
            textField.keyboardType = .default
            textField.placeholder = "Title"
            textField.isSecureTextEntry = false
        }
        alert.addAction(loginAction)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
    
    func biometrics(req: Helper.Request, newStatus: String, docName: String = "") { //https://codeburst.io/biometric-authentication-using-swift-bb2a1241f2be
        let db = Firestore.firestore()
        context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in
                if success {
                    if (newStatus == "completed") {
                        University().sendDataStep1(id: req.id, vc: self, title: docName, uid: req.uid)
                    } else {
                        db.collection("requestss").document(req.uid).setData([ "status": newStatus ], merge: true) //TODO: dette må gjøres etter dokumentet har blitt sent feks
                    }
                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    self.signOut(self)
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            self.signOut(self)
        }
    }
    
    @IBAction func verifyAdminStatus(_ sender: Any) {
        var error: NSError?
        context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in
                if success {
                    self.sendPK()
                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    self.signOut(self)
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            self.signOut(self)
        }
    }
    
    var context = LAContext()

    func sendPK() {
        var pk: SecKey?
        var pkString = ""
        do {
            pk = try Helper().getPublicKey()
            if (pk == nil) {
                Helper().generateKeys()
                pk = try Helper().getPublicKey()
            }
            pkString = Helper().keyToString(k: pk!)!
        } catch {
                print("Error")
        }
        
        let db = Firestore.firestore()
        let currentUserUID = Auth.auth().currentUser!.uid
        let ref = db.collection("admins").document(currentUserUID)
        ref.getDocument(source: .cache) { (document, error) in
            if let document = document {
                let id = document.get("id")
                let pkData = pkString.data(using: .utf8)
                self.adminInfo = AirDrop(pk: pkString, pkData: pkData!, fileName: id as! String, fileType: "admin")
                let dataToShare = self.adminInfo!.exportToFileURL(spkData: pkData!, spk: pkString, sFileName: id as! String, sFileType: "admin")
                let controller = UIActivityViewController(activityItems: [dataToShare!], applicationActivities: nil)
                self.present(controller, animated: true, completion: nil)
            } else {
                print("Document does not exist")
            }
        }
    }

    
    @IBAction func signOut(_ sender: Any) {
        DispatchQueue.main.async {
            do {
                try Auth.auth().signOut()
                isMainAdmin = false
                isAdmin = false
                self.performSegue(withIdentifier: "logOutSegueUni", sender: self)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
    }
    
    var adminInfo: AirDrop?
    var uni: University?
    
    func listenToUpdates() {
        let db = Firestore.firestore()
        db.collection("requestss")
            .addSnapshotListener { querySnapshot, error in
                guard let snapshot = querySnapshot else {
                    print("Error fetching snapshots: \(error!)")
                    return
                }
                snapshot.documentChanges.forEach { diff in
                    if (diff.type == .added || diff.type == .modified || diff.type == .removed) {
                        self.loadRequests()
                    }
                }
        }
    }
    
    func loadRequests() {
        let db = Firestore.firestore()
        db.collection("requestss").getDocuments() { (querySnapshot, err) in
            if let err = err {
                print("Error getting documents: \(err)")
            } else {
                self.myarray.removeAll()
                for document in querySnapshot!.documents {
                    var index = 4
                    switch document.get("status") as! String {
                    case "pending":
                        index = 0
                    case "accepted":
                        index = 1
                    case "completed":
                        index = 2
                    case "cancelled":
                        index = 3
                    default:
                        break
                    }
                    let req = Helper.Request(id: document.get("id") as! String, status: document.get("status") as! String, uid: document.documentID, index: index)
                    self.myarray.append(req)
                }
                self.organize()
            }
        }
    }
    
    func organize() {
        myarray = myarray.sorted(by: { $0.index < $1.index })
        self.tableViewContainer.reloadData()
    }
    
    @IBOutlet weak var tableViewContainer: UITableView!
    @IBOutlet weak var verifyAdminButton: UIButton!
    @IBOutlet weak var createAdminButton: UIButton!
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return myarray.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "exampleCell", for: indexPath) as! UITableViewCell
        
        cell.textLabel?.text = "Student ID: " + myarray[indexPath.item].id + "\nStatus: " + myarray[indexPath.item].status
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping
        switch myarray[indexPath.item].status {
        case "pending":
            cell.backgroundColor = UIColor(hue: 0.1944, saturation: 0, brightness: 0.82, alpha: 1.0)
        case "accepted":
            cell.backgroundColor = UIColor(hue: 0.1556, saturation: 1, brightness: 0.92, alpha: 1.0)
        case "completed":
            cell.backgroundColor = UIColor(hue: 0.2111, saturation: 1, brightness: 0.81, alpha: 1.0) /* #97ce00 */
        case "cancelled":
            cell.backgroundColor = UIColor(hue: 0.0639, saturation: 1, brightness: 0.97, alpha: 1.0)
        default:
            break
        }
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 5
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        return cell
    }
    var myarray: [Helper.Request] = []
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = myarray[indexPath.item]
        editRequest(req: element)
    }
    
    func updatePassword() { //https://code.tutsplus.com/tutorials/create-a-custom-alert-controller-in-ios-10-swift-3--cms-27589
        let alert = UIAlertController(title: "Update password" ,message: "Enter a secure password.", preferredStyle: .alert)
        let loginAction = UIAlertAction(title: "Update", style: .default, handler: { (action) -> Void in
            let password = alert.textFields![0]
            let passwordVerified = alert.textFields![1]
            if ((password.text)!.count > 5 && password.text == passwordVerified.text) {
                let currentUser = Auth.auth().currentUser
                currentUser?.updatePassword(to: password.text!, completion: { (error) in
                    if error != nil {
                        Helper().alertController(vc: self, title: "Something went wrong.", message: "")
                    } else {
                        let db = Firestore.firestore()
                        db.collection("admins").document(currentUser!.uid).setData([ "updatedPassword": true ], merge: true)
                        print("updated password")
                    }
                })
            } else {
                Helper().alertController(vc: self, title: "Passwords must be identical.", message: "The password must be at least 5 characters.")
            }
            
        })
        let cancel = UIAlertAction(title: "Cancel", style: .destructive, handler: { (action) -> Void in
            try! Auth.auth().signOut()
            self.performSegue(withIdentifier: "logOutSegueUni", sender: self)
        })
        alert.addTextField { (textField: UITextField) in
            textField.keyboardAppearance = .dark
            textField.keyboardType = .default
            textField.placeholder = "Password"
            textField.isSecureTextEntry = true
        }
        alert.addTextField { (textField: UITextField) in
            textField.keyboardAppearance = .dark
            textField.keyboardType = .default
            textField.placeholder = "Verify password"
            textField.isSecureTextEntry = true
        }
        alert.addAction(loginAction)
        alert.addAction(cancel)
        self.present(alert, animated: true, completion: nil)
    }
}
