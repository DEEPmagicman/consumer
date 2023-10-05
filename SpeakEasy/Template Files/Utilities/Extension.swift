//
//  Extension.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 09/12/22.
//

import CoreLocation
import UIKit
import FirebaseCrashlytics

extension CLLocation {
    func getCity(completion: @escaping (String) -> Void) {
        let locationManager = CLLocationManager()
        locationManager.getPlace(for: self) { placeMark in
            guard let placeMark = placeMark else {
                completion("")
                return
            }
            if let town = placeMark.locality, let country = placeMark.country, let state = placeMark.administrativeArea {
                completion(town)
            } else {
                completion("")
            }
        }
    }
}

extension CLLocationManager {
    func getPlace(for location: CLLocation,
                  completion: @escaping (CLPlacemark?) -> Void) {
        let geocoder = CLGeocoder()
        geocoder.reverseGeocodeLocation(location) { placemarks, error in
            guard error == nil else {
                print("*** Error in \(#function): \(error?.localizedDescription ?? "")")
                completion(nil)
                return
            }
            guard let placemark = placemarks?.first else {
                print("*** Error in \(#function): placemark is nil")
                completion(nil)
                return
            }
            completion(placemark)
        }
    }
}

extension String {
    var isValidEmail: Bool {
        let regularExpressionForEmail = "[A-Z0-9a-z._%+-]+@[A-Za-z0-9.-]+\\.[A-Za-z]{2,64}"
        let testEmail = NSPredicate(format:"SELF MATCHES %@", regularExpressionForEmail)
        return testEmail.evaluate(with: self)
    }
    
    var validateDouble: Bool {
        if let _ = Double(self) {
            return true
        } else {
            return false
        }
    }
    
    func convertDateFormat(from: DateFormat, to: DateFormat, isUTC: Bool = true, useDayLightSavingTime: Bool = false, customTimeZone: String = "") -> String {
        let olDateFormatter = DateFormatter()
        olDateFormatter.dateFormat = from.rawValue
        if isUTC {
            olDateFormatter.timeZone = TimeZone(identifier: "UTC")!
        } else {
            olDateFormatter.timeZone = .current
        }
        guard let oldDate = olDateFormatter.date(from: self) else { return "No date Found" }
        let convertDateFormatter = DateFormatter()
        convertDateFormatter.dateFormat = to.rawValue
        if customTimeZone != "", let timeZone = TimeZone(identifier: customTimeZone) {
            convertDateFormatter.timeZone = timeZone
        } else {
            convertDateFormatter.timeZone = .current
        }
        if useDayLightSavingTime {
            return convertDateFormatter.string(from: oldDate.addingTimeInterval(convertDateFormatter.timeZone.daylightSavingTimeOffset()))
        } else {
            return convertDateFormatter.string(from: oldDate)
        }
    }
    
    func toDate(withFormat format: DateFormat, isUTC: Bool = true)-> Date? {
        let dateFormatter = DateFormatter()
        if isUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")            
        } else {
            dateFormatter.timeZone = .current
        }
        dateFormatter.dateFormat = format.rawValue
        return dateFormatter.date(from: self)
    }
    
    func displayUpdatedAgo(from: DateFormat, to: DateFormat, isUTC: Bool = true, useDayLightSavingTime: Bool = false, customTimeZone: String = "") -> String {
        let oldDateFormatter = DateFormatter()
        oldDateFormatter.dateFormat = from.rawValue
        if isUTC {
            oldDateFormatter.timeZone = TimeZone(identifier: "UTC")
        } else {
            oldDateFormatter.timeZone = .current
        }
        guard let oldDate = oldDateFormatter.date(from: self) else { return "No date Found" }
        let whileAgoDate = Calendar.current.date(byAdding: .hour, value: -10, to: Date()) ?? Date()
        if whileAgoDate > oldDate {
            return Constant.String.updateWhileAgo
        }
        let convertDateFormatter = DateFormatter()
        convertDateFormatter.dateFormat = to.rawValue
        if customTimeZone != "", let timeZone = TimeZone(identifier: customTimeZone) {
            convertDateFormatter.timeZone = timeZone
        } else {
            convertDateFormatter.timeZone = .current
        }
        if useDayLightSavingTime {
            return "\(Constant.String.updated) \(convertDateFormatter.string(from: oldDate.addingTimeInterval(convertDateFormatter.timeZone.daylightSavingTimeOffset())))"
        } else {
            return "\(Constant.String.updated) \(convertDateFormatter.string(from: oldDate))"
        }
    }
}

