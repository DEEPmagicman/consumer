//
//  AppDelegate.swift
//  FoodChoo-Merchant
//
//  Created by Mac Book on 27/08/2020.
//  Copyright © 2020 Al-Tafseer. All rights reserved.
//

import Foundation
import UIKit
import AVFoundation
import ContactsUI
import NVActivityIndicatorView

//MARK: AppHelperUtility setup
@objc class Utility: NSObject{
    static let main = Utility()
    fileprivate override init() {}
}
extension Utility{
    func topViewController(base: UIViewController? = (AppDelegate.shared).window?.rootViewController) -> UIViewController? {
        
        if let nav = base as? UINavigationController {
            return topViewController(base: nav.visibleViewController)
        }
        if let tab = base as? UITabBarController {
            if let selected = tab.selectedViewController {
                return topViewController(base: selected)
            }
        }
        if let presented = base?.presentedViewController {
            return topViewController(base: presented)
        }
        return base
    }
    func thumbnailForVideoAtURL(url: URL) -> UIImage? {
        let asset = AVAsset(url: url)
        let assetImageGenerator = AVAssetImageGenerator(asset: asset)
        assetImageGenerator.appliesPreferredTrackTransform=true
        
        var time = asset.duration
        time.value = min(time.value, 2)
        
        do {
            let imageRef = try assetImageGenerator.copyCGImage(at: time, actualTime: nil)
            return UIImage(cgImage: imageRef)
        } catch {
            print("error")
            return nil
        }
    }
    func openURL(url:URL){
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:])
        }
        else{
            self.showAlert(message: Strings.URL_NOT_VALID.text ,title: Strings.ERROR.text)
        }
    }
    func delay(delay:Double, closure:@escaping ()->()) {
        DispatchQueue.main.asyncAfter(
            deadline: DispatchTime.now() + Double(Int64(delay * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: closure)
    }
    func getDeviceSpecificFont(fontWeight: String, fontSize: CGFloat)->UIFont?{
        let bounds = UIScreen.main.bounds
        let height = bounds.size.height
        
        switch height {
        case 480.0: //Iphone 3,4,SE => 3.5 inch
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize * 0.6)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize * 0.6)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize * 0.6)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize * 0.6)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize * 0.6)
            default:
                break
            }
        case 568.0: //iphone 5, 5s => 4 inch
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize * 0.7)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize * 0.7)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize * 0.7)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize * 0.7)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize * 0.7)
            default:
                break
            }
        case 667.0: //iphone 6, 6s => 4.7 inch
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize * 0.8)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize * 0.8)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize * 0.8)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize * 0.8)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize * 0.8)
            default:
                break
            }
        case 736.0: //iphone 6s+ 6+ => 5.5 inch
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize * 0.9)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize * 0.9)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize * 0.9)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize * 0.9)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize * 0.9)
            default:
                break
            }
        case 812.0: //iphone 11 pro
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize * 0.95)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize * 0.95)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize * 0.95)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize * 0.95)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize * 0.95)
            default:
                break
            }
        case 896.0: //iphone 11,11 pro max
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize)
            default:
                break
            }
        default:
            switch fontWeight {
            case "light":
                return UIFont(name: "Poppins-Light", size: fontSize)
            case "regular":
                return UIFont(name: "Poppins-Regular", size: fontSize)
            case "medium":
                return UIFont(name: "Poppins-Medium", size: fontSize)
            case "semiBold":
                return UIFont(name: "Poppins-SemiBold", size: fontSize)
            case "bold":
                return UIFont(name: "Poppins-Bold", size: fontSize)
            default:
                break
            }
        }
        return nil
    }
    func getCurrecyFrom(countryCode: String)->[String:String]?{
        let localeIds = Locale.availableIdentifiers
        var countryCurrency = [String: [String:String]]()
        for localeId in localeIds {
            let locale = Locale(identifier: localeId)
            if let country = locale.regionCode, country.count == 2 {
                if let currencyIcon = locale.currencySymbol,
                   let currency = locale.currencyCode {
                    countryCurrency[country] = [currencyIcon:currency]
                }
            }
        }
        let sorted = countryCurrency.keys.sorted()
        for country in sorted {
            guard let currency = countryCurrency[country] else {return nil}
            if country == countryCode{
                return currency
            }
        }
        return nil
    }
    func getBottomSafeArea() -> CGFloat {
        let scenes = UIApplication.shared.connectedScenes
        
        let windowScene = scenes.first as? UIWindowScene
                
        guard let window = windowScene?.windows.first else {return 0.0}
        let bottomPadding = window.safeAreaInsets.bottom
        return bottomPadding
        
    }
}
//MARK: INDICATOR
extension Utility{
    static func showLoader() {
        let size = CGSize(width: 70, height: 70)
        let bgColor = UIColor(red: 0, green: 0, blue: 0, alpha: 0.15)
        let activityData = ActivityData(size: size, message: "", messageFont: UIFont.systemFont(ofSize: 12),
                                        type: .ballClipRotatePulse, color: Global.APP_COLOR, padding: 0,
                                        displayTimeThreshold: 0, minimumDisplayTime: 1, backgroundColor: bgColor, textColor: UIColor.black)
        
        if NVActivityIndicatorPresenter.sharedInstance.isAnimating{return}
        NVActivityIndicatorPresenter.sharedInstance.startAnimating(activityData, nil)
    }
    static func hideLoader() {
        NVActivityIndicatorPresenter.sharedInstance.stopAnimating(nil)
    }
}
//MARK: Make phone call
extension Utility{
    func makeCallTo(number:String){
        guard let number = URL(string: "tel://" + number) else { return }
        UIApplication.shared.open(number)
    }
}
//MARK: Alert related functions
extension Utility{
    func showAlert(message: String, title: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: Strings.OK.text, style: .default) { _ in })
        Utility().topViewController()!.present(alert, animated: true){}
    }
    func showAlert(message: String, title: String, usingCompletionHandler handler:@escaping (() -> Swift.Void)) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: Strings.OK.text, style: .default, handler: {
            (action) in
            handler()
        }))
        Utility().topViewController()?.present(alertController, animated: true, completion: nil)
    }
    func showAlert(message: String, title: String, YES: String, NO: String, completionHandler: @escaping (UIAlertAction?, UIAlertAction?) -> Void) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: YES, style: .default){ (alertActionYES) in
            completionHandler(alertActionYES, nil)
        })
        alertController.addAction(UIAlertAction(title: NO, style: .destructive){ (alertActionNO) in
            completionHandler(nil, alertActionNO)
        })
        Utility().topViewController()!.present(alertController, animated: true, completion: nil)
    }
}
extension Utility{
  
}
//MARK: Go To Settings
extension Utility{
    func goToSettings(){
        let alertController = UIAlertController (title: "Settings", message: "Location permission is mendatory to give customer access to track his delivery.\nGo to Settings?", preferredStyle: .alert)
        
        let settingsAction = UIAlertAction(title: "Settings", style: .default) { (_) -> Void in
            
            guard let settingsUrl = URL(string: UIApplication.openSettingsURLString) else {
                return
            }
            
            if UIApplication.shared.canOpenURL(settingsUrl) {
                UIApplication.shared.open(settingsUrl, completionHandler: { (success) in
                    print("Settings opened: \(success)") // Prints true
                })
            }
        }
        alertController.addAction(settingsAction)
        let cancelAction = UIAlertAction(title: "Cancel", style: .default, handler: nil)
        alertController.addAction(cancelAction)
        
        Utility.main.topViewController()?.present(alertController, animated: true, completion: nil)
    }
}
//MARK: Utility Methods
extension Utility{
    func stringDateFormatter(dateStr: String , dateFormat : String , formatteddate : String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = dateFormat
        let date = dateFormatter.date(from: dateStr)
        dateFormatter.dateFormat = formatteddate
        dateFormatter.timeZone = .current
        dateFormatter.locale = .current
        return dateFormatter.string(from: date ?? Date())
    }
    func dateFormatter(date: Date,dateFormat:String) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = dateFormat
        return dateFormatter.string(from: date)
    }
    func getDateFrom(dateString: String,dateFormat: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = .current
        guard let date = dateFormatter.date(from: dateString) else {return nil}
        return date
    }
    func getTimeDifferenceDateFrom(dateString: String,dateFormat: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = .current
        guard let date = dateFormatter.date(from: dateString) else {return nil}
        let final =  Date() - date
        return final.hour
    }
    func getSecondsTimeDifferenceDateFrom(dateString: String,dateFormat: String) -> Int? {
        let dateFormatter = DateFormatter()
        dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        dateFormatter.dateFormat = dateFormat
        dateFormatter.locale = .current
        guard let date = dateFormatter.date(from: dateString) else {return nil}
        let final =  Date() - date
        return final.second
    }
    func openEmail(email: String) {
        if let url = URL(string: "mailto:\(email)") {
            if #available(iOS 10.0, *) {
                UIApplication.shared.open(url)
            } else {
                UIApplication.shared.openURL(url)
            }
        }
    }
    func emojiFlag(regionCode: String) -> String? {
        let code = regionCode.uppercased()
        
        guard Locale.isoRegionCodes.contains(code) else {return nil}
        
        var flagString = ""
        for s in code.unicodeScalars {
            guard let scalar = UnicodeScalar(127397 + s.value) else {
                continue
            }
            flagString.append(String(scalar))
        }
        return flagString
    }
    func countryName(from countryCode: String) -> String {
        if let name = (Locale.current as NSLocale).displayName(forKey: .countryCode, value: countryCode) {
            // Country name was found
            return name
        } else {
            // Country name cannot be found
            return countryCode
        }
    }
    func secondsToHoursMinutesSeconds (seconds : Int) -> (Int, Int, Int) {
        return (seconds / 3600, (seconds % 3600) / 60, (seconds % 3600) % 60)
    }
    func randomString(length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        return String((0..<length).map{ _ in letters.randomElement()! })
    }
    func setJustifiedText(text:String)->NSAttributedString {
        let style = NSMutableParagraphStyle()
        style.lineSpacing = 8
        style.alignment = .justified
        let attributes = [NSAttributedString.Key.paragraphStyle: style,
                          NSAttributedString.Key.foregroundColor:UIColor(displayP3Red: 84/255, green: 85/255, blue: 86/255, alpha: 1.0)]
        return NSAttributedString(string: text, attributes: attributes)
    }
    func getDownTime()->Int{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second]
        formatter.unitsStyle = .full
        let downTime = UserDefaults.standard.object(forKey: "inActiveTime") as? Date ?? Date()
        let difference = Int((formatter.string(from: downTime, to: Date()) ?? "0").digits) ?? 0
        return difference
    }
    func getDownTimeFrom(date: Date)->Int{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.hour]
        formatter.unitsStyle = .full
        let difference = Int((formatter.string(from: date, to: Date()) ?? "0").digits) ?? 0
        return difference
    }
    func getTimeDifference(first: Date, second: Date)->Int{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.second]
        formatter.unitsStyle = .full
        let difference = Int((formatter.string(from: first, to: second) ?? "0").digits) ?? 0
        return difference
    }
    func getDayDifference(first: Date, second: Date)->Int{
        let formatter = DateComponentsFormatter()
        formatter.allowedUnits = [.day]
        formatter.unitsStyle = .full
        let difference = Int((formatter.string(from: first, to: second) ?? "0").digits) ?? 0
        return difference
    }
}
//MARK: Phone contacts
extension Utility{
    func getContacts() -> [CNContact] {
        
        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactThumbnailImageDataKey] as [Any]
        
        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            print("Error fetching containers")
        }
        
        var results: [CNContact] = []
        
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)
            
            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                print("Error fetching containers")
            }
        }
        
        return results.sorted(by: { $0.givenName < $1.givenName })
    }
}
//MARK: Share QD application link
extension Utility{
    func shareSocialWith(text: String){
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = Utility.main.topViewController()?.view
        Utility.main.topViewController()?.present(activityViewController, animated: true, completion: nil)
    }
    func URLforRoute(route: String,params:[String: Any]) -> NSURL? {
        if let components: NSURLComponents  = NSURLComponents(string: (route)){
            var queryItems = [NSURLQueryItem]()
            for(key,value) in params {
                queryItems.append(NSURLQueryItem(name:key,value: "\(value)"))
            }
            components.queryItems = queryItems as [URLQueryItem]?
            return components.url as NSURL?
        }
        return nil
    }
}


