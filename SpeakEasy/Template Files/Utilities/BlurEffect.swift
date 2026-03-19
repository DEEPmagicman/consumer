//
//  BlurEffect.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 12/12/23.
//

import Foundation

import UIKit

/// VisualEffectView is a dynamic background blur view.
open class VisualEffectView: UIVisualEffectView {
   
   /// Returns the instance of UIBlurEffect.
   private let blurEffect = (NSClassFromString("_UICustomBlurEffect") as! UIBlurEffect.Type).init()
   
   /**
    Tint color.
    
    The default value is nil.
    */
   open var colorTint: UIColor? {
       get {
           if #available(iOS 14, *) {
               return ios14ColorTint
           } else {
               return value(forKey: .colorTint)
           }
       }
       set {
           if #available(iOS 14, *) {
               ios14ColorTint = newValue
           } else {
               setValue(newValue, forKey: .colorTint)
           }
       }
   }
   
   /**
    Tint color alpha.

    Don't use it unless `colorTint` is not nil.
    The default value is 0.0.
    */
   open var colorTintAlpha: CGFloat {
       get { return value(forKey: .colorTintAlpha) ?? 0.0 }
       set {
           if #available(iOS 14, *) {
               ios14ColorTint = ios14ColorTint?.withAlphaComponent(newValue)
           } else {
               setValue(newValue, forKey: .colorTintAlpha)
           }
       }
   }
   
   /**
    Blur radius.
    
    The default value is 0.0.
    */
   open var blurRadius: CGFloat {
       get {
           if #available(iOS 14, *) {
               return ios14BlurRadius
           } else {
               return value(forKey: .blurRadius) ?? 0.0
           }
       }
       set {
           if #available(iOS 14, *) {
               ios14BlurRadius = newValue
           } else {
               setValue(newValue, forKey: .blurRadius)
           }
       }
   }
   
   /**
    Scale factor.
    
    The scale factor determines how content in the view is mapped from the logical coordinate space (measured in points) to the device coordinate space (measured in pixels).
    
    The default value is 1.0.
    */
   open var scale: CGFloat {
       get { return value(forKey: .scale) ?? 1.0 }
       set { setValue(newValue, forKey: .scale) }
   }
   
   // MARK: - Initialization
   
   public override init(effect: UIVisualEffect?) {
       super.init(effect: effect)
       
       scale = 1
   }
   
   required public init?(coder aDecoder: NSCoder) {
       super.init(coder: aDecoder)
       
       scale = 1
   }
   
}

// MARK: - Helpers

private extension VisualEffectView {
   
   /// Returns the value for the key on the blurEffect.
   func value<T>(forKey key: Key) -> T? {
       return blurEffect.value(forKeyPath: key.rawValue) as? T
   }
   
   /// Sets the value for the key on the blurEffect.
   func setValue<T>(_ value: T?, forKey key: Key) {
       blurEffect.setValue(value, forKeyPath: key.rawValue)
//        if #unavailable(iOS, 14) {
//            self.effect = self.blurEffect
//        }
   }
   
   enum Key: String {
       case colorTint, colorTintAlpha, blurRadius, scale
   }
   
}

@available(iOS 14, *)
extension UIVisualEffectView {
   var ios14BlurRadius: CGFloat {
       get {
           return gaussianBlur?.requestedValues?["inputRadius"] as? CGFloat ?? 0
       }
       set {
           prepareForChanges()
           gaussianBlur?.requestedValues?["inputRadius"] = newValue
           applyChanges()
       }
   }
   var ios14ColorTint: UIColor? {
       get {
           return sourceOver?.value(forKeyPath: "color") as? UIColor
       }
       set {
           prepareForChanges()
           sourceOver?.setValue(newValue, forKeyPath: "color")
           sourceOver?.perform(Selector(("applyRequestedEffectToView:")), with: overlayView)
           applyChanges()
           overlayView?.backgroundColor = newValue
       }
   }
}

private extension UIVisualEffectView {
   var backdropView: UIView? {
       return subview(of: NSClassFromString("_UIVisualEffectBackdropView"))
   }
   var overlayView: UIView? {
       return subview(of: NSClassFromString("_UIVisualEffectSubview"))
   }
   var gaussianBlur: NSObject? {
       return backdropView?.value(forKey: "filters", withFilterType: "gaussianBlur")
   }
   var sourceOver: NSObject? {
       return overlayView?.value(forKey: "viewEffects", withFilterType: "sourceOver")
   }
   func prepareForChanges() {
       self.effect = UIBlurEffect(style: .light)
       gaussianBlur?.setValue(1.0, forKeyPath: "requestedScaleHint")
   }
   func applyChanges() {
       backdropView?.perform(Selector(("applyRequestedFilterEffects")))
   }
}

private extension NSObject {
   var requestedValues: [String: Any]? {
       get { return value(forKeyPath: "requestedValues") as? [String: Any] }
       set { setValue(newValue, forKeyPath: "requestedValues") }
   }
   func value(forKey key: String, withFilterType filterType: String) -> NSObject? {
       return (value(forKeyPath: key) as? [NSObject])?.first { $0.value(forKeyPath: "filterType") as? String == filterType }
   }
}

private extension UIView {
   func subview(of classType: AnyClass?) -> UIView? {
       return subviews.first { type(of: $0) == classType }
   }
}
