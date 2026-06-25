//
//  TicketConfirmationVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/02/26.
//

import UIKit

class TicketConfirmationVC: UIViewController {
    
//    @IBOutlet weak var venueLogoImg: UIImageView!
    @IBOutlet weak var venueName: UILabel!
//    @IBOutlet weak var venueName2: UILabel!
    @IBOutlet weak var dateandtimeLbl: UILabel!
    @IBOutlet weak var eventTitleLbl: UILabel!
    @IBOutlet weak var noteLbl: UILabel!
    @IBOutlet weak var eventImgView: UIImageView!
    @IBOutlet weak var viewTicketBtn: UIButton!
    @IBOutlet weak var viewTicketBtnView: UIView!
    @IBOutlet weak var ticketCardView: TicketCardView!
    
    @IBOutlet weak var faqTableView: UITableView!
    @IBOutlet weak var faqTableViewHeight: NSLayoutConstraint!
    
    var booking: Booking?
    var venueDetails: ClipVenue?
    var event: Event?
    var bookingId: String?
    private var faqs: [(question: String, answer: String)] = [
        (
            question: "A note from the venue",
            answer: ""
        )
    ]

    private var expandedFAQIndex: Int?
    private var isUpdatingTableHeight = false
    private var wasInteractivePopGestureEnabled = true
    private let titleMarqueeLabel = PremiumMarqueeLabel()

    private let paymentService = PaymentService()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupTitleMarqueeLabel()
        getBooking(id: bookingId ?? "be5af872-e29d-4115-93ab-6660d47662eb")
        setupFAQTableView()
        setupKVO()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)

        wasInteractivePopGestureEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled ?? true
        navigationController?.interactivePopGestureRecognizer?.isEnabled = false
        ticketCardView.playEntryAnimation()
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        navigationController?.interactivePopGestureRecognizer?.isEnabled = wasInteractivePopGestureEnabled
    }
    
    private func setupData() {

        guard let booking = booking else { return }
        venueDetails = booking.venueObject
        noteLbl.text = booking.note ?? ""

        let dressCode = (venueDetails?.dressCode ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        if !dressCode.isEmpty {
            faqs[0].answer = dressCode
            faqTableView.reloadData()
        }
//        venueLogoImg.sd_setImage(
//            with: URL(string: (venueDetails?.logo?.key ?? "").imageURL),
//            placeholderImage: Constant.Icon.uploadImage
//        )
        event = booking.event

        venueName.text = venueDetails?.name ?? ""
//        venueName2.text = venueDetails?.name ?? ""
        setHeaderTitle(event?.title ?? "")
//        eventImgView.sd_setImage(
//            with: URL(string: (event?.flyer?.key ?? "").imageURL),
//            placeholderImage: Constant.Icon.uploadImage
//        )
        if let imageUrlString = event?.flyer?.key?.imageURL {
            
            ticketCardView.setImage(named: "demo venue")
            if let url = URL(string: imageUrlString) {
                SDWebImageManager.shared.loadImage(with: url, options: .highPriority, progress: nil) {
                    [weak self] image, _, _, _, _, _ in
                    guard let self else { return }
                    DispatchQueue.main.async {
                        self.ticketCardView.setImage(image ?? UIImage(named: "newSpeakeasy"))
                    }
                }
            } else {
                ticketCardView.setImage(named: "newSpeakeasy")
            }
        }
        
        if let hexColor = event?.whiteLabelColor {
            let color = UIColor(hex: hexColor)
//            viewTicketBtnView.backgroundColor = color
//            dateandtimeLbl.textColor = color
        }
        
        let timezone = venueDetails?.useTimezone ?? ""

        let dateText = event?.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .EEEMMMD,
            customTimeZone: timezone
        )

        let startTime = event?.startDateTime.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .hmma,
            customTimeZone: timezone
        )

        let endTime = event?.endDateTime?.convertDateFormat(
            from: .yyyyMMddHHmmss,
            to: .hmma,
            customTimeZone: timezone
        ) ?? ""

        dateandtimeLbl.text = "\(dateText ?? "") at \(startTime ?? "") - \(endTime)"
        
        noteLbl.text = booking.note ?? ""
        if let customText = event?.venue?.dressCode,
           !customText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
        }
    }

    private func setupTitleMarqueeLabel() {
        titleMarqueeLabel.install(over: eventTitleLbl, horizontalInset: 72)
    }

    private func setHeaderTitle(_ title: String?) {
        titleMarqueeLabel.setText(title)
    }
    
    private func setupFAQTableView() {
        faqTableView.delegate = self
        faqTableView.dataSource = self

        faqTableView.register(
            FAQsTableViewCell.nib,
            forCellReuseIdentifier: FAQsTableViewCell.identifier
        )

        faqTableView.rowHeight = UITableView.automaticDimension
        faqTableView.estimatedRowHeight = 80
        faqTableView.separatorStyle = .none
        faqTableView.isScrollEnabled = false
    }
    
    private func setupKVO() {
        faqTableView.addObserver(
            self,
            forKeyPath: "contentSize",
            options: .new,
            context: nil
        )
    }
    
    deinit {
        faqTableView?.removeObserver(
            self,
            forKeyPath: "contentSize"
        )
    }
    
    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        guard keyPath == "contentSize",
              let tableView = object as? UITableView,
              tableView == faqTableView,
              !isUpdatingTableHeight else {
            return
        }

        let newHeight = tableView.contentSize.height

        guard faqTableViewHeight.constant != newHeight else {
            return
        }

        isUpdatingTableHeight = true

        faqTableViewHeight.constant = newHeight
        view.layoutIfNeeded()

        isUpdatingTableHeight = false
    }
    
    @IBAction func onClickViewtTicket(_ sender: Any) {
        Navigate.to.showQRCode(
            self,
            booking: nil,
            bookingId: self.bookingId ?? "",
            type: .singleTickedEvent,
            sourceEvent: self.event,
            presentationMode: .pushedFromPurchase
        )
    }
    
    @IBAction func onClickCloseBtn(_ sender: Any) {
        returnToDiscoverScreen()
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        returnToDiscoverScreen()
    }

    private func returnToDiscoverScreen() {
        if let tabBarController {
            tabBarController.selectedIndex = 0
        }

        if let navigationController {
            navigationController.popToRootViewController(animated: false)
        } else {
            dismiss(animated: false)
        }
    }
    
    private func getBooking(id: String) {
        paymentService.fetchBookingDetail(bookingId: id) { [weak self] isSuccess, _, booking in
            guard let self = self else { return }
            if isSuccess {
                self.booking = booking
                self.setupData()
                
            } else {
//                self.eventDetailView.isHidden = true
            }
        }
    }
}

