//
//  GroupTicketTVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 13/03/26.
//

import UIKit

class GroupTicketTVC: UITableViewCell {

    @IBOutlet weak var ticketListTableView: UITableView!
    @IBOutlet weak var groupTitle: UILabel!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var expandBnt: UIButton!
    @IBOutlet weak var tableParentView: UIView!
    @IBOutlet weak var containerBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var viewTopConstraint: NSLayoutConstraint!
    
    var tickets: [EventTicket] = []
    var currency: String = "$"
    var currencyPosition: String? = ""
    var whiteLabelColor: String?
    var eventTicketSetting: EventTicketSettings?
    var expandedTicketDescriptions: Set<String> = []
    var disabledTicketIds: Set<String> = []

    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket) -> Void)?
    var onRowTap: ((EventTicket) -> Void)?
    var onDescriptionToggle: ((EventTicket) -> Void)?
    var onExpandChanged: ((Bool) -> Void)?
    var onHeightChanged: (() -> Void)?

    private var isExpanded = false
    private var ticketTableObserver: NSKeyValueObservation?

    override func awakeFromNib() {
        super.awakeFromNib()

        ticketListTableView.delegate = self
        ticketListTableView.dataSource = self
        ticketListTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        ticketListTableView.isScrollEnabled = false
        ticketListTableView.contentInset = .zero
        ticketListTableView.scrollIndicatorInsets = .zero
        ticketListTableView.sectionHeaderHeight = .leastNonzeroMagnitude
        ticketListTableView.sectionFooterHeight = .leastNonzeroMagnitude

        if #available(iOS 15.0, *) {
            ticketListTableView.sectionHeaderTopPadding = 0
        }

        startTicketTableObserver()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        releaseResourcesForReuse()
    }

    deinit {
        ticketTableObserver?.invalidate()
        ticketListTableView.delegate = nil
        ticketListTableView.dataSource = nil
        releaseResourcesForReuse()
    }

    private func releaseResourcesForReuse() {
        onPlusTap = nil
        onMinusTap = nil
        onRSVPTap = nil
        onRowTap = nil
        onDescriptionToggle = nil
        onExpandChanged = nil
        onHeightChanged = nil
        tickets.removeAll()
        expandedTicketDescriptions.removeAll()
        disabledTicketIds.removeAll()
    }

    private func startTicketTableObserver() {
        ticketTableObserver?.invalidate()

        ticketTableObserver = ticketListTableView.observe(\.contentSize, options: [.new]) { [weak self] tableView, _ in
            guard let self = self else { return }
            self.tableViewHeight.constant = self.isExpanded ? tableView.contentSize.height : 0
            self.onHeightChanged?()
        }
    }

    func configure(
        groupName: String,
        tickets: [EventTicket],
        currency: String,
        currencyPosition: String?,
        whiteLabelColor: String?,
        eventTicketSetting: EventTicketSettings?,
        expandedTicketDescriptions: Set<String>,
        disabledTicketIds: Set<String>,
        isExpanded: Bool = false,
        topSpacing: CGFloat = 10,
        bottomSpacing: CGFloat = 0
    ) {
        self.groupTitle.text = groupName
        self.tickets = tickets
        self.currency = currency
        self.currencyPosition = currencyPosition
        self.whiteLabelColor = whiteLabelColor
        self.eventTicketSetting = eventTicketSetting
        self.expandedTicketDescriptions = expandedTicketDescriptions
        self.disabledTicketIds = disabledTicketIds
        self.isExpanded = isExpanded
        
        viewTopConstraint.constant = topSpacing
        containerBottomConstraint.constant = bottomSpacing
        tableParentView.isHidden = !isExpanded
        expandBnt.transform = isExpanded
            ? CGAffineTransform(rotationAngle: .pi)
            : .identity
        ticketListTableView.reloadData()
        ticketListTableView.layoutIfNeeded()
        tableViewHeight.constant = isExpanded ? ticketListTableView.contentSize.height : 0
    }

    func updateTickets(
        _ tickets: [EventTicket],
        reloadingTicketAt ticketIndex: Int?
    ) {
        self.tickets = tickets

        guard isExpanded else {
            tableViewHeight.constant = 0
            return
        }

        let reloadData = {
            self.ticketListTableView.reloadData()
        }

        if let ticketIndex,
           tickets.indices.contains(ticketIndex),
           ticketListTableView.numberOfRows(inSection: 0) > ticketIndex {
            UIView.performWithoutAnimation {
                ticketListTableView.reloadRows(
                    at: [IndexPath(row: ticketIndex, section: 0)],
                    with: .none
                )
            }
        } else {
            UIView.performWithoutAnimation(reloadData)
        }

        ticketListTableView.layoutIfNeeded()
        tableViewHeight.constant = ticketListTableView.contentSize.height
    }

    @IBAction func onClickExpandBtn(_ sender: Any) {
        AppHaptic.selectionChanged()
        isExpanded.toggle()
        tableParentView.isHidden = !isExpanded
        ticketListTableView.layoutIfNeeded()
        tableViewHeight.constant = isExpanded ? ticketListTableView.contentSize.height : 0
        onExpandChanged?(isExpanded)
        onHeightChanged?()
        expandBnt.transform = isExpanded
            ? CGAffineTransform(rotationAngle: .pi)
            : .identity
    }
}

extension GroupTicketTVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tickets.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: TicketsTVC.identifier,
            for: indexPath
        ) as? TicketsTVC else {
            return UITableViewCell()
        }

        cell.isFromGroupTicket = true

        let ticket = tickets[indexPath.row]
        let isDescriptionExpanded = expandedTicketDescriptions.contains(ticket.id ?? "")
        let isDisabled = disabledTicketIds.contains(ticket.id ?? "")

        cell.configure(
            ticket: ticket,
            currency: currency,
            currencyPosition: currencyPosition,
            whiteLabelColor: whiteLabelColor,
            eventTicketSetting: eventTicketSetting,
            isDescriptionExpanded: isDescriptionExpanded,
            isLinkDisabled: isDisabled
        )
        cell.applyGroupTicketSpacing(isFirst: indexPath.row == 0)
        cell.hideShimmer()

        cell.onPlusTap = { [weak self] ticket in
            self?.onPlusTap?(ticket)
        }

        cell.onMinusTap = { [weak self] ticket in
            self?.onMinusTap?(ticket)
        }

        cell.onRSVPTap = { [weak self] ticket in
            self?.onRSVPTap?(ticket)
        }

        cell.onDescriptionToggle = { [weak self] in
            guard let self = self else { return }

            self.onDescriptionToggle?(ticket)
            self.onHeightChanged?()
        }

        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let ticket = tickets[indexPath.row]
        let currentCount = ticket.selectedTicketCount ?? 0
        let isDisabled = disabledTicketIds.contains(ticket.id ?? "")
        guard !isDisabled else { return }
        guard currentCount == 0 else { return }
        let price = ticket.price ?? 0
        if price != 0 {
            AppHaptic.stepperChanged()
            onRowTap?(ticket)
        }
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        .leastNonzeroMagnitude
    }
}
