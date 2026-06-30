//
//  CustomQRCodePagerViewCell.swift
//  SpeakEasy-Consumer
//

import UIKit
import FSPagerView

final class CustomQRCodePagerViewCell: FSPagerViewCell {

    @IBOutlet weak var cardView: UIView!
    @IBOutlet weak var blurContainerView: UIView!
    @IBOutlet weak var blurEffectView: UIVisualEffectView!
    @IBOutlet weak var containerView: UIView!
    @IBOutlet weak var qrImageView: UIImageView!
    @IBOutlet weak var ticketCodeView: UIView!
    @IBOutlet weak var backupCodeLbl: UILabel!
    @IBOutlet weak var bookingDateTimeLbl: UILabel!
    @IBOutlet weak var ticketsTableView: UITableView!
    @IBOutlet weak var upsellBadgeView: UIView!
    @IBOutlet weak var ticketTableViewHeight: NSLayoutConstraint!

    private var booking: Booking?
    private var addOnsBooking: AddOnsBooking?
    var onHeightChange: ((CGFloat) -> Void)?
    private var tableViewObserver: NSKeyValueObservation?
    private var lastTableHeight: CGFloat = 0
    private let cardCornerRadius: CGFloat = 20
    private let defaultQRCodeSize: CGFloat = 254
    private let minimumQRCodeSize: CGFloat = 190
    private let defaultTicketTableHeight: CGFloat = 40
    private let maximumTicketTableHeight: CGFloat = 104

    override func awakeFromNib() {
        super.awakeFromNib()

        applyCardMasking()

        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.register(
            QRTicketTableViewCell.nib,
            forCellReuseIdentifier: QRTicketTableViewCell.identifier
        )
        ticketsTableView.isScrollEnabled = false
        ticketsTableView.separatorStyle = .none
        ticketsTableView.backgroundColor = .clear
        ticketsTableView.rowHeight = UITableView.automaticDimension
        ticketsTableView.estimatedRowHeight = 64
        ticketsTableView.contentInset = .zero
        ticketsTableView.scrollIndicatorInsets = .zero
        ticketsTableView.showsVerticalScrollIndicator = true

        tableViewObserver = ticketsTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }

            let newHeight = ceil(tableView.contentSize.height)
            self.applyTicketTableHeight(for: newHeight)
        }

        let tap = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyCardMasking()
    }

    deinit {
        tableViewObserver?.invalidate()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onHeightChange = nil
        lastTableHeight = 0
    }

    private func applyCardMasking() {
        clipsToBounds = true
        contentView.clipsToBounds = true

        [cardView, blurContainerView, blurEffectView].forEach { view in
            view?.clipsToBounds = true
            view?.layer.cornerRadius = cardCornerRadius
            view?.layer.masksToBounds = true
        }
    }

    // MARK: - Configure
    func configure(booking: Booking?, addOnsBooking: AddOnsBooking?, qrImage: UIImage?, venue: ClipVenue?) {
        self.booking = booking
        self.addOnsBooking = addOnsBooking

        qrImageView.image = qrImage
        ticketsTableView.contentOffset = .zero

        let timeZone: String
        if let booking = booking {
            timeZone = venue?.useTimezone ?? ""
        } else if let addOnsBooking = addOnsBooking {
            timeZone = addOnsBooking.venue?.timezone?.capitalized ?? venue?.useTimezone ?? ""
        } else {
            timeZone = venue?.useTimezone ?? ""
        }

        if let booking = booking {
//            upsellBadgeView.isHidden = true
            backupCodeLbl.text = booking.venueObject?.bookingCode ?? ""
            bookingDateTimeLbl.text = "Purchased on \(booking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: timeZone))"

        } else if let addOnsBooking = addOnsBooking {
//            upsellBadgeView.isHidden = false
            backupCodeLbl.text = ""
            bookingDateTimeLbl.text = "Purchased on \(addOnsBooking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: timeZone))"
        }

        ticketsTableView.reloadData()
        ticketsTableView.layoutIfNeeded()
        applyTicketTableHeight(
            for: ceil(ticketsTableView.contentSize.height)
        )
    }

    private func applyTicketTableHeight(for contentHeight: CGFloat) {
        let rowCount = currentTicketCount()
        let cappedHeight = rowCount == 0
            ? 0
            : min(
                max(contentHeight, defaultTicketTableHeight),
                maximumTicketTableHeight
            )

        guard abs(cappedHeight - lastTableHeight) > 1 else {
            ticketsTableView.isScrollEnabled = contentHeight > cappedHeight + 1
            return
        }

        lastTableHeight = cappedHeight
        ticketTableViewHeight.constant = cappedHeight
        ticketsTableView.isScrollEnabled = contentHeight > cappedHeight + 1
        resizeQRCode(forTicketTableHeight: cappedHeight)
        onHeightChange?(cappedHeight)
    }

    private func resizeQRCode(forTicketTableHeight tableHeight: CGFloat) {
        let extraTicketHeight = max(
            0,
            tableHeight - defaultTicketTableHeight
        )

        let size = max(
            minimumQRCodeSize,
            defaultQRCodeSize - extraTicketHeight
        )

        qrImageView.constraints
            .filter {
                $0.firstAttribute == .height ||
                $0.firstAttribute == .width
            }
            .forEach { $0.constant = size }

        layoutIfNeeded()
    }

    private func currentTicketCount() -> Int {
        if let booking {
            return booking.uniqueTickets.count
        }

        if let addOnsBooking {
            return addOnsBooking.uniqueTickets.count
        }

        return 0
    }

    // MARK: - Flip
    @objc private func qrImageTapped() {
        containerView.isUserInteractionEnabled = false
        flipView()
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.flipView()
            self.containerView.isUserInteractionEnabled = true
        }
    }

    private func flipView() {
        UIView.transition(with: containerView, duration: 1, options: .transitionFlipFromRight) { [weak self] in
            guard let self = self else { return }
            self.ticketCodeView.isHidden = !self.ticketCodeView.isHidden
            self.qrImageView.isHidden = !self.qrImageView.isHidden
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension CustomQRCodePagerViewCell: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if let booking = booking {
            return booking.uniqueTickets.count
        } else if let addOnsBooking = addOnsBooking {
            return addOnsBooking.uniqueTickets.count
        }
        return 0
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: QRTicketTableViewCell.identifier,
            for: indexPath
        ) as? QRTicketTableViewCell else {
            return UITableViewCell()
        }

        cell.selectionStyle = .none

        if let booking = booking {
            guard booking.uniqueTickets.indices.contains(indexPath.row) else {
                return cell
            }

            let ticket = booking.uniqueTickets[indexPath.row]
            let quantity = ticket.selectedQuantity ?? 0
            let title = ticket.ticketCustomName?.isEmpty == false
                ? ticket.ticketCustomName
                : ticket.ticketName

            cell.configure(
                title: title,
                description: "" ,
                quantity: quantity
            )

        } else if let addOnsBooking = addOnsBooking {
            guard addOnsBooking.uniqueTickets.indices.contains(indexPath.row) else {
                return cell
            }

            let ticket = addOnsBooking.uniqueTickets[indexPath.row]
            let quantity = ticket.selectedQuantity ?? 0
            cell.configure(
                title: ticket.addOns?.name ?? "",
                description: ticket.addOns?.description ?? "",
                quantity: quantity
            )
        }

        return cell
    }
}