extension TicketConfirmationVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {
        return faqs.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as! FAQsTableViewCell

        let item = faqs[indexPath.row]

        cell.questionLbl.text = item.question
        cell.ansLbl.text = item.answer
        cell.selectionStyle = .none
        cell.ansView.isHidden = expandedFAQIndex != indexPath.row

        cell.onToggle = { [weak self] in
            guard let self = self else { return }

            let previous = self.expandedFAQIndex
            self.expandedFAQIndex =
                (self.expandedFAQIndex == indexPath.row)
                ? nil
                : indexPath.row

            var indexPaths = [indexPath]

            if let previous,
               previous != indexPath.row {
                indexPaths.append(
                    IndexPath(row: previous, section: 0)
                )
            }

            UIView.performWithoutAnimation {
                self.faqTableView.reloadRows(
                    at: indexPaths,
                    with: .none
                )
            }

            self.faqTableView.beginUpdates()
            self.faqTableView.endUpdates()
        }

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        expandedFAQIndex =
            (expandedFAQIndex == indexPath.row)
            ? nil
            : indexPath.row

        faqTableView.reloadData()
    }
}



import UIKit
import SDWebImage

@IBDesignable
final class TicketCardView: UIView {

    private let imageView = UIImageView()
    private let maskLayer = CAShapeLayer()
    private let shineLayer = CAGradientLayer()

    @IBInspectable var image: UIImage? {
        didSet {
            imageView.image = image
        }
    }

    @IBInspectable var shadowOffsetX: CGFloat = 1 {
        didSet {
            layer.shadowOffset.width = shadowOffsetX
        }
    }

    @IBInspectable var shadowOffsetY: CGFloat = 1 {
        didSet {
            layer.shadowOffset.height = shadowOffsetY
        }
    }

