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

    var tickets: [EventTicket] = []
    var currency: String = "$"
    var whiteLabelColor: String?
    var eventTicketSetting: EventTicketSettings?

    var onPlusTap: ((EventTicket) -> Void)?
    var onMinusTap: ((EventTicket) -> Void)?
    var onRSVPTap: ((EventTicket) -> Void)?
    var onHeightChanged: (() -> Void)?

    private var isExpanded = true
    private var ticketTableObserver: NSKeyValueObservation?

    override func awakeFromNib() {
        super.awakeFromNib()

        ticketListTableView.delegate = self
        ticketListTableView.dataSource = self
        ticketListTableView.register(TicketsTVC.nib, forCellReuseIdentifier: TicketsTVC.identifier)
        ticketListTableView.isScrollEnabled = false
        ticketListTableView.rowHeight = UITableView.automaticDimension
        ticketListTableView.estimatedRowHeight = 140

        startTicketTableObserver()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onPlusTap = nil
        onMinusTap = nil
        onRSVPTap = nil
        onHeightChanged = nil
    }

    deinit {
        ticketTableObserver?.invalidate()
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
        whiteLabelColor: String?,
        eventTicketSetting: EventTicketSettings?
    ) {
        self.groupTitle.text = groupName
        self.tickets = tickets
        self.currency = currency
        self.whiteLabelColor = whiteLabelColor
        self.eventTicketSetting = eventTicketSetting

        ticketListTableView.isHidden = !isExpanded
        ticketListTableView.reloadData()
        ticketListTableView.layoutIfNeeded()
        tableViewHeight.constant = isExpanded ? ticketListTableView.contentSize.height : 0
    }

    @IBAction func onClickExpandBtn(_ sender: Any) {
        isExpanded.toggle()
        ticketListTableView.isHidden = !isExpanded
        ticketListTableView.layoutIfNeeded()
        tableViewHeight.constant = isExpanded ? ticketListTableView.contentSize.height : 0
        onHeightChanged?()
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

        let ticket = tickets[indexPath.row]

        cell.configure(
            ticket: ticket,
            currency: currency,
            whiteLabelColor: whiteLabelColor,
            eventTicketSetting: eventTicketSetting
        )

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
            self.ticketListTableView.beginUpdates()
            self.ticketListTableView.endUpdates()
            self.ticketListTableView.layoutIfNeeded()
            self.tableViewHeight.constant = self.isExpanded ? self.ticketListTableView.contentSize.height : 0
            self.onHeightChanged?()
        }

        return cell
    }
}
