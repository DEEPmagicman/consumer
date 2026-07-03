//
//  CoverQRCodeVC.swift
//  SpeakEasy-Consumer
//

import UIKit
import FSPagerView
import PassKit

final class CoverQRCodeVC: UIViewController {

    @IBOutlet weak var backgroundContainerView: UIView!
    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var buyAnotherTicketBtn: UIButton!
    @IBOutlet weak var progressBarView: UIView!
    @IBOutlet weak var cityLbl: UILabel!
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            pagerView.register(
                UINib(nibName: "CustomQRCodePagerViewCell", bundle: nil),
                forCellWithReuseIdentifier: CustomQRCodePagerViewCell.identifier
            )
        }
    }
    @IBOutlet weak var addToWalletBtn: UIButton!
    @IBOutlet weak var pagerViewheight: NSLayoutConstraint!

    // MARK: - Data
    weak var delegate: QRCodeVCNavigationDelegate?
    var qrImage: UIImage?
    var addOnsQRImage: UIImage?
    var booking: Booking?
    var addOnsBooking: AddOnsBooking?
    var venue: ClipVenue?
    var bookingId: String = ""
    var addOnsBookingId: String = ""
    var isAddOnsAvailable: Bool = false
    var isOnlyAddOnAvailable: Bool = false
    var venueId = String()
    var venueNameText: String? = ""
    var shouldReturnToVenueAfterClose = false

    private let paymentService = PaymentService()
    private let posterHeaderView = VenuePosterHeaderView()
    private var dotViews: [UIView] = []
    private let scrollView = UIScrollView()
    private weak var scrollContentView: UIView?
    private var scrollContentHeightConstraint: NSLayoutConstraint?
    private var pagerHeightCandidates: [Int: CGFloat] = [:]
    private var currentPage: Int = 0
    private let preferredPagerHeight: CGFloat = 465
    private var currentPagerHeight: CGFloat = 465
    private var pass: PKPass?
    private let venueNameMarqueeLabel = PremiumMarqueeLabel()
    private var wasInteractivePopGestureEnabled: Bool?
    private weak var interactivePopNavigationController: UINavigationController?

    private var showsAddOnsPage: Bool {
        isAddOnsAvailable && !isOnlyAddOnAvailable
    }

    private var pagerItemCount: Int {
        showsAddOnsPage ? 2 : 1
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollableLayout()
        configurePresentationDismissBehavior()
        setupUI()
        setupPosterBackground()
        setupPagerView()

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: UIApplication.willEnterForegroundNotification,
            object: nil
        )
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(refreshData),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        loadInitialData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        clipPagerOverflow()
        updateScrollableContentHeight()
        updatePagerItemSize(height: currentPagerHeight)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configurePresentationDismissBehavior()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        disableInteractiveBackNavigation()
        WebSocketWrapper.shared.addDelegate(self) 
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        if let wasInteractivePopGestureEnabled {
            interactivePopNavigationController?.interactivePopGestureRecognizer?.isEnabled = wasInteractivePopGestureEnabled
            self.wasInteractivePopGestureEnabled = nil
            interactivePopNavigationController = nil
        }
        WebSocketWrapper.shared.removeDelegate(self)
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func configurePresentationDismissBehavior() {
        modalPresentationStyle = .fullScreen
        isModalInPresentation = true
        presentationController?.delegate = self
    }

    private func disableInteractiveBackNavigation() {
        guard interactivePopNavigationController == nil else { return }

        interactivePopNavigationController = navigationController
        wasInteractivePopGestureEnabled = navigationController?.interactivePopGestureRecognizer?.isEnabled
        interactivePopNavigationController?.interactivePopGestureRecognizer?.isEnabled = false
    }

    private func setupScrollableLayout() {
        guard scrollContentView == nil else { return }

        let contentView = view!
        let rootView = UIView(frame: contentView.frame)
        rootView.backgroundColor = contentView.backgroundColor ?? .black

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.backgroundColor = .clear
        scrollView.alwaysBounceVertical = false
        scrollView.showsVerticalScrollIndicator = false

        view = rootView
        rootView.addSubview(scrollView)

        contentView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentView)
        scrollContentView = contentView

        let heightConstraint = contentView.heightAnchor.constraint(
            equalToConstant: max(rootView.bounds.height, UIScreen.main.bounds.height)
        )
        scrollContentHeightConstraint = heightConstraint

        NSLayoutConstraint.activate([
            scrollView.topAnchor.constraint(equalTo: rootView.topAnchor),
            scrollView.leadingAnchor.constraint(equalTo: rootView.leadingAnchor),
            scrollView.trailingAnchor.constraint(equalTo: rootView.trailingAnchor),
            scrollView.bottomAnchor.constraint(equalTo: rootView.bottomAnchor),

            contentView.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentView.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentView.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentView.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentView.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            heightConstraint
        ])
    }

    private func setupUI() {
        setupHeaderLabels()
        setVenueTitle(venueNameText?.isEmpty == false ? venueNameText : (venue?.name.isEmpty == false ? venue?.name : "-"))
        cityLbl.text = venue?.city
    }

    private func setupHeaderLabels() {
        setupVenueTitleMarquee()

        cityLbl.numberOfLines = 1
        cityLbl.lineBreakMode = .byTruncatingTail
        cityLbl.textAlignment = .center
        cityLbl.adjustsFontSizeToFitWidth = true
        cityLbl.minimumScaleFactor = 0.8

        NSLayoutConstraint.activate([
            venueName.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 72
            ),
            venueName.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24
            ),
            cityLbl.leadingAnchor.constraint(
                greaterThanOrEqualTo: view.leadingAnchor,
                constant: 24
            ),
            cityLbl.trailingAnchor.constraint(
                lessThanOrEqualTo: view.trailingAnchor,
                constant: -24
            )
        ])
    }

    private func setupVenueTitleMarquee() {
        guard venueNameMarqueeLabel.superview == nil,
              let parent = venueName.superview else { return }

        venueNameMarqueeLabel.translatesAutoresizingMaskIntoConstraints = false
        venueNameMarqueeLabel.font = venueName.font ?? Constant.Font.geistMedium(size: 22)
        venueNameMarqueeLabel.textColor = venueName.textColor ?? .white
        venueNameMarqueeLabel.animationSpeed = 25
        venueNameMarqueeLabel.animationDelay = 1.2
        venueNameMarqueeLabel.trailingSpacing = 48
        parent.addSubview(venueNameMarqueeLabel)
        venueName.isHidden = true

        NSLayoutConstraint.activate([
            venueNameMarqueeLabel.centerXAnchor.constraint(equalTo: venueName.centerXAnchor),
            venueNameMarqueeLabel.centerYAnchor.constraint(equalTo: venueName.centerYAnchor),
            venueNameMarqueeLabel.leadingAnchor.constraint(equalTo: parent.leadingAnchor, constant: 72),
            venueNameMarqueeLabel.trailingAnchor.constraint(equalTo: parent.trailingAnchor, constant: -72),
            venueNameMarqueeLabel.heightAnchor.constraint(equalToConstant: 30)
        ])
    }

    private func setVenueTitle(_ title: String?) {
        venueName.text = title
        venueNameMarqueeLabel.setText(title)
    }

    private func setupPosterBackground() {
        backgroundContainerView.addSubview(posterHeaderView)
        posterHeaderView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            posterHeaderView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            posterHeaderView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            posterHeaderView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            posterHeaderView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])

        let imageUrlString = "\(SharedURL.amazonStorage)\(venue?.venueAttachment?.first?.key ?? "")"
        posterHeaderView.loadImage(from: imageUrlString)
    }

    private func setupPagerView() {
        pagerView.delegate = self
        pagerView.dataSource = self
        pagerView.isInfinite = false
        pagerView.interitemSpacing = 0
        pagerView.transformer = FSPagerViewTransformer(type: .linear)
        pagerView.transformer?.minimumAlpha = 1
        pagerView.backgroundColor = .clear
        clipPagerOverflow()
        applyPagerHeight(currentPagerHeight, reloadPager: false)
    }

    private func setupProgressDots(count: Int) {
        progressBarView.subviews.forEach { $0.removeFromSuperview() }
        dotViews.removeAll()

        progressBarView.isHidden = count <= 1
        guard count > 1 else { return }

        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.alignment = .center
        stackView.translatesAutoresizingMaskIntoConstraints = false
        progressBarView.addSubview(stackView)

        NSLayoutConstraint.activate([
            stackView.centerXAnchor.constraint(equalTo: progressBarView.centerXAnchor),
            stackView.centerYAnchor.constraint(equalTo: progressBarView.centerYAnchor)
        ])

        for _ in 0..<count {
            let dot = UIView()
            dot.translatesAutoresizingMaskIntoConstraints = false
            dot.layer.cornerRadius = 5
            NSLayoutConstraint.activate([
                dot.widthAnchor.constraint(equalToConstant: 10),
                dot.heightAnchor.constraint(equalToConstant: 10)
            ])
            stackView.addArrangedSubview(dot)
            dotViews.append(dot)
        }

        updateProgressDots()
    }

    private func updateProgressDots(activePage: Int? = nil) {
        let page = activePage ?? currentPage
        for (index, dot) in dotViews.enumerated() {
            dot.backgroundColor = index == page
                ? .white
                : UIColor.white.withAlphaComponent(0.25)
        }
    }

    private func refreshPagerUI() {
        setupProgressDots(count: pagerItemCount)
        invalidatePagerHeights()
        pagerView.reloadData()
    }

    private func invalidatePagerHeights() {
        pagerHeightCandidates.removeAll()
        applyPagerHeight(preferredPagerHeight, reloadPager: false)
        updateScrollableContentHeight()
    }

    // MARK: - Data Loading
    private func loadInitialData() {
        if isOnlyAddOnAvailable {
            fetchAddOnsBooking(showLoader: false)
            return
        }

        if let booking, !bookingId.isEmpty {
            applyCoverBooking(booking)
        }

        guard !bookingId.isEmpty else { return }
        fetchCoverBooking(showLoader: false)
    }

    @objc private func refreshData() {
        if isOnlyAddOnAvailable {
            fetchAddOnsBooking(showLoader: false)
            return
        }
        fetchCoverBooking(showLoader: false)
    }

    private func fetchCoverBooking(showLoader: Bool) {
        paymentService.fetchBookingDetail(bookingId: bookingId) { [weak self] isSuccess, _, fetchedBooking in
            guard let self else { return }
            guard isSuccess, let fetchedBooking else { return }

            DispatchQueue.main.async {
                self.applyCoverBooking(fetchedBooking)
                self.fetchAddOnsBookingIfNeeded(showLoader: false)
            }
        }
    }

    private func applyCoverBooking(_ booking: Booking) {
        self.booking = booking
        venue = booking.venueObject ?? venue
        setVenueTitle(booking.venueObject?.name ?? venueNameText ?? "-")
        cityLbl.text = booking.venueObject?.city ?? venue?.city

        if isAddOnsAvailable || !addOnsBookingId.isEmpty || !(booking.addOnsBookingId ?? "").isEmpty {
            isAddOnsAvailable = true
            if addOnsBookingId.isEmpty {
                addOnsBookingId = booking.addOnsBookingId ?? ""
            }
        }

        qrImage = generateQRCodeImage(from: coverQRCodePayload(for: bookingId))

        let imageUrlString = "\(SharedURL.amazonStorage)\(booking.venueObject?.venueAttachment?.first?.key ?? venue?.venueAttachment?.first?.key ?? "")"
        posterHeaderView.loadImage(from: imageUrlString)

        refreshPagerUI()
    }

    private func fetchAddOnsBookingIfNeeded(showLoader: Bool) {
        let resolvedAddOnsBookingId = resolvedAddOnsBookingID()
        guard !resolvedAddOnsBookingId.isEmpty else {
            isAddOnsAvailable = false
            setupProgressDots(count: pagerItemCount)
            return
        }

        isAddOnsAvailable = true
        addOnsBookingId = resolvedAddOnsBookingId
        fetchAddOnsBooking(showLoader: showLoader)
    }

    private func fetchAddOnsBooking(showLoader: Bool) {
        let resolvedAddOnsBookingId = resolvedAddOnsBookingID()
        guard !resolvedAddOnsBookingId.isEmpty else { return }

        PaymentPresenter.getAddOnsBooking(addOnsBookingId: resolvedAddOnsBookingId) { [weak self] isSuccess, _, fetchedAddOnsBooking in
            guard let self else { return }
            guard isSuccess, let fetchedAddOnsBooking else { return }

            DispatchQueue.main.async {
                self.applyAddOnsBooking(fetchedAddOnsBooking)
            }
        }
    }

    private func applyAddOnsBooking(_ addOnsBooking: AddOnsBooking) {
        self.addOnsBooking = addOnsBooking
        addOnsBookingId = addOnsBooking.id ?? addOnsBookingId
        isAddOnsAvailable = true

        if isOnlyAddOnAvailable || booking == nil {
            setVenueTitle(addOnsBooking.venue?.name ?? venueNameText ?? "-")
            let imageUrlString = "\(SharedURL.amazonStorage)\(addOnsBooking.venue?.venueAttachment?.first?.key ?? "")"
            posterHeaderView.loadImage(from: imageUrlString)
        }

        addOnsQRImage = generateQRCodeImage(from: addOnsQRCodePayload(for: addOnsBookingId))

        if isOnlyAddOnAvailable {
            qrImage = addOnsQRImage
        }

        refreshPagerUI()
    }

    private func resolvedAddOnsBookingID() -> String {
        if !addOnsBookingId.isEmpty { return addOnsBookingId }
        return booking?.addOnsBookingId ?? ""
    }

    // MARK: - QR Code
    private func coverQRCodePayload(for bookingID: String) -> String {
        """
        {
            "id": "\(bookingID)",
            "type": "COVER"
        }
        """
    }

    private func addOnsQRCodePayload(for addOnsBookingID: String) -> String {
        """
        {
            "id": "\(addOnsBookingID)",
            "type": "COVER_ADDON"
        }
        """
    }

    private func generateQRCodeImage(from string: String) -> UIImage? {
        guard let data = string.data(using: .utf8),
              let filter = CIFilter(name: "CIQRCodeGenerator") else {
            return nil
        }

        filter.setValue(data, forKey: "inputMessage")
        filter.setValue("H", forKey: "inputCorrectionLevel")

        guard let ciImage = filter.outputImage else { return nil }

        let targetSide: CGFloat = 254
        let scaleX = targetSide / ciImage.extent.width
        let scaleY = targetSide / ciImage.extent.height
        let scaledImage = ciImage.transformed(by: CGAffineTransform(scaleX: scaleX, y: scaleY))

        let context = CIContext()
        guard let cgImage = context.createCGImage(scaledImage, from: scaledImage.extent) else {
            return nil
        }

        return UIImage(cgImage: cgImage)
    }

    // MARK: - Pager Height
    private func applyPagerHeight(for index: Int, animated: Bool) {
        applyPagerHeight(currentPagerHeight, reloadPager: false)
    }

    private func handlePagerContentHeightChange(at index: Int, height: CGFloat) {
        pagerHeightCandidates[index] = max(preferredPagerHeight, ceil(height))
        let resolvedHeight = max(
            preferredPagerHeight,
            pagerHeightCandidates.values.max() ?? preferredPagerHeight
        )

        guard abs(resolvedHeight - currentPagerHeight) > 1 else {
            updateScrollableContentHeight()
            return
        }

        applyPagerHeight(resolvedHeight, reloadPager: true)
    }

    private func applyPagerHeight(_ height: CGFloat, reloadPager: Bool) {
        currentPagerHeight = height
        pagerViewheight.constant = height
        updatePagerItemSize(height: height)
        updateScrollableContentHeight()

        if reloadPager {
            pagerView.reloadData()
        }
    }

    private func updatePagerItemSize(height: CGFloat) {
        let width = pagerView.bounds.width > 0 ? pagerView.bounds.width : 300
        let itemSize = CGSize(width: width, height: height)
        guard pagerView.itemSize != itemSize else { return }
        pagerView.itemSize = itemSize
    }

    private func updateScrollableContentHeight() {
        guard let contentView = scrollContentView else { return }

        contentView.layoutIfNeeded()
        let pagerTop = pagerView.convert(pagerView.bounds, to: contentView).minY
        let progressTopSpacing: CGFloat = 14
        let progressHeight: CGFloat = 10
        let walletTopSpacing: CGFloat = 12
        let walletHeight: CGFloat = 50
        let buyButtonTopSpacing: CGFloat = 14
        let buyButtonHeight: CGFloat = 48
        let bottomPadding: CGFloat = 20
        let requiredHeight = max(
            view.bounds.height,
            pagerTop
                + currentPagerHeight
                + progressTopSpacing
                + progressHeight
                + walletTopSpacing
                + walletHeight
                + buyButtonTopSpacing
                + buyButtonHeight
                + bottomPadding
        )

        guard abs((scrollContentHeightConstraint?.constant ?? 0) - requiredHeight) > 1 else { return }
        scrollContentHeightConstraint?.constant = requiredHeight
        view.layoutIfNeeded()
    }

    private func clipPagerOverflow() {
        pagerView.clipsToBounds = true
        pagerView.layer.masksToBounds = true
        pagerView.subviews.forEach { clipPagerScrollContainers(in: $0) }
    }

    private func clipPagerScrollContainers(in view: UIView) {
        if let scrollView = view as? UIScrollView {
            scrollView.clipsToBounds = true
            scrollView.layer.masksToBounds = true
        }
        view.subviews.forEach { clipPagerScrollContainers(in: $0) }
    }

    private func syncPagerPage(from pagerView: FSPagerView, animatedHeight: Bool) {
        let page = pagerView.currentIndex
        guard page != currentPage else {
            applyPagerHeight(for: page, animated: animatedHeight)
            return
        }
        currentPage = page
        pass = nil  // reset cached pass — different page = different booking
        updateProgressDots()
        applyPagerHeight(for: page, animated: animatedHeight)
    }

    private func venueForPagerCell(at index: Int) -> ClipVenue? {
        booking?.venueObject ?? venue
    }

    // MARK: - Apple Wallet
    private func presentAddPKPass(_ pass: PKPass) {
        guard let vc = PKAddPassesViewController(pass: pass) else { return }
        vc.delegate = self
        present(vc, animated: true)
    }

    // MARK: - Actions
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
        let uniqueId = booking?.venueObject?.uniqueId ?? addOnsBooking?.venue?.uniqueId ?? ""
        let timeZone = booking?.venueObject?.timezone ?? addOnsBooking?.venue?.timezone ?? ""
        delegate?.navigateToVenueDetail(
            venueId: booking?.venueId ?? venueId,
            venueUniqueId: uniqueId,
            venueTimeZone: timeZone
        )
        if shouldReturnToVenueAfterClose {
            returnToVenueScreen(animated: true)
        } else {
            dismiss(animated: true)
        }
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        if shouldReturnToVenueAfterClose {
            returnToVenueScreen(animated: true)
            return
        }
        returnToDiscoverScreen()
    }

    private func returnToVenueScreen(animated: Bool) {
        guard let navigationController else {
            dismiss(animated: animated)
            return
        }

        if let venueVC = navigationController.viewControllers.last(where: { $0 is VenueVC }) {
            navigationController.popToViewController(venueVC, animated: animated)
        } else if navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: animated)
        } else {
            dismiss(animated: animated)
        }
    }

    private func returnToDiscoverScreen() {
        if let navigationController,
           navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: true)
            return
        }

        let presenter = presentingViewController

        dismiss(animated: false) {
            if let navigationController = presenter as? UINavigationController {
                navigationController.tabBarController?.selectedIndex = 0
                navigationController.popToRootViewController(animated: false)
            } else if let navigationController = presenter?.navigationController {
                navigationController.tabBarController?.selectedIndex = 0
                navigationController.popToRootViewController(animated: false)
            } else if let tabBarController = presenter?.tabBarController {
                tabBarController.selectedIndex = 0
            }
        }
    }

    @IBAction func onClickAddToWalletBtn(_ sender: Any) {
        let bookingID: String
        if isOnlyAddOnAvailable {
            bookingID = addOnsBookingId
        } else if currentPage == 1 && showsAddOnsPage {
            bookingID = addOnsBookingId
        } else {
            bookingID = bookingId
        }

        guard !bookingID.isEmpty else {
            Alert.showAlertSheet(style: .alert, title: "Booking not found", message: "")
            return
        }

        let pkl = PKPassLibrary()
        if let pass = pass {
            if pkl.containsPass(pass) {
                Alert.showToast("Ticket already added to Wallet", vc: self)
            } else {
                presentAddPKPass(pass)
            }
            return
        }

        guard let url = URL(string: APIBuilder.appClipAppleWallet(bookingID)) else { return }

        addToWalletBtn.isUserInteractionEnabled = false
        addToWalletBtn.alpha = 0.65
        URLSession.shared.fetchData(at: url) { [weak self] data, error in
            guard let self else { return }
            DispatchQueue.main.async {
                self.addToWalletBtn.isUserInteractionEnabled = true
                self.addToWalletBtn.alpha = 1
            }
            guard let data else {
                DispatchQueue.main.async {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
                return
            }
            do {
                let pass = try PKPass(data: data)
                self.pass = pass
                DispatchQueue.main.async {
                    self.presentAddPKPass(pass)
                }
            } catch {
                DispatchQueue.main.async {
                    Alert.showAlertSheet(style: .alert, title: "Invalid ticket data", message: "")
                }
            }
        }
    }
}