    @IBInspectable var enablePerspective: Bool = true {
        didSet {
            applyPerspective()
        }
    }

    @IBInspectable var rotateY: CGFloat = -10 {
        didSet {
            applyPerspective()
        }
    }

    @IBInspectable var rotateX: CGFloat = 2 {
        didSet {
            applyPerspective()
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    override func prepareForInterfaceBuilder() {
        super.prepareForInterfaceBuilder()
        commonInit()
    }

    private func commonInit() {
        backgroundColor = .clear
        clipsToBounds = false

        setupImageView()
        setupShineLayer()
        setupShadow()
        applyPerspective()
    }
//
//    private func setupBorder() {
//        if borderLayer.superlayer == nil {
//            layer.addSublayer(borderLayer)
//        }
//
//        borderLayer.fillColor = UIColor.clear.cgColor
//        borderLayer.strokeColor = UIColor.white.withAlphaComponent(0.08).cgColor
//        borderLayer.lineWidth = 2
//    }

    private func setupImageView() {
        if imageView.superview == nil {
            addSubview(imageView)
        }

        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.mask = maskLayer
    }

    private func setupShadow() {
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOpacity = 0.09
        layer.shadowRadius = 12
        layer.shadowOffset = CGSize(width: 1, height: 1)
        layer.masksToBounds = false
    }

    override func layoutSubviews() {
        super.layoutSubviews()

        imageView.frame = bounds

        let path = makeTicketPath(in: bounds)

        maskLayer.frame = bounds
        maskLayer.path = path.cgPath

        shineLayer.frame = bounds
        shineLayer.mask = {
            let layer = CAShapeLayer()
            layer.frame = bounds
            layer.path = path.cgPath
            return layer
        }()

        layer.shadowPath = path.cgPath

        applyPerspective()
    }
    
   
    
    
    private func playShineAnimation(delay: TimeInterval = 0.55) {
        shineLayer.removeAnimation(forKey: "shineAnimation")

        shineLayer.opacity = 1
        shineLayer.transform = CATransform3DMakeRotation(CGFloat(18 * Double.pi / 180), 0, 0, 1)

        let animation = CABasicAnimation(keyPath: "position.x")
        animation.fromValue = -bounds.width
        animation.toValue = bounds.width * 2
        animation.duration = 0.85
        animation.beginTime = CACurrentMediaTime() + delay
        animation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        animation.fillMode = .removed

        shineLayer.add(animation, forKey: "shineAnimation")

        DispatchQueue.main.asyncAfter(deadline: .now() + delay + 0.85) { [weak self] in
            self?.shineLayer.opacity = 0
        }
    }
    
    func playEntryAnimation(delay: TimeInterval = 0.15) {
        layoutIfNeeded()

        // Initial state
        alpha = 0
        layer.opacity = 0
        transform = CGAffineTransform(scaleX: 0.75, y: 0.75)
            .translatedBy(x: 0, y: 40)

        // Reset 3D transform first
        layer.transform = CATransform3DIdentity

        DispatchQueue.main.asyncAfter(deadline: .now() + delay) { [weak self] in
            guard let self = self else { return }

            // UIKit pop animation
            UIView.animate(
                withDuration: 0.75,
                delay: 0,
                usingSpringWithDamping: 0.65,
                initialSpringVelocity: 0.8,
                options: [.curveEaseOut]
            ) {
                self.alpha = 1
                self.transform = .identity
            }

            // 3D flip + settle animation
            let animation = CAKeyframeAnimation(keyPath: "transform")
            animation.duration = 0.95
            animation.timingFunctions = [
                CAMediaTimingFunction(name: .easeOut),
                CAMediaTimingFunction(name: .easeInEaseOut),
                CAMediaTimingFunction(name: .easeOut)
            ]

            var start = CATransform3DIdentity
            start.m34 = -1.0 / 700.0
            start = CATransform3DRotate(start, CGFloat(-35 * Double.pi / 180), 0, 1, 0)
            start = CATransform3DRotate(start, CGFloat(10 * Double.pi / 180), 1, 0, 0)
            start = CATransform3DScale(start, 0.78, 0.78, 1)

            var middle = CATransform3DIdentity
            middle.m34 = -1.0 / 700.0
            middle = CATransform3DRotate(middle, CGFloat(8 * Double.pi / 180), 0, 1, 0)
            middle = CATransform3DRotate(middle, CGFloat(-3 * Double.pi / 180), 1, 0, 0)
            middle = CATransform3DScale(middle, 1.04, 1.04, 1)

            var end = CATransform3DIdentity
            end.m34 = -1.0 / 700.0
            end = CATransform3DRotate(end, self.rotateY * .pi / 180, 0, 1, 0)
            end = CATransform3DRotate(end, self.rotateX * .pi / 180, 1, 0, 0)

            animation.values = [
                start,
                middle,
                end
            ]

            self.layer.transform = end
            self.layer.add(animation, forKey: "ticketEntry3DAnimation")
        }
    }
    
    private func setupShineLayer() {
        if shineLayer.superlayer == nil {
            layer.addSublayer(shineLayer)
        }

        shineLayer.colors = [
            UIColor.white.withAlphaComponent(0.0).cgColor,
            UIColor.white.withAlphaComponent(0.22).cgColor,
            UIColor.white.withAlphaComponent(0.0).cgColor
        ]

        shineLayer.locations = [0.0, 0.5, 1.0]
        shineLayer.startPoint = CGPoint(x: 0, y: 0.5)
        shineLayer.endPoint = CGPoint(x: 1, y: 0.5)
        shineLayer.opacity = 0
    }

    private func makeTicketPath(in rect: CGRect) -> UIBezierPath {
        let originalWidth: CGFloat = 297
        let originalHeight: CGFloat = 288

        let scaleX = rect.width / originalWidth
        let scaleY = rect.height / originalHeight

        func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            return CGPoint(
                x: rect.minX + x * scaleX,
                y: rect.minY + y * scaleY
            )
        }

        let path = UIBezierPath()

        // Converted from your SVG path
        path.move(to: p(11, 23.0433))

        path.addCurve(
            to: p(25.0146, 11.1185),
            controlPoint1: p(11.0001, 15.7292),
            controlPoint2: p(17.6108, 10.1044)
        )

        path.addLine(to: p(273.398, 45.139))

        path.addCurve(
            to: p(284, 57.0638),
            controlPoint1: p(279.477, 45.9716),
            controlPoint2: p(284, 51.0587)
        )

        path.addLine(to: p(284, 117.598))

        path.addCurve(
            to: p(267.055, 143.5),
            controlPoint1: p(274.314, 120.173),
            controlPoint2: p(267.055, 130.791)
        )

        path.addCurve(
            to: p(284, 169.402),
            controlPoint1: p(267.055, 156.209),
            controlPoint2: p(274.314, 166.826)
        )

        path.addLine(to: p(284, 227.137))

        path.addCurve(
            to: p(273.459, 239.053),
            controlPoint1: p(284, 233.119),
            controlPoint2: p(279.511, 238.194)
        )

        path.addLine(to: p(25.0742, 274.288))

        path.addCurve(
            to: p(11, 262.372),
            controlPoint1: p(17.6515, 275.341),
            controlPoint2: p(11.0001, 269.71)
        )

        path.addLine(to: p(11, 180.707))

        path.addCurve(
            to: p(33.8984, 143.5),
            controlPoint1: p(24.3459, 175.252),
            controlPoint2: p(33.8983, 160.655)
        )

        path.addCurve(
            to: p(11, 106.291),
            controlPoint1: p(33.8984, 126.346),
            controlPoint2: p(24.3462, 111.747)
        )

        path.addLine(to: p(11, 23.0433))

        path.close()
        return path
    }

    private func applyPerspective() {
        guard enablePerspective else {
            layer.transform = CATransform3DIdentity
            return
        }

        var transform = CATransform3DIdentity
        transform.m34 = -1.0 / 700.0

        let yAngle = rotateY * .pi / 180
        let xAngle = rotateX * .pi / 180

        transform = CATransform3DRotate(transform, yAngle, 0, 1, 0)
        transform = CATransform3DRotate(transform, xAngle, 1, 0, 0)

        layer.transform = transform
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
    }

    func setImage(named name: String) {
        imageView.image = UIImage(named: name)
    }
}