extension Utility{
    func attributedString(mainString: String, modificationString: String) -> NSMutableAttributedString {
        
        let mainFont = Utility.main.getDeviceSpecificFont(fontWeight: "bold", fontSize: 14.0) ?? UIFont()
        let customFont = Utility.main.getDeviceSpecificFont(fontWeight: "medium", fontSize: 14.0) ?? UIFont()
        
        let attributes:[NSAttributedString.Key:Any] = [NSAttributedString.Key.foregroundColor: UIColor.black, NSAttributedString.Key.font: customFont]
        let attributedModifiedMessage = NSMutableAttributedString(string: mainString, attributes: attributes)
        
        let regex = try! NSRegularExpression(pattern: modificationString,options: .ignoreMetacharacters)
        for match in regex.matches(in: mainString, options: NSRegularExpression.MatchingOptions(), range: NSRange(location: 0, length: mainString.count)) as [NSTextCheckingResult] {
            attributedModifiedMessage.addAttribute(NSAttributedString.Key.font, value: mainFont, range: match.range)
            attributedModifiedMessage.addAttribute(NSAttributedString.Key.foregroundColor, value: Global.APP_COLOR, range: match.range)
        }
        return attributedModifiedMessage
    }
}

extension Utility {
    func openMap(lat: Double, lng: Double){
        guard let googleMapUrl = URL(string: "comgooglemaps://") else {return}
        if UIApplication.shared.canOpenURL(googleMapUrl) {
            guard let searchUrlString = URL(string: "comgooglemaps://search?q=\("\(lat),\(lng)")") else {return}
            UIApplication.shared.open(searchUrlString)
        }
        else{
            guard let appleMapUrl = URL(string: "http://maps.apple.com/") else {return}
            guard let searchUrlString = URL(string: "maps://?saddr=&daddr=\(lat),\(lng)") else {return}
            UIApplication.shared.canOpenURL(appleMapUrl)
            UIApplication.shared.open(searchUrlString)
        }
    }
    
