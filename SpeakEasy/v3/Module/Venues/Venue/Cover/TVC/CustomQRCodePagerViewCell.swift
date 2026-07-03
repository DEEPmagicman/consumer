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
    private let qrLogoContainerView = UIView()
    private let qrLogoImageView = UIImageView()
    var onContentHeightChange: ((CGFloat) -> Void)?
    private var tableViewObserver: NSKeyValueObservation?
    private var lastTableHeight: CGFloat = 0
    private let cardCornerRadius: CGFloat = 20
    private let defaultQRCodeSize: CGFloat = 254
    private let minimumTicketTableHeight: CGFloat = 64
    private let fixedVerticalPadding: CGFloat = 58

    override func awakeFromNib() {
        super.awakeFromNib()

        applyCardMasking()
        setupQRCodeLogo()
        contentView.layer.shadowColor = UIColor.clear.cgColor

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
        ticketsTableView.showsVerticalScrollIndicator = false

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
        onContentHeightChange = nil
        lastTableHeight = 0
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

        lastTableHeight = 0
        clearQRCodeBorders()
        qrImageView.image = qrImage
        qrLogoContainerView.isHidden = qrImage == nil
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

    private func clearQRCodeBorders() {
        [cardView, blurContainerView, containerView].forEach {
            $0?.layer.borderWidth = 0
            $0?.layer.borderColor = UIColor.clear.cgColor
        }
        containerView.backgroundColor = .clear
    }

    private func applyTicketTableHeight(for contentHeight: CGFloat) {
        let rowCount = currentTicketCount()
        let hasTickets = rowCount > 0
        let cappedHeight = hasTickets ? max(minimumTicketTableHeight, contentHeight) : 0
        let preferredHeight = fixedVerticalPadding + defaultQRCodeSize + cappedHeight

        guard abs(cappedHeight - lastTableHeight) > 1 else {
            ticketsTableView.isScrollEnabled = false
            applyQRCodeSize(defaultQRCodeSize)
            onContentHeightChange?(preferredHeight)
            return
        }

        lastTableHeight = cappedHeight
        ticketTableViewHeight.constant = cappedHeight
        ticketsTableView.isScrollEnabled = false
        applyQRCodeSize(defaultQRCodeSize)
        onContentHeightChange?(preferredHeight)
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
