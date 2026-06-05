//
//  EventQRTicketVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 04/06/26.
//

import UIKit

class EventQRTicketVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var tableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var progressBarView: UIView!
    
    
    private var faqs: [(question: String, answer: String)] = [
        (
            question: "Event details.",
            answer: "View all event information including venue, date, time, and other event-related details."
        ),
        (
            question: "How to use my tickets",
            answer: "Show your QR ticket at the venue entrance for scanning and entry."
        )
    ]

    private var expandedFAQIndex: Int?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        tableView.addObserver(
            self,
            forKeyPath: "contentSize",
            options: .new,
            context: nil
        )
    }

    deinit {
        tableView.removeObserver(self, forKeyPath: "contentSize")
    }

    override func observeValue(
        forKeyPath keyPath: String?,
        of object: Any?,
        change: [NSKeyValueChangeKey : Any]?,
        context: UnsafeMutableRawPointer?
    ) {
        if keyPath == "contentSize" {
            tableViewHeight.constant = tableView.contentSize.height
            view.layoutIfNeeded()
        }
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            FAQsTableViewCell.nib,
            forCellReuseIdentifier: FAQsTableViewCell.identifier
        )

        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 80
        tableView.separatorStyle = .none
        tableView.isScrollEnabled = false
    }
}

extension EventQRTicketVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        faqs.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: FAQsTableViewCell.identifier,
            for: indexPath
        ) as! FAQsTableViewCell

        let faq = faqs[indexPath.row]

        cell.questionLbl.text = faq.question
        cell.ansLbl.text = faq.answer
        cell.selectionStyle = .none

        let isExpanded = expandedFAQIndex == indexPath.row
        cell.ansView.isHidden = !isExpanded

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {

        expandedFAQIndex = (expandedFAQIndex == indexPath.row) ? nil : indexPath.row

        tableView.reloadData()

        DispatchQueue.main.async {
            self.tableViewHeight.constant = tableView.contentSize.height
        }
    }
}