    func openMail(email:String){
        guard let mailUrl = URL(string: "mailto:\(email)") else {return}
        UIApplication.shared.open(mailUrl)
    }
}

//MARK:- Share QD application link
extension Utility{
    func shareQuickDelivery(text: String){
        let textToShare = [text]
        let activityViewController = UIActivityViewController(activityItems: textToShare, applicationActivities: nil)
        activityViewController.popoverPresentationController?.sourceView = Utility.main.topViewController()?.view
        Utility.main.topViewController()?.present(activityViewController, animated: true, completion: nil)
    }
}

class Alert {
    
    static func showAlertSheet(style: UIAlertController.Style, title: String?, message: String?, actions: [UIAlertAction] = [UIAlertAction(title: "ok", style: .cancel, handler: nil)], completion: (() -> Swift.Void)? = nil) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: style)
        for action in actions {
            alert.addAction(action)
        }
        if let topVC = UIApplication.getTopMostViewController() {
            alert.popoverPresentationController?.sourceView = topVC.view
            alert.popoverPresentationController?.sourceRect = CGRect(x: topVC.view.bounds.midX, y: topVC.view.bounds.midY, width: 0, height: 0)
            alert.popoverPresentationController?.permittedArrowDirections = []
            DispatchQueue.main.async {
                topVC.present(alert, animated: true, completion: completion)
            }
        }
    }
    
    static func showToast(_ message: String) {
        if let vcc = UIApplication.shared.keyWindow?.rootViewController {
            vcc.view.makeToast(message)
        }
    }
}

