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
    var shouldPlayPurchaseSuccessHaptic = false
    weak var buyAnotherCoverListTarget: CoverTicketListVC?

    private let paymentService = PaymentService()
    private let venueService = VenueService()
    private let posterHeaderView = VenuePosterHeaderView()
    private let backgroundBlurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let backgroundDimView = UIView()
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
    private let loadingShimmerView = CoverQRLoadingShimmerView()
    private var wasInteractivePopGestureEnabled: Bool?
    private weak var interactivePopNavigationController: UINavigationController?
    private var isInitialLoadingVisible = false
    private var isBuyAnotherNavigationInProgress = false
    private var hasPlayedPurchaseSuccessHaptic = false

    private var isAddOnsQRCodeReady: Bool {
        addOnsBooking != nil && addOnsQRImage != nil
    }

    private var showsAddOnsPage: Bool {
        isAddOnsAvailable && !isOnlyAddOnAvailable && isAddOnsQRCodeReady
    }

    private var pagerItemCount: Int {
        showsAddOnsPage ? 2 : 1
    }

    private var coverWalletBookingID: String {
        guard !isOnlyAddOnAvailable else { return "" }
        return (booking?.id ?? bookingId).trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var shouldShowWalletButton: Bool {
        false
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupScrollableLayout()
        configurePresentationDismissBehavior()
        setupUI()
        setupPosterBackground()
        setupPagerView()
        setupLoadingShimmerView()
        setInitialLoadingVisible(shouldShowInitialLoadingShimmer, animated: false)

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
        playPurchaseSuccessHapticIfNeeded()
        disableInteractiveBackNavigation()
        WebSocketWrapper.shared.addDelegate(self) 
    }

    private func playPurchaseSuccessHapticIfNeeded() {
        guard shouldPlayPurchaseSuccessHaptic,
              !hasPlayedPurchaseSuccessHaptic else { return }

        hasPlayedPurchaseSuccessHaptic = true
        AppHaptic.success()
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
        updateHeaderMetadata()
    }

    private func setupHeaderLabels() {
        setupVenueTitleMarquee()

        cityLbl.numberOfLines = 2
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

    private func updateHeaderMetadata() {
        let city = headerCityText()
        let dateTime = headerDateTimeText()
        let lines = [city, dateTime]
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }

        cityLbl.text = lines.joined(separator: "\n")
        cityLbl.isHidden = lines.isEmpty
    }

    private func headerCityText() -> String {
        let city = booking?.venueObject?.city
            ?? venue?.city
        return city?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }

    private func headerDateTimeText() -> String {
        let sourceDate: String?
        let timeZone: String?

        if isOnlyAddOnAvailable || (showsAddOnsPage && currentPage == 1) {
            sourceDate = addOnsBooking?.createdAt
            timeZone = addOnsBooking?.venue?.timezone
                ?? booking?.venueObject?.useTimezone
                ?? booking?.venueObject?.timezone
                ?? venue?.useTimezone
                ?? venue?.timezone
        } else {
            sourceDate = booking?.createdAt
            timeZone = booking?.venueObject?.useTimezone
                ?? booking?.venueObject?.timezone
                ?? venue?.useTimezone
                ?? venue?.timezone
        }

        guard let sourceDate, !sourceDate.isEmpty else {
            return fallbackHeaderDateTimeText(timeZone: timeZone)
        }

        return sourceDate.convertDateFormat(
            from: .yyyyMMddTHHmmssSSSz,
            to: .EEEMMMDATHMMA,
            isUTC: true,
            customTimeZone: timeZone ?? ""
        )
    }

    private func fallbackHeaderDateTimeText(timeZone: String?) -> String {
        guard shouldReturnToVenueAfterClose, !bookingId.isEmpty else { return "" }

        let formatter = DateFormatter()
        formatter.dateFormat = DateFormat.EEEMMMDATHMMA.rawValue
        if let timeZone,
           !timeZone.isEmpty,
           let venueTimeZone = TimeZone(identifier: timeZone) {
            formatter.timeZone = venueTimeZone
        }
        return formatter.string(from: Date())
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

        setupBackgroundReadabilityLayer()

        let imageUrlString = "\(SharedURL.amazonStorage)\(venue?.venueAttachment?.first?.key ?? "")"
        posterHeaderView.loadImage(from: imageUrlString)
    }

    private func setupBackgroundReadabilityLayer() {
        guard backgroundBlurView.superview == nil else { return }

        backgroundBlurView.alpha = 0.18
        backgroundBlurView.isUserInteractionEnabled = false
        backgroundBlurView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainerView.addSubview(backgroundBlurView)

        backgroundDimView.backgroundColor = UIColor.black.withAlphaComponent(0.10)
        backgroundDimView.isUserInteractionEnabled = false
        backgroundDimView.translatesAutoresizingMaskIntoConstraints = false
        backgroundContainerView.addSubview(backgroundDimView)

        NSLayoutConstraint.activate([
            backgroundBlurView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            backgroundBlurView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            backgroundBlurView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            backgroundBlurView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor),

            backgroundDimView.topAnchor.constraint(equalTo: backgroundContainerView.topAnchor),
            backgroundDimView.leadingAnchor.constraint(equalTo: backgroundContainerView.leadingAnchor),
            backgroundDimView.trailingAnchor.constraint(equalTo: backgroundContainerView.trailingAnchor),
            backgroundDimView.bottomAnchor.constraint(equalTo: backgroundContainerView.bottomAnchor)
        ])
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

    private func setupLoadingShimmerView() {
        loadingShimmerView.translatesAutoresizingMaskIntoConstraints = false
        loadingShimmerView.isHidden = true
        view.addSubview(loadingShimmerView)

        NSLayoutConstraint.activate([
            loadingShimmerView.topAnchor.constraint(equalTo: view.topAnchor),
            loadingShimmerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            loadingShimmerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            loadingShimmerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
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
    private var shouldShowInitialLoadingShimmer: Bool {
        isOnlyAddOnAvailable || booking == nil
    }

    private func setInitialLoadingVisible(_ isVisible: Bool, animated: Bool = true) {
        let didChangeVisibility = isInitialLoadingVisible != isVisible
        isInitialLoadingVisible = isVisible

        pagerView.isHidden = isVisible
        progressBarView.isHidden = isVisible || pagerItemCount <= 1
        addToWalletBtn.isHidden = isVisible || !shouldShowWalletButton
        buyAnotherTicketBtn.isHidden = isVisible

        guard didChangeVisibility else {
            updateScrollableContentHeight()
            return
        }

        if isVisible {
            loadingShimmerView.show(animated: animated)
            view.bringSubviewToFront(loadingShimmerView)
        } else {
            loadingShimmerView.hide(animated: animated)
        }
    }

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
        updateHeaderMetadata()

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
        setInitialLoadingVisible(false)
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

        paymentService.fetchAddOnsBooking(addOnsBookingId: resolvedAddOnsBookingId) { [weak self] isSuccess, _, fetchedAddOnsBooking in
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
            updateHeaderMetadata()
            let imageUrlString = "\(SharedURL.amazonStorage)\(addOnsBooking.venue?.venueAttachment?.first?.key ?? "")"
            posterHeaderView.loadImage(from: imageUrlString)
        }

        addOnsQRImage = generateQRCodeImage(from: addOnsQRCodePayload(for: addOnsBookingId))

        if isOnlyAddOnAvailable {
            qrImage = addOnsQRImage
        }

        refreshPagerUI()
        setInitialLoadingVisible(false)
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

        updateHeaderMetadata()
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
        let walletTopSpacing: CGFloat = addToWalletBtn.isHidden ? 0 : 12
        let walletHeight: CGFloat = addToWalletBtn.isHidden ? 0 : 50
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
        if let bookingVenue = booking?.venueObject {
            return bookingVenue
        }
        return venue
    }

    // MARK: - Apple Wallet
    private func presentAddPKPass(_ pass: PKPass) {
        guard let vc = PKAddPassesViewController(pass: pass) else { return }
        vc.delegate = self
        present(vc, animated: true)
    }

    // MARK: - Actions
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
        AppHaptic.primaryAction()

        openBuyAnotherTicketFlow()
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        AppHaptic.navigation()
        if shouldReturnToVenueAfterClose {
            returnToVenueScreen(animated: true)
            return
        }
        returnToDiscoverScreen()
    }

    private func returnToVenueScreen(animated: Bool) {
        guard let navigationController else {
            let presenter = presentingViewController
            dismiss(animated: animated) {
                if let presentingNavigationController = presenter as? UINavigationController {
                    self.popPresenterToVenue(in: presentingNavigationController, animated: false)
                } else if let presentingNavigationController = presenter?.navigationController {
                    self.popPresenterToVenue(in: presentingNavigationController, animated: false)
                }
            }
            return
        }

        popPresenterToVenue(in: navigationController, animated: animated)
    }

    private func popPresenterToVenue(in navigationController: UINavigationController, animated: Bool) {
        if let venueVC = navigationController.viewControllers.last(where: { $0 is VenueVC }) {
            navigationController.popToViewController(venueVC, animated: animated)
        } else if let coverListVC = navigationController.viewControllers.last(where: { $0 is CoverTicketListVC }) as? CoverTicketListVC {
            coverListVC.resetForFreshPurchase()
            navigationController.popToViewController(coverListVC, animated: animated)
        } else if navigationController.viewControllers.count > 1 {
            navigationController.popViewController(animated: animated)
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
        let bookingID = coverWalletBookingID

        guard !bookingID.isEmpty else {
            AppHaptic.error()
            Alert.showAlertSheet(style: .alert, title: "Booking not found", message: "")
            return
        }

        AppHaptic.primaryAction()
        let pkl = PKPassLibrary()
        if let pass = pass {
            if pkl.containsPass(pass) {
                AppHaptic.warning()
                Alert.showToast("Ticket already added to Wallet", vc: self)
            } else {
                presentAddPKPass(pass)
            }
            return
        }

        guard let url = URL(string: APIBuilder.coverAppleWallet(bookingID)) else { return }

        addToWalletBtn.isUserInteractionEnabled = false
        addToWalletBtn.alpha = 0.65
        URLSession.shared.fetchData(at: url) { [weak self] data, _ in
            guard let self else { return }
            DispatchQueue.main.async {
                self.addToWalletBtn.isUserInteractionEnabled = true
                self.addToWalletBtn.alpha = 1
            }
            guard let data else {
                DispatchQueue.main.async {
                    AppHaptic.error()
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
                    AppHaptic.error()
                    Alert.showAlertSheet(style: .alert, title: "Invalid ticket data", message: "")
                }
            }
        }
    }
}

private extension CoverQRCodeVC {

    struct VenueNavigationContext {
        let venueId: String
        let uniqueId: String
        let timeZone: String
    }

    func currentVenueNavigationContext() -> VenueNavigationContext {
        let currentVenueId = booking?.venueId
            ?? booking?.venueObject?.id
            ?? addOnsBooking?.venue?.id
            ?? venue?.id
            ?? venueId
        let uniqueId = booking?.venueObject?.uniqueId
            ?? booking?.uniqueId
            ?? addOnsBooking?.venue?.uniqueId
            ?? venue?.uniqueId
            ?? ""
        let timeZone = booking?.venueObject?.timezone
            ?? addOnsBooking?.venue?.timezone
            ?? venue?.timezone
            ?? ""

        return VenueNavigationContext(
            venueId: currentVenueId,
            uniqueId: uniqueId,
            timeZone: timeZone
        )
    }

    func openBuyAnotherTicketFlow() {
        guard !isBuyAnotherNavigationInProgress else { return }

        let presenter = presentingViewController
        let navigationController = resolvedNavigationController(using: presenter)

        if let coverListVC = buyAnotherCoverListTarget ?? existingCoverTicketList(using: presenter) {
            returnToCoverTicketList(coverListVC)
            return
        }

        if shouldReturnToVenueAfterClose {
            openFreshTicketsFromVenueFlow(using: presenter, navigationController: navigationController)
        } else {
            openVenueFromOrderFlow(using: presenter)
        }
    }

    func openFreshTicketsFromVenueFlow(
        using presenter: UIViewController?,
        navigationController: UINavigationController?
    ) {
        if let venueVC = navigationController?.viewControllers.last(where: { $0 is VenueVC }) as? VenueVC {
            performAfterClosingQRCode(using: presenter, animated: false) { navigationController in
                navigationController.popToViewController(venueVC, animated: false)
            }
            return
        }

        dismissQRCodeOnly(animated: false)
    }

    func returnToCoverTicketList(_ coverListVC: CoverTicketListVC) {
        coverListVC.resetForFreshPurchase()

        let complete: () -> Void = { [weak coverListVC] in
            guard let coverListVC,
                  let coverNavigationController = coverListVC.navigationController else { return }

            if coverNavigationController.topViewController !== coverListVC {
                coverNavigationController.popToViewController(coverListVC, animated: false)
            }
        }

        if presentingViewController != nil {
            dismiss(animated: false, completion: complete)
        } else {
            complete()
        }
    }

    func openVenueFromOrderFlow(using presenter: UIViewController?) {
        let context = currentVenueNavigationContext()
        let venueDetails = preferredVenueDetailsForNavigation()

        performAfterClosingQRCode(using: presenter) { navigationController in
            let venueVC = VenueVC(nibName: "VenueVC", bundle: nil)
            venueVC.venueDetails = venueDetails
            venueVC.uniqueId = context.uniqueId
            venueVC.hidesBottomBarWhenPushed = true
            navigationController.pushViewController(venueVC, animated: true)
        }
    }

    func fetchAndOpenCoverTicketList(using presenter: UIViewController?) {
        setBuyAnotherNavigationLoading(true)

        fetchFreshVenueDetailsForBuyAnother { [weak self] venueDetail in
            guard let self else { return }

            DispatchQueue.main.async {
                guard let venueDetail else {
                    self.setBuyAnotherNavigationLoading(false)
                    Alert.showAlertSheet(
                        style: .alert,
                        title: "Unable to load tickets",
                        message: "Please try again."
                    )
                    return
                }

                let shouldShowDirectUpsell = self.shouldOpenDirectUpsell(for: venueDetail)

                self.performAfterClosingQRCode(using: presenter) { navigationController in
                    guard let sender = navigationController.topViewController else { return }
                    Navigate.to.coverTicketListVC(
                        sender,
                        venueDetails: venueDetail,
                        shouldShowDirectUpsell: shouldShowDirectUpsell
                    )
                }
            }
        }
    }

    func fetchFreshVenueDetailsForBuyAnother(completion: @escaping (ClipVenue?) -> Void) {
        let context = currentVenueNavigationContext()
        let venueTimeZone = context.timeZone.isEmpty ? TimeZone.current.identifier : context.timeZone

        if !context.uniqueId.isEmpty {
            venueService.fetchCoverVenueDetail(
                uniqueId: context.uniqueId,
                venueTimeZone: venueTimeZone
            ) { isSuccess, _, venueDetail in
                completion(isSuccess ? venueDetail : nil)
            }
            return
        }

        guard !context.venueId.isEmpty else {
            completion(preferredVenueDetailsForNavigation())
            return
        }

        venueService.fetchVenueDetail(
            venueId: context.venueId,
            venueTimeZone: venueTimeZone
        ) { isSuccess, _, venueDetail in
            completion(isSuccess ? venueDetail : nil)
        }
    }

    func resolvedNavigationController(using presenter: UIViewController?) -> UINavigationController? {
        presenter as? UINavigationController
            ?? presenter?.navigationController
            ?? presenter?.presentingViewController as? UINavigationController
            ?? presenter?.presentingViewController?.navigationController
            ?? navigationController
    }

    func existingCoverTicketList(using presenter: UIViewController?) -> CoverTicketListVC? {
        navigationCandidates(using: presenter).compactMap {
            $0.viewControllers.last(where: { $0 is CoverTicketListVC }) as? CoverTicketListVC
        }.last
    }

    func navigationCandidates(using presenter: UIViewController?) -> [UINavigationController] {
        [
            navigationController,
            presenter as? UINavigationController,
            presenter?.navigationController,
            presenter?.presentingViewController as? UINavigationController,
            presenter?.presentingViewController?.navigationController
        ].compactMap { $0 }
    }

    func performAfterClosingQRCode(
        using presenter: UIViewController?,
        animated: Bool = true,
        completion: @escaping (UINavigationController) -> Void
    ) {
        let wasPresented = presentingViewController != nil
        let navigationController = resolvedNavigationController(using: presenter)

        let complete: () -> Void = { [weak self, weak navigationController] in
            guard let navigationController else { return }

            self?.setBuyAnotherNavigationLoading(false)
            completion(navigationController)
        }

        if wasPresented {
            dismiss(animated: animated, completion: complete)
        } else {
            complete()
        }
    }

    func dismissQRCodeOnly(animated: Bool) {
        if presentingViewController != nil {
            dismiss(animated: animated)
        } else {
            navigationController?.popViewController(animated: animated)
        }
    }

    func preferredVenueDetailsForNavigation() -> ClipVenue? {
        if let bookingVenue = booking?.venueObject {
            return bookingVenue
        }
        return venue
    }

    func shouldOpenDirectUpsell(for venueDetail: ClipVenue) -> Bool {
        let hasCoverTickets = venueDetail.coverTicket?.contains {
            !($0.isDeleted ?? false) &&
            $0.status == "ENABLED"
        } ?? false

        return !hasCoverTickets && isOnlyAddOnAvailable
    }

    func setBuyAnotherNavigationLoading(_ isLoading: Bool) {
        isBuyAnotherNavigationInProgress = isLoading
        buyAnotherTicketBtn.isEnabled = !isLoading
        setInitialLoadingVisible(isLoading, animated: true)
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
        if page != currentPage {
            currentPage = page
            AppHaptic.selectionChanged()
            updateHeaderMetadata()
        }
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
            AppHaptic.success()
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

private final class CoverQRLoadingShimmerView: UIView {
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let titleLine = ShimmerViewV3()
    private let subtitleLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let cardView = UIView()
    private let qrSquare = ShimmerViewV3()
    private let helperLine = ShimmerViewV3(frame: .zero, lighter: true)
    private let ticketLineOne = ShimmerViewV3()
    private let ticketMetaOne = ShimmerViewV3(frame: .zero, lighter: true)
    private let ticketLineTwo = ShimmerViewV3()
    private let ticketMetaTwo = ShimmerViewV3(frame: .zero, lighter: true)
    private let walletLine = ShimmerViewV3()
    private let actionLine = ShimmerViewV3(frame: .zero, lighter: true)

    private var shimmerViews: [ShimmerViewV3] {
        [
            titleLine,
            subtitleLine,
            qrSquare,
            helperLine,
            ticketLineOne,
            ticketMetaOne,
            ticketLineTwo,
            ticketMetaTwo,
            walletLine,
            actionLine
        ]
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    func show(animated: Bool) {
        isHidden = false
        shimmerViews.forEach { $0.startShimmer() }

        guard animated else {
            alpha = 1
            return
        }

        alpha = 0
        UIView.animate(withDuration: 0.18) {
            self.alpha = 1
        }
    }

    func hide(animated: Bool) {
        let completion: (Bool) -> Void = { _ in
            self.shimmerViews.forEach { $0.stopShimmer() }
            self.isHidden = true
            self.alpha = 1
        }

        guard animated else {
            completion(true)
            return
        }

        UIView.animate(
            withDuration: 0.22,
            animations: {
                self.alpha = 0
            },
            completion: completion
        )
    }

    private func setupUI() {
        isHidden = true
        alpha = 0
        backgroundColor = UIColor.black.withAlphaComponent(0.72)
        isUserInteractionEnabled = true

        blurView.translatesAutoresizingMaskIntoConstraints = false
        addSubview(blurView)

        cardView.translatesAutoresizingMaskIntoConstraints = false
        cardView.backgroundColor = UIColor.white.withAlphaComponent(0.075)
        cardView.layer.cornerRadius = 22
        cardView.layer.borderWidth = 1
        cardView.layer.borderColor = UIColor.white.withAlphaComponent(0.08).cgColor
        cardView.clipsToBounds = true
        addSubview(cardView)

        [titleLine, subtitleLine, walletLine, actionLine].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 8
            addSubview($0)
        }

        [
            qrSquare,
            helperLine,
            ticketLineOne,
            ticketMetaOne,
            ticketLineTwo,
            ticketMetaTwo
        ].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            $0.layer.cornerRadius = 8
            cardView.addSubview($0)
        }

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),

            titleLine.topAnchor.constraint(equalTo: safeAreaLayoutGuide.topAnchor, constant: 44),
            titleLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.58),
            titleLine.heightAnchor.constraint(equalToConstant: 22),

            subtitleLine.topAnchor.constraint(equalTo: titleLine.bottomAnchor, constant: 12),
            subtitleLine.centerXAnchor.constraint(equalTo: centerXAnchor),
            subtitleLine.widthAnchor.constraint(equalTo: widthAnchor, multiplier: 0.36),
            subtitleLine.heightAnchor.constraint(equalToConstant: 14),

            cardView.topAnchor.constraint(equalTo: subtitleLine.bottomAnchor, constant: 34),
            cardView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 18),
            cardView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -18),
            cardView.heightAnchor.constraint(equalToConstant: 430),

            qrSquare.topAnchor.constraint(equalTo: cardView.topAnchor, constant: 26),
            qrSquare.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            qrSquare.widthAnchor.constraint(equalToConstant: 230),
            qrSquare.heightAnchor.constraint(equalTo: qrSquare.widthAnchor),

            helperLine.topAnchor.constraint(equalTo: qrSquare.bottomAnchor, constant: 20),
            helperLine.centerXAnchor.constraint(equalTo: cardView.centerXAnchor),
            helperLine.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.50),
            helperLine.heightAnchor.constraint(equalToConstant: 14),

            ticketLineOne.topAnchor.constraint(equalTo: helperLine.bottomAnchor, constant: 28),
            ticketLineOne.leadingAnchor.constraint(equalTo: cardView.leadingAnchor, constant: 26),
            ticketLineOne.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.48),
            ticketLineOne.heightAnchor.constraint(equalToConstant: 16),

            ticketMetaOne.centerYAnchor.constraint(equalTo: ticketLineOne.centerYAnchor),
            ticketMetaOne.trailingAnchor.constraint(equalTo: cardView.trailingAnchor, constant: -26),
            ticketMetaOne.widthAnchor.constraint(equalToConstant: 42),
            ticketMetaOne.heightAnchor.constraint(equalToConstant: 16),

            ticketLineTwo.topAnchor.constraint(equalTo: ticketLineOne.bottomAnchor, constant: 26),
            ticketLineTwo.leadingAnchor.constraint(equalTo: ticketLineOne.leadingAnchor),
            ticketLineTwo.widthAnchor.constraint(equalTo: cardView.widthAnchor, multiplier: 0.38),
            ticketLineTwo.heightAnchor.constraint(equalToConstant: 16),

            ticketMetaTwo.centerYAnchor.constraint(equalTo: ticketLineTwo.centerYAnchor),
            ticketMetaTwo.trailingAnchor.constraint(equalTo: ticketMetaOne.trailingAnchor),
            ticketMetaTwo.widthAnchor.constraint(equalToConstant: 34),
            ticketMetaTwo.heightAnchor.constraint(equalToConstant: 16),

            walletLine.topAnchor.constraint(equalTo: cardView.bottomAnchor, constant: 22),
            walletLine.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 28),
            walletLine.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -28),
            walletLine.heightAnchor.constraint(equalToConstant: 50),

            actionLine.topAnchor.constraint(equalTo: walletLine.bottomAnchor, constant: 14),
            actionLine.leadingAnchor.constraint(equalTo: walletLine.leadingAnchor),
            actionLine.trailingAnchor.constraint(equalTo: walletLine.trailingAnchor),
            actionLine.heightAnchor.constraint(equalToConstant: 48)
        ])
    }
}