// MARK: - FSPagerViewDelegate & FSPagerViewDataSource
extension CoverQRCodeVC: FSPagerViewDelegate, FSPagerViewDataSource {

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        pagerItemCount
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(
            withReuseIdentifier: CustomQRCodePagerViewCell.identifier,
            at: index
        ) as? CustomQRCodePagerViewCell else {
            return FSPagerViewCell()
        }

        cell.onContentHeightChange = { [weak self] height in
            self?.handlePagerContentHeightChange(at: index, height: height)
        }

        if isOnlyAddOnAvailable || (showsAddOnsPage && index == 1) {
            cell.configure(
                booking: nil,
                addOnsBooking: addOnsBooking,
                qrImage: addOnsQRImage,
                venue: venueForPagerCell(at: index)
            )
        } else {
            cell.configure(
                booking: booking,
                addOnsBooking: nil,
                qrImage: qrImage,
                venue: venueForPagerCell(at: index)
            )
        }

        return cell
    }

    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        let page = pagerView.currentIndex
        updateProgressDots(activePage: page)
    }

//    func pagerViewDidEndDecelerating(_ pagerView: FSPagerView) {
//        syncPagerPage(from: pagerView, animatedHeight: false)
//    }
//
//    func pagerViewDidEndScrollAnimation(_ pagerView: FSPagerView) {
//        syncPagerPage(from: pagerView, animatedHeight: false)
//    }
}

