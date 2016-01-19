//
//  UserActivityLogger.swift
//  SwiftLogger
//
//  Created by Aiden Montgomery on 19/01/2016.
//  Copyright © 2016 Constructive Coding. All rights reserved.
//

import Foundation

#if SPLUNK
    import SplunkMint
#endif

#if FABRIC
    import Crashlytics
#endif

public class QFUserActivityLogger {
    
    private static var context: Dictionary<String, AnyObject>?
    
    public class func trackLoginSuccess(method: String, trackingID id: String = "") {
        #if FABRIC
            Answers.logLoginWithMethod(method,
                success: true,
                customAttributes: nil)
        #else
            track("Login Success: \(method)", trackingID: id)
        #endif
    }
    
    public class func trackLoginFailure(method: String, trackingID id: String = "") {
        #if FABRIC
            Answers.logLoginWithMethod(method,
                success: false,
                customAttributes: nil)
        #else
            track("Login Failure: \(method)", trackingID: id)
        #endif
    }
    
    public class func trackContentView(name: String, contentType: String, contentID: String? = "", trackingID: String? = "") {
        #if FABRIC
            Answers.logContentViewWithName(name,
                contentType: contentType,
                contentId: contentID,
                customAttributes: addTrackingIDToContext(trackingID!))
        #elseif SPLUNK
            var datalist = convertContextToDataList()
            datalist.add(ExtraData(key: "ContentType", andValue: contentType))
            datalist.add(ExtraData(key: "ContentID", andValue: contentID!))
            datalist.add(ExtraData(key: "TrackingID", andValue: trackingID!))
            Mint.sharedInstance().logViewWithCurrentViewName(name, limitedExtraDataList: datalist)
        #else
            track("\(name) \(contentType) \(trackingID)")
        #endif
    }
    
    public class func track(event: String, trackingID: String = "") {
        if (self.context == nil) {
            setup()
        }
        
        #if FABRIC
            Answers.logCustomEventWithName(event,
                customAttributes: addTrackingIDToContext(trackingID))
        #elseif SPLUNK
            Mint.sharedInstance().logEventAsyncWithTag(event, extraDataKey: "trackingID", extraDataValue: trackingID) { (logResult) -> Void in
                let result = logResult.resultState.rawValue == OKResultState.rawValue ? "OK" : "Failed"
                print("Track Event Result: \(result)")
            }
        #elseif ADBMOBILE
            ADBMobile.trackState(event, data: self.context)
        #else
            print("\(event) \(trackingID)")
        #endif
    }
    
    private static func addTrackingIDToContext (trackingID: String) -> Dictionary<String, AnyObject> {
        var dictionary = Dictionary<String, AnyObject>()
        dictionary["TrackingID"] = trackingID
        
        if (self.context != nil) {
            for (key, value) in self.context! {
                dictionary[key] = value;
            }
        }
        
        return dictionary
    }
    
    #if SPLUNK
    private static func convertContextToDataList() -> LimitedExtraDataList {
        let datalist = LimitedExtraDataList()
        if (self.context != nil) {
            for (key, value) in self.context! {
                datalist.add(ExtraData(key: key, andValue: value as! String))
            }
        }
        
        return datalist
    }
    #endif
    
    private static func setup() {
        #if ADBMOBILE
            let omnitureConfig = ConfigStore.sharedStore.omnitureConfig
            let omnitureJsonPath = NSBundle.mainBundle().pathForResource(omnitureConfig, ofType: "json")
            ADBMobile.overrideConfigPath(omnitureJsonPath)
        #endif
        
        self.context = [ "appID" : NSBundle.mainBundle().bundleIdentifier!,
            "language" : NSLocale.currentLocale().objectForKey(NSLocaleLanguageCode) ?? "",
            "country" : NSLocale.currentLocale().objectForKey(NSLocaleCountryCode) ?? ""]
    }
}