SAPCRMODataApp
===========
This application is showcasing the usage of the SAP Mobile Platform SDK for iOS.

## How To Get Started
* Download the [SAPCRMOData project](https://github.com/SAP/Mobile_SDK_oData_App/archive/master.zip)
* Visit the official [SMP SDK site](http://help.sap.com/mobile-platform). Navigate to the latest version of the iOS SDK and open the Installation Guide. Follow the installation steps described in the guide to download and instal the SAP Mobile SDK.

## Configuring the project
The [SAP Mobile SDK for iOS](http://help.sap.com/mobile-platform) are required to build this app. After installing the required components, all dependencies can be configured using CocoaPods. 

### Installation with CocoaPods

[CocoaPods](http://cocoapods.org) is a dependency manager for Objective-C, which automates and simplifies the process of using 3rd-party libraries  in your projects. You can install it with the following command:

```bash
$ gem install cocoapods
```

#### Podfile

To integrate the SAP Mobile SDK into your Xcode project using CocoaPods, run the following command on the project's directory:

```bash
$ pod install
```

## Technical Details

It is highly recommended to check out the documentation on [Native OData App Development](http://help.sap.com/mobile-platform).

The following Mobile SDK frameworks are used:
- ODataAPI
- OData Online
- OData Offline
- HTTPConversation
- MAFLogonManager
- Supportability (for logging and tracing)
- further libraries required due to dependencies

The SAPCRMOData app supports three different modes:
- Online (default)
- Offline (relies on the OData offline store)
- Demo mode

The demo mode can be used right away; note that creating, editing or deleting entities is restricted in demo mode.

The online and offline mode require a compatible CRM endpoint.
The endpoint URL and app ID must be filled in in order for the app to work. 
This can be done within the device's Settings -> SAPCRMOData (see screenshot). Also, a valid user name and a password is required - except for demo mode.

![App Settings](https://github.com/SAP/Mobile_SDK_oData_App/blob/screenshots/Screenshots/settings.png)

The Login UI:
![The Login UI](https://github.com/SAP/Mobile_SDK_oData_App/blob/screenshots/Screenshots/login.png)

The App's Main UI:
![The App's Main UI](https://github.com/SAP/Mobile_SDK_oData_App/blob/screenshots/Screenshots/appointments.png)

Built-In Log Viewer:
![Built-In Log Viewer](https://github.com/SAP/Mobile_SDK_oData_App/blob/screenshots/Screenshots/logviewer.png)

In-App Settings:
![In-App Settings](https://github.com/SAP/Mobile_SDK_oData_App/blob/screenshots/Screenshots/inappsettings.png)

## Credits

SAPCRMOData is owned and maintained by [SAP](http://go.sap.com/index.html).

## License

SAPCRMOData is released under the Apache License Version 2.0. See LICENSE for details.
