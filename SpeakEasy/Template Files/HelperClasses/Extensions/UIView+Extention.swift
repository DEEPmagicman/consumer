import UIKit

extension UIView {
    
    @IBInspectable var cornerRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            layer.cornerRadius = newValue
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var borderWidth: CGFloat {
        get {
            return layer.borderWidth
        }
        set {
            layer.borderWidth = newValue
        }
    }
    
    @IBInspectable var borderColor: UIColor? {
        get {
            return UIColor(cgColor: layer.borderColor!)
        }
        set {
            layer.borderColor = newValue?.cgColor
        }
    }
    
    class func fromNib<T : UIView>() -> T {
        return Bundle.main.loadNibNamed(String(describing: T.self), owner: nil, options: nil)![0] as! T
    }
    @IBInspectable var topRightRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .topRight, cornerRadii: CGSize(width: newValue, height: newValue))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var bottomRightRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .bottomRight, cornerRadii: CGSize(width: newValue, height: newValue))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var bottomLeftRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .bottomLeft, cornerRadii: CGSize(width: newValue, height: newValue))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
            layer.masksToBounds = newValue > 0
        }
    }
    
    @IBInspectable var topLeftRadius: CGFloat {
        get {
            return layer.cornerRadius
        }
        set {
            let path = UIBezierPath(roundedRect: self.bounds, byRoundingCorners: .topLeft, cornerRadii: CGSize(width: newValue, height: newValue))
            let mask = CAShapeLayer()
            mask.path = path.cgPath
            self.layer.mask = mask
            layer.masksToBounds = newValue > 0
        }
    }
}
