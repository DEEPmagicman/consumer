//
//  RoundedCorners.swift
//  Fan Direct
//
//  Created by Usman Bin Rehan on 2/26/18.
//  Copyright © 2018 Usman Bin Rehan. All rights reserved.
//

import UIKit

class CheckBoxSignin: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        if self.isSelected{
            self.imageView?.backgroundColor = .white
        }
        else{
            self.imageView?.backgroundColor = .clear
        }
    }
}
class vibrateBell: UIImageView{
    override func layoutSubviews() {
        super.layoutSubviews()
        let transformAnim  = CAKeyframeAnimation(keyPath:"transform")
        transformAnim.values  = [NSValue(caTransform3D: CATransform3DMakeRotation(0.2, 0.0, 0.0, 1.0)),NSValue(caTransform3D: CATransform3DMakeRotation(-0.2 , 0, 0, 1))]
        transformAnim.autoreverses = true
        transformAnim.duration  = 0.115
        transformAnim.repeatCount = Float.infinity
        self.layer.add(transformAnim, forKey: "transform")
    }
}
class RoundedStackView: UIStackView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        self.clipsToBounds = true
        
    }
}
class RoundedButton: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        self.clipsToBounds = true
        
        if self.isEnabled {
            self.titleLabel?.textColor = .white
        }
        else{
            self.titleLabel?.textColor = UIColor(red:255/255, green:255/255, blue:255/255, alpha:0.5)
        }
    }
}
class RoundedTextField: UITextField {
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        self.clipsToBounds = true
        
    }
}
class RoundedLabel: UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        self.clipsToBounds = true
    }
}
class RoundedImage : UIImageView{
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        self.clipsToBounds = true
    }
}
class RoundedView : UIView{
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
    }
}
class RoundedSwitch : UISwitch{
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        self.clipsToBounds = true
    }
}
class RoundSenderCorners : UIView{
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(corners: [.topLeft, .topRight, .bottomRight], radius: 24.0)
    }
}
class RoundReceiverCorners : UIView{
    override func layoutSubviews() {
        super.layoutSubviews()
        roundCorners(corners: [.topLeft, .topRight, .bottomLeft], radius: 24.0)
    }
}
class RoundLeftCorners : UIView{
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        let radius = CGFloat(height / 2.0)
        roundCorners(corners: [.topLeft,.bottomLeft], radius: radius)
    }
}
class RoundRightCorners : UIView{
    override func layoutSubviews() {
        super.layoutSubviews()
        let height = self.frame.height
        let radius = CGFloat(height / 2.0)
        roundCorners(corners: [.topRight,.bottomRight], radius: radius)
    }
}
class RotateLabel : UILabel {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.transform = CGAffineTransform(rotationAngle: CGFloat.pi/2)
    }
}
extension UIView {
//    func roundCorners(corners: UIRectCorner, radius: CGFloat) {
//        let path = UIBezierPath(roundedRect: bounds, byRoundingCorners: corners, cornerRadii: CGSize(width: radius, height: radius))
//        let mask = CAShapeLayer()
//        mask.path = path.cgPath
//        layer.mask = mask
//    }
}
extension UIView {
    func shake(){
        let animation = CABasicAnimation(keyPath: "position")
        animation.duration = 0.07
        animation.repeatCount = 3
        animation.autoreverses = true
        animation.fromValue = NSValue(cgPoint: CGPoint(x: self.center.x - 10, y: self.center.y))
        animation.toValue = NSValue(cgPoint: CGPoint(x: self.center.x + 10, y: self.center.y))
        self.layer.add(animation, forKey: "position")
    }
}
class DashedBorderView: UIView {
    override func layoutSubviews() {
        super.layoutSubviews()
        let yourViewBorder = CAShapeLayer()
        yourViewBorder.strokeColor = UIColor(red:187/255, green:187/255, blue:190/255, alpha:1.0).cgColor
        yourViewBorder.lineDashPattern = [4, 4]
        yourViewBorder.frame = self.bounds
        yourViewBorder.fillColor = nil
        yourViewBorder.cornerRadius = 6
        yourViewBorder.path = UIBezierPath(rect: self.bounds).cgPath
        self.layer.addSublayer(yourViewBorder)
    }
}
class ButtonStates: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        self.tintColor = .clear
        if self.isSelected{
            self.setTitleColor(Global.APP_COLOR, for: .selected)
        }
        else{
            self.setTitleColor(UIColor.lightGray, for: .normal)
        }
    }
}
class PlainButton: UIButton {
    override func layoutSubviews() {
        self.tintColor = .clear
        self.setTitleColor(UIColor.white, for: .normal)
        self.setTitleColor(UIColor.white, for: .selected)
    }
}
class ButtonStartCancleTimerStates: UIButton {
    override func layoutSubviews() {
        super.layoutSubviews()
        
        self.tintColor = .clear
        
        let height = self.frame.height
        self.layer.cornerRadius = CGFloat(height / 2.0)
        
        if !self.isEnabled{
            self.backgroundColor = Global.APP_COLOR_DISABLE
            self.setTitleColor(Global.APP_COLOR_DISABLE_TEXT, for: .selected)
        }
        else{
            self.backgroundColor = .white
            self.setTitleColor(Global.APP_COLOR, for: .normal)
        }
    }
}

//final class LoadingButton: UIButton {
//
//    struct ButtonState {
//        var state: UIControl.State
//        var title: String?
//        var image: UIImage?
//    }
//
//    private (set) var buttonStates: [ButtonState] = []
//    private lazy var activityIndicator: UIActivityIndicatorView = {
//        let activityIndicator = UIActivityIndicatorView()
//        activityIndicator.hidesWhenStopped = true
//        activityIndicator.color = self.titleColor(for: .normal)
//        self.addSubview(activityIndicator)
//        activityIndicator.translatesAutoresizingMaskIntoConstraints = false
//        let xCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerX, relatedBy: .equal, toItem: activityIndicator, attribute: .centerX, multiplier: 1, constant: 0)
//        let yCenterConstraint = NSLayoutConstraint(item: self, attribute: .centerY, relatedBy: .equal, toItem: activityIndicator, attribute: .centerY, multiplier: 1, constant: 0)
//        self.addConstraints([xCenterConstraint, yCenterConstraint])
//        return activityIndicator
//    }()
//
//    func showLoading() {
//        activityIndicator.startAnimating()
//        var buttonStates: [ButtonState] = []
//        for state in [UIControl.State.disabled] {
//            let buttonState = ButtonState(state: state, title: title(for: state), image: image(for: state))
//            buttonStates.append(buttonState)
//            setTitle("", for: state)
//            setImage(UIImage(), for: state)
//        }
//        self.buttonStates = buttonStates
//        isEnabled = false
//    }
//
//    func hideLoading() {
//        activityIndicator.stopAnimating()
//        for buttonState in buttonStates {
//            setTitle(buttonState.title, for: buttonState.state)
//            setImage(buttonState.image, for: buttonState.state)
//        }
//        isEnabled = true
//    }
//}
