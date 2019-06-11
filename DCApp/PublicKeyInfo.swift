//
//  PublicKeyInfo.swift
//  CryptoTestApp
//
//  Created by Elisabeth Bratli on 21/03/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import UIKit

final class AirDrop: NSObject {
    
    fileprivate enum Keys: String {
        case Pk = "pk"
        case StudentId = "studentId"
    }
    
    let pk: String
    let studentId: String
    
    
    init(pk: String, studentId: String) {
        self.pk = pk
        self.studentId = studentId
    }
}

extension AirDrop {
    func exportToFileURL() -> URL? {
        let pk = "123"
        let studentId = "456"
        // 1
        var contents: [String : Any] = [Pk: pk, StudentId: studentId]
        
        // 2
        /* if let image = beerImage() {
         if let data = UIImageJPEGRepresentation(image, 1) {
         contents[Keys.ImagePath.rawValue] = data.base64EncodedString()
         }
         }*/
        
        // 3
        /* if let note = note {
         contents[Keys.Note.rawValue] = note
         }*/
        
        // 4
        guard let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
        }
        let name = "test"
        // 5
        let saveFileURL = path.appendingPathComponent("/\(name).spk")
        (contents as NSDictionary).write(to: saveFileURL, atomically: true)
        return saveFileURL
    }
    
    static func importData(from url: URL) {
        // 1
        guard let dictionary = NSDictionary(contentsOf: url),
            let dataInfo = dictionary as? [String: AnyObject]
        let pk = dataInfo[PublicKeyInfo.Key] as? String,
        let studentId = dataInfo[StudentId] as? NSNumber else {
            return
        }
        
        
        print(data)
        // 2
        //let studentData = PublicKeyInfo(pk: pk, studentId: studentId)
        
        // 3
        
        
        // 4
        
        // 5
        do {
            try FileManager.default.removeItem(at: url)
        } catch {
            print("Failed to remove item from Inbox")
        }
    }
    
}
