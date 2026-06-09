//
//  CoverQRCodeVC.swift
//  SpeakEasy-Consumer
//

import UIKit
import FSPagerView
import PassKit

final class CoverQRCodeVC: UIViewController {

    @IBOutlet weak var venueName: UILabel!
    @IBOutlet weak var buyAnotherTicketBtn: UIButton!
    @IBOutlet weak var progressBarView: UIView!
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            self.pagerView.register(
                UINib(nibName: "CustomQRCodePagerViewCell", bundle: nil),
                forCellWithReuseIdentifier: CustomQRCodePagerViewCell.identifier
            )
        }
    }
    @IBOutlet weak var addToWalletBtn: UIButton!
//    @IBOutlet weak var bgImage: UIImageView!

    // MARK: - Data
    weak var delegate: QRCodeVCNavigationDelegate?
    var qrImage: UIImage?
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
    private var dotViews: [UIView] = []
    private var currentPage: Int = 0 {
        didSet { updateProgressDots() }
    }

    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        generateQRCode()
        fetchBookingDetails()

        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.willEnterForegroundNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(refreshData), name: UIApplication.didBecomeActiveNotification, object: nil)

        pagerView.delegate = self
        pagerView.dataSource = self
        
        pagerView.interitemSpacing = 25
        pagerView.transformer = FSPagerViewTransformer(type: .linear)
        pagerView.transformer?.minimumAlpha = 1
        pagerView.backgroundColor = .clear
        
        DispatchQueue.main.async {
            self.pagerView.itemSize = CGSize(width: 300,
                                                  height: self.pagerView.frame.height)
        }
        setupProgressDots(count: isAddOnsAvailable ? 2 : 1)
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
//        bgImage.sd_setImage(with: URL(string: (venue?.venueAttachment?.first?.key ?? "").imageURL))
        venueName.text = venue?.name.isEmpty == false ? venue?.name : "-"
    }

    private func generateQRCode() {
        let idToUse = isOnlyAddOnAvailable ? addOnsBookingId : bookingId
        let string = """
        {
            "id": "\(idToUse)",
            "type": "COVER"
        }
        """
        qrImage = generateQRCodeImage(from: string)
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

    // MARK: - API
    @objc private func refreshData() {
        fetchBookingDetails()
    }

    private func fetchBookingDetails() {
        Loader.show()
        paymentService.fetchBookingDetail(bookingId: bookingId) { [weak self] isSuccess, _, fetchedBooking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.booking = fetchedBooking
                DispatchQueue.main.async {
                    self.pagerView.reloadData()
                }
            }
        }
    }
    
    // MARK: - Progress Dots

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

    private func updateProgressDots() {
        for (index, dot) in dotViews.enumerated() {
            UIView.animate(withDuration: 0.2) {
                dot.backgroundColor = index == self.currentPage
                    ? .white
                    : UIColor.white.withAlphaComponent(0.25)
            }
        }
    }

    // MARK: - Actions
    @IBAction func onClickBuyAnotherTicket(_ sender: Any) {
        let uniqueId = booking?.venueObject?.uniqueId ?? ""
        let timeZone = booking?.venueObject?.timezone ?? ""
        delegate?.navigateToVenueDetail(
            venueId: booking?.venueId ?? "",
            venueUniqueId: uniqueId,
            venueTimeZone: timeZone
        )
        dismiss(animated: true)
    }
}

// MARK: - FSPagerViewDelegate & FSPagerViewDataSource
extension CoverQRCodeVC: FSPagerViewDelegate, FSPagerViewDataSource {

    func numberOfItems(in pagerView: FSPagerView) -> Int {
        isAddOnsAvailable ? 2 : 1
    }

    func pagerView(_ pagerView: FSPagerView, cellForItemAt index: Int) -> FSPagerViewCell {
        guard let cell = pagerView.dequeueReusableCell(
            withReuseIdentifier: CustomQRCodePagerViewCell.identifier,
            at: index
        ) as? CustomQRCodePagerViewCell else {
            return FSPagerViewCell()
        }

        if isAddOnsAvailable && index == 1 {
            let addOnsQRString = """
            {
                "id": "\(addOnsBookingId)",
                "type": "COVER_ADDON"
            }
            """
            cell.configure(
                booking: nil,
                addOnsBooking: addOnsBooking,
                qrImage: generateQRCodeImage(from: addOnsQRString),
                venue: venue
            )
        } else {
            cell.configure(
                booking: booking,
                addOnsBooking: nil,
                qrImage: qrImage,
                venue: venue
            )
        }

        return cell
    }
    
    func pagerViewDidScroll(_ pagerView: FSPagerView) {
        guard currentPage != pagerView.currentIndex else { return }
        currentPage = pagerView.currentIndex
    }
}

// MARK: - WebSocket
extension CoverQRCodeVC: WebSocketCallBackDelegate {

    func checkinBooking(booking: Booking?) {
        if self.booking?.id == booking?.id {
            self.booking = booking
            DispatchQueue.main.async {
                self.pagerView.reloadData()
            }
        }
    }

    func uncheckBooking(booking: Booking?) {
        if self.booking?.id == booking?.id {
            self.booking = booking
            DispatchQueue.main.async {
                self.pagerView.reloadData()
            }
        }
    }
}
