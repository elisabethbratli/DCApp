# DCApp

DCApp (Degree Certificate Application) is an iOS app created to demonstrate the funcamentals of the document verification system described in the master's thesis, "Document Verification System on iOS with Face ID/Touch ID".

## Getting Started

These instructions will get you a copy of the project, and assuming the prerequisites are fulfilled, you will be able to run DCApp on your iPhone.

### Prerequisites

1. A Macintosh is required to run the project.
2. Xcode must be installed. It is an integrated development environment for macOS. 
  * Go to the App store to download and install Xcode.
3. A paid Apple Developer Account.
  * Without a paid account, the code can still be viewed in Xcode and run in the Xcode simulator. In the simulator the biometric features are replaced with a passcode. AirDrop is not available in the simulator.

### Installing and running project

1. Download the project as a zipfile.
2. Unzip the project on your Macintosh.
3. Open the root folder, DCApp, and open DCApp.xcworkspace (not DCAPP.xcodeproj) in Xcode.
4. Click the top level of DCApp in the navigation menu to the left.
5. Go to "General".
6. If you have not used Xcode before: For "Team" in the "Signing" section, choose "Add an Account", an log in with your Apple ID. If you have more than one team to choose from now, choose your paid team if you have one. 

* To be able to create new users (both students and administrators), there is an option to create a main administrator when signing up. This is only if you want to test, and would not be a part of a real system!

To run in simulator: in the top left (next to stop icon), click DCApp, and choose device to run app on.

To run on real device:
* Connect device to your Macintosh.
* The device should appear as an option where you chose the simulator.
* Run the application (if you get a build fail, go to "Signing" in "General" again and resolve errors. Typically you need to register the device.)
