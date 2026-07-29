//
//  CustomQRCodePagerViewCell.swift
//  SpeakEasy-Consumer
//

import UIKit
import FSPagerView

final class CustomQRCodePagerViewCell: FSPagerViewCell {

    private enum Layout {
        static let qrCodeSize: CGFloat = 230
        static let qrContainerSize: CGFloat = 270
        static let ticketRowHeight: CGFloat = 64
        static let visibleTicketRows = 3
        static let cardTopPadding: CGFloat = 18
        static let qrTicketSpacing: CGFloat = 6
        static let ticketBottomPadding: CGFloat = 14
        static let cardBottomPadding: CGFloat = 20

        static func visibleRows(for ticketCount: Int) -> Int {
            min(max(ticketCount, 1), visibleTicketRows)
        }

        static func ticketTableHeight(for ticketCount: Int) -> CGFloat {
            CGFloat(visibleRows(for: ticketCount)) * ticketRowHeight
        }

        static func cardHeight(for ticketCount: Int) -> CGFloat {
            cardTopPadding
                + qrContainerSize
                + qrTicketSpacing
                + ticketTableHeight(for: ticketCount)
                + ticketBottomPadding
                + cardBottomPadding
        }
    }

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
    @IBOutlet weak var backgroundColorView: UIView!
    
    private var booking: Booking?
    private var addOnsBooking: AddOnsBooking?
    private let qrLogoContainerView = UIView()
    private let qrLogoImageView = UIImageView()
    var onContentHeightChange: ((CGFloat) -> Void)?
    private let cardCornerRadius: CGFloat = 20
    private var cardHeightConstraint: NSLayoutConstraint?

