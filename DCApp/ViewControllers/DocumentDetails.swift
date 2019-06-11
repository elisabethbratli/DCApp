//
//  DocumentDetails.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 21/05/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import Foundation
import UIKit
import LocalAuthentication


class DocumentDetails: UIViewController {
    
    @IBOutlet weak var documentText: UILabel!
    
    @IBAction func send(_ sender: Any) {
        let alert = UIAlertController(title: "Send document", message: "", preferredStyle: .actionSheet)
        alert.addAction(UIAlertAction(title: "Send", style: .default, handler: { (_) in
           self.biometrics()
        }))
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: { (_) in
        }))
        
        self.present(alert, animated: true, completion: {
            print("action")
        })
    }
    
    var context = LAContext()
    func biometrics() { //https://codeburst.io/biometric-authentication-using-swift-bb2a1241f2be
        context = LAContext()
        var error: NSError?
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            let reason = "Authenticate"
            context.evaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, localizedReason: reason ) { success, error in
                if success {
                    Student().sendDocument(vc: self, data: selectedDocument)
                } else {
                    print(error?.localizedDescription ?? "Failed to authenticate")
                    VerifiedStudent().signOut(self) //TODO: bare signerer brukeren ut. Skal vi ha noe annet kanskje?
                }
            }
        } else {
            print(error?.localizedDescription ?? "Can't evaluate policy")
            VerifiedStudent().signOut(self) //TODO: bare signerer brukeren ut. Skal vi ha noe annet kanskje?
        }
    }
    
    override func viewDidLoad() {
        documentText.text = documentTextString
        super.viewDidLoad()
    }
    
}