extension Double {
    // For reducing value as per scale down value
    var scaledValue: Double {
        self / Double(FixValue.scale)
    }
    
    func decimalFormat(_ valueDouble: Bool = false) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.numberStyle = .decimal
        if valueDouble {
            if let newValue =  Double(String(format: "%.2f", NSNumber(value: self).doubleValue)) {
                return String(numberFormatter.string(from: NSNumber(value: newValue)) ?? "")
            } else {
                return "0.00"
            }
        } else {
            return String(numberFormatter.string(from: NSNumber(value: self)) ?? "")
        }
    }
}

extension UITapGestureRecognizer {
  func didTapAttributedString(_ string: String, in label: UILabel) -> Bool {
    guard let text = label.text else {
      return false
    }
    let range = (text as NSString).range(of: string)
    return self.didTapAttributedText(label: label, inRange: range)
  }
  private func didTapAttributedText(label: UILabel, inRange targetRange: NSRange) -> Bool {
    guard let attributedText = label.attributedText else {
      assertionFailure("attributedText must be set")
      return false
    }
    let textContainer = createTextContainer(for: label)
    let layoutManager = NSLayoutManager()
    layoutManager.addTextContainer(textContainer)
    let textStorage = NSTextStorage(attributedString: attributedText)
    if let font = label.font {
      textStorage.addAttribute(NSAttributedString.Key.font, value: font, range: NSMakeRange(0, attributedText.length))
    }
    textStorage.addLayoutManager(layoutManager)
    let locationOfTouchInLabel = location(in: label)
    let textBoundingBox = layoutManager.usedRect(for: textContainer)
    let alignmentOffset = aligmentOffset(for: label)
    let xOffset = ((label.bounds.size.width - textBoundingBox.size.width) * alignmentOffset) - textBoundingBox.origin.x
    let yOffset = ((label.bounds.size.height - textBoundingBox.size.height) * alignmentOffset) - textBoundingBox.origin.y
    let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - xOffset, y: locationOfTouchInLabel.y - yOffset)
    let characterTapped = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    let lineTapped = Int(ceil(locationOfTouchInLabel.y / label.font.lineHeight)) - 1
    let rightMostPointInLineTapped = CGPoint(x: label.bounds.size.width, y: label.font.lineHeight * CGFloat(lineTapped))
    let charsInLineTapped = layoutManager.characterIndex(for: rightMostPointInLineTapped, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
    return characterTapped <= charsInLineTapped ? targetRange.contains(characterTapped) : false
  }
  private func createTextContainer(for label: UILabel) -> NSTextContainer {
    let textContainer = NSTextContainer(size: label.bounds.size)
    textContainer.lineFragmentPadding = 0.0
    textContainer.lineBreakMode = label.lineBreakMode
    textContainer.maximumNumberOfLines = label.numberOfLines
    return textContainer
  }
  private func aligmentOffset(for label: UILabel) -> CGFloat {
    switch label.textAlignment {
    case .left, .natural, .justified:
      return 0.0
    case .center:
      return 0.5
    case .right:
      return 1.0
    @unknown default:
      return 0.0
    }
  }
}

