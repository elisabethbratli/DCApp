//
//  AirDrop.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 21/03/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//  code taken from https://www.raywenderlich.com/1018-uiactivityviewcontroller-tutorial-sharing-data
//  and modified to work with this app.

import UIKit
import FirebaseAuth
import FirebaseDatabase
import FirebaseFirestore

final class AirDrop: NSObject {
    
    fileprivate enum Keys: String {
        case PkData = "pkData"
        case Pk = "pk"
        case FileName = "fileName"
        case FileType = "fileType"
    }
    
    let pkData: Data
    let fileName: String //studentID for students
    let pk: String
    let fileType: String
    
    init(pk: String, pkData: Data
        , fileName: String, fileType: String) {
        self.pkData = pkData
        self.pk = pk
        self.fileName = fileName
        self.fileType = fileType
    }
}

extension AirDrop {
    func exportToFileURL(spkData: Data
        , spk: String, sFileName: String, sFileType: String) -> URL? {
        var pk = ""
        let fileName = sFileName
        let pkData = spkData
        let fileType = sFileType
        if (sFileType != "doc") {
            pk = spk
        } else {
            let date = Date()
            let calendar = Calendar.current
            pk = String(calendar.component(.day, from: date)) + "-"
            pk += String(calendar.component(.month, from: date)) + "-"
            pk += String(calendar.component(.year, from: date))
        }
        
        let contents: [String : Any] = [Keys.PkData.rawValue: pkData, Keys.Pk.rawValue: pk, Keys.FileName.rawValue: fileName, Keys.FileType.rawValue: fileType]
        guard let path = FileManager.default
            .urls(for: .documentDirectory, in: .userDomainMask).first else {
                return nil
        }
        let saveFileURL = path.appendingPathComponent("/\(fileName).spk")
        (contents as NSDictionary).write(to: saveFileURL, atomically: true)

        if (sFileType == "doc") {
            let db = Firestore.firestore()
            db.collection("requestss").document(spk).setData([ "status": "completed" ], merge: true) //TODO: dette må gjøres etter dokumentet har blitt sent feks
        }

        return saveFileURL
    }
    
}

extension AirDrop {
    static func importData(from url: URL) {
        let currentUser = Auth.auth().currentUser
        if (currentUser != nil && isAdmin) {
            guard let dictionary = NSDictionary(contentsOf: url),
                let dataInfo = dictionary as? [String: AnyObject],
                let pkData = dataInfo[Keys.PkData.rawValue] as? Data,
                let pk = dataInfo[Keys.Pk.rawValue] as? String,
                let fileName = dataInfo[Keys.FileName.rawValue] as? String,
                let fileType = dataInfo[Keys.FileType.rawValue] as? String else {
                    print("AirDrop file failed", NSDictionary(contentsOf: url))
                    return
            }
            if (fileType == "student") {
                University().addStudent(pkData: pkData, pk: pk, id: fileName)
            } else if (fileType == "admin") {
                University().addAdmin(pkData: pkData, pk: pk, id: fileName)
            }
            print("URL", url)
            do {
                try FileManager.default.removeItem(at: url)
            } catch {
                print("Failed to remove item from Inbox")
            }
        } else {
            guard let dictionary = NSDictionary(contentsOf: url),
                let dataInfo = dictionary as? [String: AnyObject],
                let pkData = dataInfo[Keys.PkData.rawValue] as? Data,
                let pk = dataInfo[Keys.Pk.rawValue] as? String,
                let fileName = dataInfo[Keys.FileName.rawValue] as? String,
                let fileType = dataInfo[Keys.FileType.rawValue] as? String else {
                    print("AirDrop file failed", NSDictionary(contentsOf: url))
                    return
            }

            if (fileType == "doc") {
                ICloud().saveFileToICloud(d: pkData, title: fileName, date: pk)
            }
        }
    }
}
