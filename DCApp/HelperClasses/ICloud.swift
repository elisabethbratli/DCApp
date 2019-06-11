//
//  ICloud.swift
//  DCApp
//
//  Created by Elisabeth Bratli on 29/03/2019.
//  Copyright © 2019 Elisabeth Bratli. All rights reserved.
//

import Foundation
import UIKit

class ICloud {
    
    func saveFileToICloud(d: Data, title: String, date: String) { //https://stackoverflow.com/questions/45905865/how-to-save-pdf-document-to-icloud-drive-programmatically-using-swift
        var error: NSError?
        let iCloudDocumentsURL = FileManager.default.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("DCApp")
        
        do {
            //is iCloud working?
            if  iCloudDocumentsURL != nil {
                //Create the Directory if it doesn't exist
                if (!FileManager.default.fileExists(atPath: iCloudDocumentsURL!.path, isDirectory: nil)) {
                    //This gets skipped after initial run saying directory exists, but still don't see it on iCloud
                    try FileManager.default.createDirectory(at: iCloudDocumentsURL!, withIntermediateDirectories: true, attributes: nil)
                }
            } else {
                print("iCloud is NOT working!")
            }
            
            if error != nil {
                print("Error creating iCloud DIR")
            }
            
            let localDocumentsURL = FileManager.default.urls(for: FileManager.SearchPathDirectory.documentDirectory, in: .userDomainMask).last! as NSURL

            let b64s = d.base64EncodedString()

            let myTextString = NSString(string: b64s)
            let myLocalFile = localDocumentsURL.appendingPathComponent(date + "Title" + title + ".txt")
            _ = try myTextString.write(to: myLocalFile!, atomically: true, encoding: String.Encoding.utf8.rawValue)
            
            if ((error) != nil){
                print("Error saving to local DIR")
            }
            
            //If file exists on iCloud remove it
            var isDir:ObjCBool = false
            if (FileManager.default.fileExists(atPath: iCloudDocumentsURL!.path, isDirectory: &isDir)) {
                try FileManager.default.removeItem(at: iCloudDocumentsURL!)
            }
            
            //copy from my local to iCloud
            if error == nil {
                try FileManager.default.copyItem(at: localDocumentsURL as URL, to: iCloudDocumentsURL!)
            }
        }
        catch{
            print("Error saving a file")
        }
        //testButton()
    }
    
    func deleteDoc(element: URL) {
        do {
            try FileManager.default.removeItem(at: element)
            print("DELETED")
        } catch {
            print("Couldn't delete")
        }
    }

    
    func docs() -> [URL] {
        let fileManager = FileManager.default
        if let icloudFolderURL = fileManager.url(forUbiquityContainerIdentifier: nil)?.appendingPathComponent("DCApp"),
            let urls = try? fileManager.contentsOfDirectory(at: icloudFolderURL, includingPropertiesForKeys: nil, options: []) {
            return urls
        }
        return []
    }}