extension UIStoryboard {
    func instantiateVC<T: UIViewController>(_ id: T.Type) -> T {
        guard let controller = self.instantiateViewController(withIdentifier: String(describing: id)) as? T else {
            fatalError("could not cast UIViewController")
        }
        return controller
    }
}

extension UIImageView {
    func shadow(offset: CGSize, opacity: Float = 0.25, color: UIColor = .black, radius: CGFloat = 1) {
        self.layer.shadowColor = color.cgColor
        self.layer.shadowOffset = offset
        self.layer.shadowOpacity = opacity
        self.layer.shadowRadius = radius
        self.layer.masksToBounds = false
    }
}

extension UITableView {
    func setupPadding() {
        if #available(iOS 15.0, *) {
            self.sectionHeaderTopPadding = 0
        }
    }
    
    func groupStyleHeader() {
        if self.tableHeaderView == nil {
            var frame = CGRect.zero
            frame.size.height = .leastNormalMagnitude
            self.tableHeaderView = UIView(frame: frame)
        }
        self.sectionHeaderHeight = 0
    }
    
    func groupStyleFooter() {
        if self.tableFooterView == nil {
            var frame = CGRect.zero
            frame.size.height = .leastNormalMagnitude
            self.tableFooterView = UIView(frame: frame)
        }
        self.sectionFooterHeight = 0
    }

    func groupStyleSpacing() {
        groupStyleHeader()
        groupStyleFooter()
    }
}

extension UIView {
    static var nib: UINib {
        UINib(nibName: "\(self)", bundle: nil)
    }
}

extension UITapGestureRecognizer {
    func didTapAttributedTextInLabel(label: UILabel, inRange targetRange: NSRange) -> Bool {
        let layoutManager = NSLayoutManager()
        let textContainer = NSTextContainer(size: CGSize.zero)
        let textStorage = NSTextStorage(attributedString: label.attributedText!)
        layoutManager.addTextContainer(textContainer)
        textStorage.addLayoutManager(layoutManager)
        textContainer.lineFragmentPadding = 0.0
        textContainer.lineBreakMode = label.lineBreakMode
        textContainer.maximumNumberOfLines = label.numberOfLines
        let labelSize = label.bounds.size
        textContainer.size = labelSize
        let locationOfTouchInLabel = location(in: label)
        let textBoundingBox = layoutManager.usedRect(for: textContainer)
        let textContainerOffset = CGPoint(x: (labelSize.width - textBoundingBox.size.width) * 0.5 - textBoundingBox.origin.x, y: (labelSize.height - textBoundingBox.size.height) * 0.5 - textBoundingBox.origin.y)
        let locationOfTouchInTextContainer = CGPoint(x: locationOfTouchInLabel.x - textContainerOffset.x, y: locationOfTouchInLabel.y - textContainerOffset.y)
        let indexOfCharacter = layoutManager.characterIndex(for: locationOfTouchInTextContainer, in: textContainer, fractionOfDistanceBetweenInsertionPoints: nil)
        return NSLocationInRange(indexOfCharacter, targetRange)
    }
}

extension Range where Bound == String.Index {
    var nsRange: NSRange {
        return NSRange(location: lowerBound.encodedOffset,
                       length: upperBound.encodedOffset - lowerBound.encodedOffset)
    }
}

extension Decodable {
    static func parse(_ obj: Any) -> Self? {
        do {
            let data = try JSONSerialization.data(withJSONObject: obj, options: .prettyPrinted)
            return try JSONDecoder().decode(self, from: data)
        } catch {
            let error = NSError.init(domain: NSCocoaErrorDomain,
                                     code: 101,
                                     userInfo: ["type": "Model parsing error",
                                                "model type": "\(self)",
                                                "error": "\(error)",
                                                "environment": APIBuilder.webBaseURL,
                                                "consumer id": UserDefault.shared.user?.id ?? "-"])
            Crashlytics.crashlytics().record(error: error)
            return nil
        }
    }
}
