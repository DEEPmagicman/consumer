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
    @IBOutlet weak var pagerView: FSPagerView! {
        didSet {
            self.pagerView.register(
                UINib(nibName: "CustomQRCodePagerViewCell", bundle: nil),
                forCellWithReuseIdentifier: CustomQRCodePagerViewCell.identifier
            )
        }
    }
    @IBOutlet weak var addToWalletBtn: PKAddPassButton!
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

    private let paymentService = PaymentService()

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

        let attributedString = NSAttributedString(
            string: "Buy another ticket",
            attributes: [NSAttributedString.Key.underlineStyle: NSUnderlineStyle.single.rawValue]
        )
        buyAnotherTicketBtn.setAttributedTitle(attributedString, for: .normal)
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
