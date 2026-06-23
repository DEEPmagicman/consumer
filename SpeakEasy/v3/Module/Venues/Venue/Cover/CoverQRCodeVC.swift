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

    private let paymentService = PaymentService()
    private let posterHeaderView = VenuePosterHeaderView()
    private var dotViews: [UIView] = []
    private var pagerItemHeights: [Int: CGFloat] = [:]
    private var currentPage: Int = 0
    private let fallbackPagerHeight: CGFloat = 415
    private var pass: PKPass?

    private var showsAddOnsPage: Bool {
        isAddOnsAvailable && !isOnlyAddOnAvailable
    }

    private var pagerItemCount: Int {
        showsAddOnsPage ? 2 : 1
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
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
        updatePagerItemSize(height: pagerView.itemSize.height > 0 ? pagerView.itemSize.height : fallbackPagerHeight)
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        WebSocketWrapper.shared.delegate.append(self)
    }

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        WebSocketWrapper.shared.delegate.removeAll(where: { $0 as? NSObject == self })
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    // MARK: - Setup
    private func setupUI() {
        setupHeaderLabels()
        venueName.text = venueNameText?.isEmpty == false ? venueNameText : (venue?.name.isEmpty == false ? venue?.name : "-")
        cityLbl.text = venue?.city
    }

    private func setupHeaderLabels() {
        venueName.numberOfLines = 2
        venueName.lineBreakMode = .byWordWrapping
        venueName.textAlignment = .center
        venueName.adjustsFontSizeToFitWidth = true
        venueName.minimumScaleFactor = 0.75

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
        updatePagerItemSize(height: fallbackPagerHeight)
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
        pagerItemHeights.removeAll()
    }

    // MARK: - Data Loading
    private func loadInitialData() {
        if isOnlyAddOnAvailable {
            fetchAddOnsBooking(showLoader: true)
            return
        }

        if let booking, !bookingId.isEmpty {
            applyCoverBooking(booking)
        }

        guard !bookingId.isEmpty else { return }
        fetchCoverBooking(showLoader: booking == nil)
    }

    @objc private func refreshData() {
        if isOnlyAddOnAvailable {
            fetchAddOnsBooking(showLoader: true)
            return
        }
        fetchCoverBooking(showLoader: true)
    }

    private func fetchCoverBooking(showLoader: Bool) {
        if showLoader { Loader.show() }

        paymentService.fetchBookingDetail(bookingId: bookingId) { [weak self] isSuccess, _, fetchedBooking in
            if showLoader { Loader.hide() }
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
        venueName.text = booking.venueObject?.name ?? venueNameText ?? "-"
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

        if showLoader { Loader.show() }

        PaymentPresenter.getAddOnsBooking(addOnsBookingId: resolvedAddOnsBookingId) { [weak self] isSuccess, _, fetchedAddOnsBooking in
            if showLoader { Loader.hide() }
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
            venueName.text = addOnsBooking.venue?.name ?? venueNameText ?? "-"
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
        let data = string.data(using: .ascii)
        if let filter = CIFilter(name: "CIQRCodeGenerator") {
            filter.setValue(data, forKey: "inputMessage")
            let transform = CGAffineTransform(scaleX: 10, y: 10)
            if let output = filter.outputImage?.transformed(by: transform) {
                return UIImage(ciImage: output)
            }
        }
        return nil
    }

    // MARK: - Pager Height
    private func handlePagerCellHeightChange(at index: Int, height: CGFloat) {

        let totalHeight = fallbackPagerHeight

        guard pagerItemHeights[index] != totalHeight else { return }

        pagerItemHeights[index] = totalHeight

        guard currentPage == index else { return }

        pagerViewheight.constant = totalHeight
        updatePagerItemSize(height: totalHeight)

        UIView.performWithoutAnimation {
            self.view.layoutIfNeeded()
        }
    }

    private func applyPagerHeight(for index: Int, animated: Bool) {

        let height = pagerItemHeights[index] ?? fallbackPagerHeight

        pagerViewheight.constant = height
        updatePagerItemSize(height: height)
    }

    private func updatePagerItemSize(height: CGFloat) {
        let width = pagerView.bounds.width > 0 ? pagerView.bounds.width : 300
        let itemSize = CGSize(width: width, height: height)
        guard pagerView.itemSize != itemSize else { return }
        pagerView.itemSize = itemSize
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
        dismiss(animated: true)
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        returnToDiscoverScreen()
    }

    private func returnToDiscoverScreen() {
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

        Loader.show()
        URLSession.shared.fetchData(at: url) { [weak self] data, error in
            Loader.hide()
            guard let self else { return }
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

        cell.onHeightChange = { [weak self] height in
            self?.handlePagerCellHeightChange(at: index, height: height)
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