    override func awakeFromNib() {
        super.awakeFromNib()

        setupCardHeightConstraint()
        applyCardMasking()
        setupQRCodeLogo()
        contentView.layer.shadowColor = UIColor.clear.cgColor

        ticketsTableView.delegate = self
        ticketsTableView.dataSource = self
        ticketsTableView.register(
            QRTicketTableViewCell.nib,
            forCellReuseIdentifier: QRTicketTableViewCell.identifier
        )
        ticketsTableView.isScrollEnabled = true
        ticketsTableView.separatorStyle = .none
        ticketsTableView.backgroundColor = .clear
        ticketsTableView.rowHeight = Layout.ticketRowHeight
        ticketsTableView.estimatedRowHeight = Layout.ticketRowHeight
        ticketsTableView.contentInset = .zero
        ticketsTableView.scrollIndicatorInsets = .zero
        ticketsTableView.showsVerticalScrollIndicator = false
        ticketsTableView.bounces = false
        ticketsTableView.alwaysBounceVertical = false
        applyTicketSizing(for: 1)
        applyQRCodeSize(Layout.qrCodeSize)

        let tap = UITapGestureRecognizer(target: self, action: #selector(qrImageTapped))
        containerView.addGestureRecognizer(tap)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        applyCardMasking()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onContentHeightChange = nil
        ticketCodeView.isHidden = true
        qrImageView.isHidden = false
        qrLogoContainerView.isHidden = false
        ticketsTableView.contentOffset = .zero
    }

    private func applyCardMasking() {
        clipsToBounds = true
        contentView.clipsToBounds = true

        [cardView, blurContainerView, blurEffectView].forEach { view in
            view?.clipsToBounds = true
            view?.layer.cornerRadius = cardCornerRadius
            view?.layer.masksToBounds = true
        }

        containerView.clipsToBounds = true
        containerView.layer.cornerRadius = 10
        containerView.layer.masksToBounds = true
    }

    private func setupCardHeightConstraint() {
        contentView.constraints
            .filter {
                ($0.firstItem as? UIView) == contentView &&
                $0.firstAttribute == .bottom &&
                ($0.secondItem as? UIView) == cardView &&
                $0.secondAttribute == .bottom
            }
            .forEach { $0.isActive = false }

        cardHeightConstraint = cardView.heightAnchor.constraint(
            equalToConstant: Layout.cardHeight(for: 1)
        )
        cardHeightConstraint?.isActive = true
    }

    private func setupQRCodeLogo() {
        guard qrLogoContainerView.superview == nil else { return }

        qrImageView.layer.magnificationFilter = .nearest
        qrImageView.layer.minificationFilter = .nearest

        qrLogoContainerView.translatesAutoresizingMaskIntoConstraints = false
        qrLogoContainerView.backgroundColor = .white
        qrLogoContainerView.layer.cornerRadius = 22
        qrLogoContainerView.layer.borderWidth = 1
        qrLogoContainerView.layer.borderColor = UIColor.black.withAlphaComponent(0.12).cgColor
        qrLogoContainerView.clipsToBounds = true
        containerView.addSubview(qrLogoContainerView)

        qrLogoImageView.translatesAutoresizingMaskIntoConstraints = false
        qrLogoImageView.contentMode = .scaleAspectFit
        qrLogoImageView.image = UIImage(named: "qrLogo") ?? UIImage(named: "newSpeakeasy") ?? UIImage(named: "appLogo")
        qrLogoContainerView.addSubview(qrLogoImageView)

        NSLayoutConstraint.activate([
            qrLogoContainerView.centerXAnchor.constraint(equalTo: qrImageView.centerXAnchor),
            qrLogoContainerView.centerYAnchor.constraint(equalTo: qrImageView.centerYAnchor),
            qrLogoContainerView.widthAnchor.constraint(equalToConstant: 44),
            qrLogoContainerView.heightAnchor.constraint(equalTo: qrLogoContainerView.widthAnchor),

            qrLogoImageView.topAnchor.constraint(equalTo: qrLogoContainerView.topAnchor, constant: 8),
            qrLogoImageView.leadingAnchor.constraint(equalTo: qrLogoContainerView.leadingAnchor, constant: 8),
            qrLogoImageView.trailingAnchor.constraint(equalTo: qrLogoContainerView.trailingAnchor, constant: -8),
            qrLogoImageView.bottomAnchor.constraint(equalTo: qrLogoContainerView.bottomAnchor, constant: -8)
        ])
    }

    // MARK: - Configure
    func configure(booking: Booking?, addOnsBooking: AddOnsBooking?, qrImage: UIImage?, venue: ClipVenue?) {
        self.booking = booking
        self.addOnsBooking = addOnsBooking

        clearQRCodeBorders()
        applyQRCodeBackgroundColor(venue: venue)
        qrImageView.image = qrImage
        qrLogoContainerView.isHidden = qrImage == nil
        ticketsTableView.contentOffset = .zero
        applyTicketSizing(for: currentTicketCount())

        let timeZone: String
        if booking != nil {
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
            backupCodeLbl.text = addOnsBooking.venue?.bookingCode ?? venue?.bookingCode ?? ""
            bookingDateTimeLbl.text = "Purchased on \(addOnsBooking.createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .HMMAMMMDD, isUTC: true, customTimeZone: timeZone))"
        }

        ticketsTableView.reloadData()
    }

    private func applyQRCodeBackgroundColor(venue: ClipVenue?) {
        let venueSettings = booking?.venueObject?.venueSettings ?? venue?.venueSettings
        let isCompedTicket = booking?.isCompedTicket == true

        backgroundColorView.backgroundColor = TicketQRCodeColorResolver.color(
            venueSettings: venueSettings,
            ticketType: .cover,
            isFreeTicket: isFreeCoverBooking(),
            preferredColor: isCompedTicket ? venueSettings?.compedTicketQrCodeBorderColor : nil,
            fallbackColor: nil
        ) ?? .clear
    }

    private func isFreeCoverBooking() -> Bool {
        guard let booking else { return false }
        let tickets = booking.bookingHasItem
        guard !tickets.isEmpty else { return false }
        return tickets.allSatisfy { $0.ticketPrice <= 0 }
    }

    private func clearQRCodeBorders() {
        [cardView, blurContainerView, containerView].forEach {
            $0?.layer.borderWidth = 0
            $0?.layer.borderColor = UIColor.clear.cgColor
        }
        containerView.backgroundColor = .clear
    }

    private func applyTicketSizing(for ticketCount: Int) {
        ticketTableViewHeight.constant = Layout.ticketTableHeight(for: ticketCount)
        let cardHeight = Layout.cardHeight(for: ticketCount)
        cardHeightConstraint?.constant = cardHeight
        ticketsTableView.isScrollEnabled = ticketCount > Layout.visibleTicketRows
        onContentHeightChange?(cardHeight)
    }

    private func applyQRCodeSize(_ size: CGFloat) {
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
            self.qrLogoContainerView.isHidden = self.qrImageView.isHidden
        }
    }
}

// MARK: - UITableViewDelegate & UITableViewDataSource
extension CustomQRCodePagerViewCell: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Layout.ticketRowHeight
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        currentTicketCount()
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
                description: descriptionForCoverTicket(ticket),
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

    private func descriptionForCoverTicket(_ ticket: BookingHasItem) -> String {
        booking?.ticketDetails?
            .first {
                $0.ticketId == ticket.ticketId ||
                $0.ticketName == ticket.ticketName ||
                $0.ticketName == ticket.ticketCustomName
            }?
            .ticketDescription ?? ""
    }
}
