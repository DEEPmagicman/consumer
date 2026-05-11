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
            if let town = placeMark.locality, placeMark.country != nil, placeMark.administrativeArea != nil {
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
    var validateDouble: Bool {
        if Double(self) != nil {
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
//        if useDayLightSavingTime {
//            return convertDateFormatter.string(from: oldDate.addingTimeInterval(convertDateFormatter.timeZone.daylightSavingTimeOffset()))
//        } else {
            return convertDateFormatter.string(from: oldDate)
//        }
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
    
    func dateFormatter(formate: DateFormat = .yyyyMMddTHHmmssSSSz, isTimeZoneChanged: Bool = false, isUTC: Bool = false) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = .current
        dateFormatter.dateFormat = formate.rawValue
        if !isTimeZoneChanged {
            dateFormatter.timeZone = Constant.venueTimeZone
        }
        if isUTC {
            dateFormatter.timeZone = TimeZone(identifier: "UTC")!
        }
        return dateFormatter.date(from: self)
    }
}

extension Date {
    func startOfMonth() -> Date {
        return Calendar.current.date(from: Calendar.current.dateComponents([.year, .month], from: Calendar.current.startOfDay(for: self)))!
    }
    func endOfMonth() -> Date {
        return Calendar.current.date(byAdding: DateComponents(month: 1, day: -1), to: self.startOfMonth())!
    }
    
    var age: Int {
        let now = Date()
        let calendar = Calendar.current
        
        let ageComponents = calendar.dateComponents([.year], from: self, to: now)
        return ageComponents.year ?? 0
    }
    
    static func venueNow(timezone: String?) -> Date {
          let tz = timezone ?? TimeZone.current.identifier
          let timeZone = TimeZone(identifier: tz) ?? .current

          let formatter = DateFormatter()
          formatter.locale = Locale(identifier: "en_US_POSIX")
          formatter.timeZone = timeZone
          formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"

          return formatter.date(from: formatter.string(from: Date())) ?? Date()
      }
}

extension Double {
    // For reducing value as per scale down value
//    var scaledValue: Double {
//        self / Double(FixValue.scale)
//    }
    
    func decimalFormat(_ valueDouble: Bool = false) -> String {
        let numberFormatter = NumberFormatter()
        numberFormatter.minimumFractionDigits = valueDouble ? 2 : 0
        numberFormatter.numberStyle = .decimal
        if valueDouble {
            if let newValue =  Double(String(format: "%.2f", NSNumber(value: self).doubleValue)) {
                return String(numberFormatter.string(from: NSNumber(value: newValue)) ?? "")
            } else {
                return "0.00"
            }
        } else {
            let decimalPrice = Int(String(self).components(separatedBy: ".").last ?? "0")
            numberFormatter.minimumFractionDigits = decimalPrice ?? 0 > 0 ? 2 : 0
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
    
    func dequeue<T: UITableViewCell>(withIdentifier id: String, for ipp: IndexPath) -> T {
        guard let cell = dequeueReusableCell(withIdentifier: id, for: ipp) as? T else {
            fatalError("could not cast cell")
        }
        return cell
    }

    func dequeue<T: UITableViewHeaderFooterView>(withIdentifier id: String) -> T {
        guard let view = dequeueReusableHeaderFooterView(withIdentifier: id) as? T else {
            fatalError("could not cast view")
        }
        return view
    }
    
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
    static var identifier: String {
        String(describing: Self.self)
    }
}

extension UIView {
    
    func applyGradient(id: String) {
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        let colors = gradientColors(for: id)
        
        let gradient = CAGradientLayer()
        gradient.frame = bounds
        gradient.cornerRadius = bounds.height / 2
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        
        layer.insertSublayer(gradient, at: 0)
    }
    
    private func gradientColors(for id: String) -> [UIColor] {
        let palettes: [[UIColor]] = [
            [UIColor(hex: "#f9d423"), UIColor(hex: "#ff4e50")],
            [UIColor(hex: "#a1ffce"), UIColor(hex: "#faffd1")],
            [UIColor(hex: "#fbc2eb"), UIColor(hex: "#a6c1ee")],
            [UIColor(hex: "#fad0c4"), UIColor(hex: "#ffd1ff")],
            [UIColor(hex: "#89f7fe"), UIColor(hex: "#66a6ff")],
            [UIColor(hex: "#fbc2eb"), UIColor(hex: "#f9d423")],
            [UIColor(hex: "#ffecd2"), UIColor(hex: "#fcb69f")],
            [UIColor(hex: "#a18cd1"), UIColor(hex: "#fbc2eb")]
        ]
        
        let index = abs(id.hashValue) % palettes.count
        return palettes[index]
    }
    
    enum GradientDirection {
        case topToBottom
        case bottomToTop
        case leftToRight
        case rightToLeft

        var startPoint: CGPoint {
            switch self {
            case .topToBottom: return CGPoint(x: 0.5, y: 0.0)
            case .bottomToTop: return CGPoint(x: 0.5, y: 1.0)
            case .leftToRight: return CGPoint(x: 0.0, y: 0.5)
            case .rightToLeft: return CGPoint(x: 1.0, y: 0.5)
            }
        }

        var endPoint: CGPoint {
            switch self {
            case .topToBottom: return CGPoint(x: 0.5, y: 1.0)
            case .bottomToTop: return CGPoint(x: 0.5, y: 0.0)
            case .leftToRight: return CGPoint(x: 1.0, y: 0.5)
            case .rightToLeft: return CGPoint(x: 0.0, y: 0.5)
            }
        }
    }
    
    func applyScreenBgGradient(
        colors: [UIColor] = [AppColor.background, AppColor.primaryColor],
        direction: GradientDirection = .topToBottom
    ) {
        layer.sublayers?.removeAll(where: { $0 is CAGradientLayer })
        
        let gradient = CAGradientLayer()
        gradient.colors = colors.map { $0.cgColor }
        gradient.startPoint = direction.startPoint
        gradient.endPoint = direction.endPoint
        gradient.frame = bounds
        
        layer.insertSublayer(gradient, at: 0)
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
            print("---\(error)")
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


extension UITextView {

    func setPlaceholder(_ text: String) {
        let placeholderLabel = UILabel()
        placeholderLabel.text = text
        placeholderLabel.textColor = .lightGray
        placeholderLabel.font = self.font
        placeholderLabel.sizeToFit()
        placeholderLabel.frame.origin = CGPoint(x: 5, y: 8)
        placeholderLabel.tag = 999

        self.addSubview(placeholderLabel)

        NotificationCenter.default.addObserver(forName: UITextView.textDidChangeNotification, object: self, queue: .main) { _ in
            placeholderLabel.isHidden = !self.text.isEmpty
        }
    }
}

extension NSMutableAttributedString {
    func trimTrailingWhitespaceAndNewlines() {
        let ws = CharacterSet.whitespacesAndNewlines
        while length > 0 {
            let lastRange = NSRange(location: length - 1, length: 1)
            let lastChar = (string as NSString).substring(with: lastRange)
            if lastChar.rangeOfCharacter(from: ws) != nil {
                deleteCharacters(in: lastRange)
            } else {
                break
            }
        }
    }

    func forceSystemFont15() {
        let base = Constant.Font.interRegular(size: 12)

        enumerateAttribute(.font, in: NSRange(location: 0, length: length)) { value, range, _ in
            let traits = (value as? UIFont)?.fontDescriptor.symbolicTraits ?? []
            let descriptor = base.fontDescriptor.withSymbolicTraits(traits) ?? base.fontDescriptor
            let newFont = UIFont(descriptor: descriptor, size: 12)
            self.addAttribute(.font, value: newFont, range: range)
        }
    }
}

extension UIColor {
    func suitableTextColor() -> UIColor {
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        self.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let brightness = (red * 299 + green * 587 + blue * 114) / 1000
        return brightness > 0.6 ? .black : .white
    }
}