// MARK: - PKAddPassesViewControllerDelegate
extension CoverQRCodeVC: PKAddPassesViewControllerDelegate {
    func addPassesViewControllerDidFinish(_ controller: PKAddPassesViewController) {
        controller.dismiss(animated: true)
        let pkl = PKPassLibrary()
        if let pass = pass, pkl.containsPass(pass) {
            Alert.showToast("Ticket added to Wallet", vc: self)
        }
    }
}

extension CoverQRCodeVC: UIAdaptivePresentationControllerDelegate {
    func presentationControllerShouldDismiss(_ presentationController: UIPresentationController) -> Bool {
        false
    }
}

// MARK: - WebSocket
extension CoverQRCodeVC: WebSocketCallBackDelegate {

    func checkinBooking(booking: Booking?) {
        guard self.booking?.id == booking?.id, let booking else { return }
        self.booking = booking
        DispatchQueue.main.async {
            self.invalidatePagerHeights()
            self.pagerView.reloadData()
            self.applyPagerHeight(for: self.currentPage, animated: false)
        }
    }

    func uncheckBooking(booking: Booking?) {
        guard self.booking?.id == booking?.id, let booking else { return }
        self.booking = booking
        DispatchQueue.main.async {
            self.invalidatePagerHeights()
            self.pagerView.reloadData()
            self.applyPagerHeight(for: self.currentPage, animated: false)
        }
    }

    func checkInAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String) {
        guard addOnsBooking?.id == bookingId else { return }
        addOnsBooking?.addOnsBookingHasCheckIn = checkIndata
        DispatchQueue.main.async {
            self.invalidatePagerHeights()
            self.pagerView.reloadData()
            if self.currentPage == 1 || self.isOnlyAddOnAvailable {
                self.applyPagerHeight(for: self.currentPage, animated: false)
            }
        }
    }

    func unCheckAddOnsTicket(checkIndata: [AddOnsBookingHasCheckIn], bookingId: String) {
        guard addOnsBooking?.id == bookingId else { return }
        addOnsBooking?.addOnsBookingHasCheckIn = checkIndata
        DispatchQueue.main.async {
            self.invalidatePagerHeights()
            self.pagerView.reloadData()
            if self.currentPage == 1 || self.isOnlyAddOnAvailable {
                self.applyPagerHeight(for: self.currentPage, animated: false)
            }
        }
    }
}
