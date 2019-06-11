//
//  VerifiedStudent.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 30/04/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import Foundation
import UIKit
import Firebase
import LocalAuthentication
import FirebaseFirestore

var documentTextString = ""
var selectedDocument = ""
var docName = ""

class VerifiedStudent: UIViewController, UITableViewDataSource, UITableViewDelegate {
    var studentId: String = ""
    @IBOutlet weak var noDocs: UILabel!
    @IBOutlet weak var table: UITableView!
    var urls: [URL] = []
    var docs: [Helper.Documents] = []
    var context = LAContext()
    
    func files() {
        urls = ICloud().docs()
        if (urls.count < 1) {
            table.isHidden = true
            noDocs.isHidden = false
        } else {
            for url in urls {
                let filename = url.lastPathComponent
                let nameArr = filename.components(separatedBy: ".")
                let nameArr2 = nameArr[0].components(separatedBy: "Title")
                if (nameArr.count == 1 || nameArr[1] != "txt" || nameArr2.count == 1) { //removing files that are not document. Safety check
                    if let index = urls.index(where: {$0 == url}) {
                        urls.remove(at: index)
                        continue
                    }
                }
                var date1 = nameArr2[0].components(separatedBy: "-")
                if (date1[0].count == 1) {
                    date1[0] = "0" + date1[0]
                }
                if (date1[1].count == 1) {
                    date1[1] = "0"+date1[1]
                }
                let dateStr = date1[2] + "-" + date1[1] + "-" + date1[0]
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd"
                let date = dateFormatter.date(from: dateStr)
                let newDoc = Helper.Documents(url: url, date: date!)
                docs.append(newDoc)
            }
        }
        docs = docs.sorted(by: { $0.date > $1.date })
    }
    
    override func viewDidLoad() {
        files()
        if (urls.count < 1) {
            table.isHidden = true
            noDocs.isHidden = false
        }
        super.viewDidLoad()
        let currentUserUID = Auth.auth().currentUser!.uid
        let db = Firestore.firestore()
        let ref = db.collection("students").document(currentUserUID)
        
        ref.getDocument { (document, error) in
            if let document = document, document.exists {
                ref.getDocument(source: .cache) { (document, error) in
                    if let document = document {
                        self.studentId = (document.get("studentId") as? String)! //TODO: skal det være as eller as? ?
                    } else {
                        print("Document does not exist in cache")
                    }
                }
            }
        }
    }
    
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return urls.count
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cloudCell", for: indexPath) as! UITableViewCell
        let fullFilename = docs[indexPath.item].url.lastPathComponent
        let nameArr1 = fullFilename.components(separatedBy: ".")
        let nameArr2 = nameArr1[0].components(separatedBy: "Title")
        cell.textLabel?.text = "Document: " + nameArr2[1] + "\nDate: " + nameArr2[0]
        cell.textLabel?.numberOfLines = 0
        cell.textLabel?.lineBreakMode = .byWordWrapping

        cell.backgroundColor = UIColor(hue: 0.1944, saturation: 0, brightness: 0.82, alpha: 1.0)
        cell.layer.borderColor = UIColor.white.cgColor
        cell.layer.borderWidth = 5
        cell.layer.cornerRadius = 8
        cell.clipsToBounds = true
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let element = docs[indexPath.item].url
        let fullName = element.lastPathComponent
        let nameArr1 = fullName.components(separatedBy: ".")
        let nameArr2 = nameArr1[0].components(separatedBy: "Title")
        docName = nameArr2[1]
        action(element: element)
    }
    
    func action(element: URL) {
        let filename = element.lastPathComponent
        let nameArr1 = filename.components(separatedBy: ".")
        let nameArr2 = nameArr1[0].components(separatedBy: "Title")
        //https://medium.com/swift-india/uialertcontroller-in-swift-22f3c5b1dd68
        let alert = UIAlertController(title: "Document: " + nameArr2[1], message: "Please select an option", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "View", style: .default, handler: { (_) in
            self.biometrics(action: "view", element: element)
        }))
        
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (_) in
            self.biometrics(action: "send", element: element)
        }))
        
        alert.addAction(UIAlertAction(title: "Delete", style: .default, handler: { (_) in
            self.biometrics(action: "delete", element: element)
        }))

        alert.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: { (_) in
        }))
        
        self.present(alert, animated: true, completion: {
            print("action")
        })
    }
    
    func biometrics(action: String, element: URL) { //https://codeburst.io/biometric-authentication-using-swift-bb2a1241f2be
        var error: NSError?
        context = LAContext()
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in
                if success {
                    switch action {
                    case "delete":
                        ICloud().deleteDoc(element: element)
                    case "view":
                        do {
                            let tmpString = try String(contentsOf: element, encoding: .utf8)
                            guard let d = Data.init(base64Encoded: tmpString) else {
                                return
                            }
                            let dec = Helper().decrypt(encrypted: d)
                            selectedDocument = String(decoding: dec as! Data, as: UTF8.self)
                            let docArr = String(decoding: dec as! Data, as: UTF8.self).components(separatedBy: ",sig1:")
                            let content = docArr[0].components(separatedBy: "document:")
                            let docElem = docArr[docArr.count-1]
                            documentTextString = content[1]
                        } catch {
                            print("Error")
                        }
                        DispatchQueue.main.async {
                            self.performSegue(withIdentifier: "modalSegue", sender: self)
                        }
                    case "send":
                        do {
                            let tmpString = try String(contentsOf: element, encoding: .utf8)
                            guard let d = Data.init(base64Encoded: tmpString) else {
                                return
                            }
                            let dec = Helper().decrypt(encrypted: d)
                            Student().sendDocument(vc: self, data: String(decoding: dec as! Data, as: UTF8.self))
                        } catch {
                            print("something went wrong")
                        }
                    default:
                        break
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
    
    @IBAction func signOut(_ sender: Any) {
        DispatchQueue.main.async {
            do {
                try Auth.auth().signOut()
                self.performSegue(withIdentifier: "signOutVerifiedStudentSegue", sender: self)
            } catch let signOutError as NSError {
                print ("Error signing out: %@", signOutError)
            }
        }
    }
    
    @IBAction func requestDocument(_ sender: Any) {
        let db = Firestore.firestore()
        db.collection("requestss").addDocument(data: [
            "id": studentId,
            "status": "pending",
        ]) { err in
            if let err = err {
                print("Error adding document: \(err)")
            } else {
                Helper().alertController(vc: self, title: "Request sent.", message: "A grade transcript has been requested.")
                print("Document added")
            }
        }
    }
}
