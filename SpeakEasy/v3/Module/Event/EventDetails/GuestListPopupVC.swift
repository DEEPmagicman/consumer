//
//  GuestListPopupVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 24/03/26.
//

import Foundation
import UIKit

final class GuestListPopupVC: UIViewController {

    var attendees: [Attendee] = []
    var eventId: String?
    var totalAttendees = 0
    var totalTicketSold: Int?
    var hasMore = false

    private let dimmedView = UIView()
    private let popupView = GradientBorderCardView()
    private let headerContainerView = UIView()
    private let titleLabel = UILabel()
    private let countLabel = UILabel()
    private let closeButton = UIButton(type: .system)
    private let separatorView = UIView()
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let footerSpinner = UIActivityIndicatorView(style: .medium)
    private let eventService = EventService()

    private var popupCenterYConstraint: NSLayoutConstraint!
    private var popupHeightConstraint: NSLayoutConstraint!
    private var tableHeightConstraint: NSLayoutConstraint!
    private var isFetchingMore = false

    private let rowHeight: CGFloat = 72
    private let maxVisibleRows = 5
    private let pageSize = 10
    private let sideInset: CGFloat = 20
    private let headerTopPadding: CGFloat = 18
    private let headerBottomPadding: CGFloat = 14
    private let bottomPadding: CGFloat = 14
    private let popupMaxHeightRatio: CGFloat = 0.75

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTableView()
        reloadUI()
        animateIn()
        
    }

    private func setupUI() {
        view.backgroundColor = .clear

        dimmedView.translatesAutoresizingMaskIntoConstraints = false
        dimmedView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        dimmedView.alpha = 0
        view.addSubview(dimmedView)

        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissPopup))
        dimmedView.addGestureRecognizer(tap)

        popupView.translatesAutoresizingMaskIntoConstraints = false
        popupView.backgroundColor = UIColor(hex: "#171717")
//        popupView.layer.cornerRadius = 16
//        popupView.clipsToBounds = true
        view.addSubview(popupView)

        headerContainerView.translatesAutoresizingMaskIntoConstraints = false
        headerContainerView.backgroundColor = .clear
        popupView.addSubview(headerContainerView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "Guestlist"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.interMedium(size: 16)

        countLabel.translatesAutoresizingMaskIntoConstraints = false
        countLabel.textColor = UIColor.white.withAlphaComponent(0.75)
        countLabel.font = Constant.Font.interRegular(size: 12)

        closeButton.translatesAutoresizingMaskIntoConstraints = false
        closeButton.tintColor = .white
        closeButton.setImage(UIImage(systemName: "xmark"), for: .normal)
        closeButton.addTarget(self, action: #selector(dismissPopup), for: .touchUpInside)

        separatorView.translatesAutoresizingMaskIntoConstraints = false
        separatorView.backgroundColor = UIColor.white.withAlphaComponent(0.12)

        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.backgroundColor = .clear

        popupView.addSubview(titleLabel)
        popupView.addSubview(countLabel)
        popupView.addSubview(closeButton)
        popupView.addSubview(separatorView)
        popupView.addSubview(tableView)

        NSLayoutConstraint.activate([
            dimmedView.topAnchor.constraint(equalTo: view.topAnchor),
            dimmedView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimmedView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimmedView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            popupView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: sideInset),
            popupView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -sideInset),

            titleLabel.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            titleLabel.topAnchor.constraint(equalTo: popupView.topAnchor, constant: headerTopPadding),

            countLabel.leadingAnchor.constraint(equalTo: titleLabel.trailingAnchor, constant: 8),
            countLabel.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor, constant: 1),

            closeButton.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -16),
            closeButton.centerYAnchor.constraint(equalTo: titleLabel.centerYAnchor),
            closeButton.widthAnchor.constraint(equalToConstant: 28),
            closeButton.heightAnchor.constraint(equalToConstant: 28),

            separatorView.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: headerBottomPadding),
            separatorView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor, constant: 20),
            separatorView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor, constant: -20),
            separatorView.heightAnchor.constraint(equalToConstant: 1),

            tableView.topAnchor.constraint(equalTo: separatorView.bottomAnchor, constant: 6),
            tableView.leadingAnchor.constraint(equalTo: popupView.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: popupView.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: popupView.bottomAnchor, constant: -bottomPadding)
        ])

        popupCenterYConstraint = popupView.centerYAnchor.constraint(equalTo: view.centerYAnchor)
        popupCenterYConstraint.isActive = true

        popupHeightConstraint = popupView.heightAnchor.constraint(equalToConstant: 220)
        popupHeightConstraint.isActive = true

        tableHeightConstraint = tableView.heightAnchor.constraint(equalToConstant: 100)
        tableHeightConstraint.isActive = true
    }

    private func setupTableView() {
        tableView.register(GuestListPopupCell.self, forCellReuseIdentifier: GuestListPopupCell.identifier)
        tableView.delegate = self
        tableView.dataSource = self
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = true
        tableView.isScrollEnabled = false
        tableView.rowHeight = rowHeight
        tableView.estimatedRowHeight = rowHeight
        tableView.contentInset = .zero
        footerSpinner.color = UIColor.white.withAlphaComponent(0.75)
        footerSpinner.hidesWhenStopped = true
        footerSpinner.frame = CGRect(x: 0, y: 0, width: 1, height: 44)
    }

    private func reloadUI() {
        let count = attendees.count
        let displayTotal = max(totalTicketSold ?? totalAttendees, count)
        countLabel.text = "\(displayTotal) going"

        tableView.reloadData()
        tableView.layoutIfNeeded()

        let visibleRows = min(count, maxVisibleRows)
        let tableHeight = CGFloat(visibleRows) * rowHeight
        tableHeightConstraint.constant = tableHeight

        tableView.isScrollEnabled = count > maxVisibleRows

        let contentHeight = headerTopPadding + 22 + headerBottomPadding + 1 + 6 + tableHeight + bottomPadding
        let maxHeight = UIScreen.main.bounds.height * popupMaxHeightRatio
        popupHeightConstraint.constant = min(contentHeight, maxHeight)
        updateFooterSpinner()

        view.layoutIfNeeded()
        tryFetchMoreIfListDoesNotOverflow()
    }

    private func updateFooterSpinner() {
        tableView.tableFooterView = isFetchingMore ? footerSpinner : nil

        if isFetchingMore {
            footerSpinner.startAnimating()
        } else {
            footerSpinner.stopAnimating()
        }
    }

    private func tryFetchMoreIfListDoesNotOverflow() {
        DispatchQueue.main.async { [weak self] in
            guard let self,
                  self.hasMore,
                  !self.isFetchingMore,
                  self.tableView.window != nil else {
                return
            }

            let hasScrollableOverflow =
            self.tableView.contentSize.height >
            self.tableView.bounds.height + 1

            if !hasScrollableOverflow {
                self.fetchMoreAttendees()
            }
        }
    }

    private func fetchMoreAttendees() {
        guard hasMore,
              !isFetchingMore,
              let eventId,
              !eventId.isEmpty else {
            return
        }

        isFetchingMore = true
        updateFooterSpinner()

        eventService.fetchEventAttendees(
            eventId: eventId,
            skip: attendees.count,
            take: pageSize
        ) { [weak self] success, _, list, total, totalTicketSold, hasMore, _ in
            DispatchQueue.main.async {
                guard let self else { return }

                self.isFetchingMore = false

                if success {
                    let appendedCount = self.appendAttendees(list ?? [])
                    self.totalAttendees = max(
                        max(total ?? self.totalAttendees, self.totalAttendees),
                        self.attendees.count
                    )
                    self.totalTicketSold = totalTicketSold ?? self.totalTicketSold
                    self.hasMore =
                    appendedCount > 0 &&
                    (hasMore || self.totalAttendees > self.attendees.count)
                }

                self.reloadUI()
            }
        }
    }

    private func appendAttendees(_ list: [Attendee]) -> Int {
        guard !list.isEmpty else { return 0 }

        var seenIds = Set(attendees.compactMap { $0.id })
        let originalCount = attendees.count

        list.forEach { attendee in
            if let id = attendee.id, !id.isEmpty {
                guard !seenIds.contains(id) else { return }
                seenIds.insert(id)
            }

            attendees.append(attendee)
        }

        attendees = sortAttendeesImageFirst(attendees)
        return attendees.count - originalCount
    }

    private func sortAttendeesImageFirst(_ list: [Attendee]) -> [Attendee] {
        let withImage = list.filter { $0.hasImage }
        let withoutImage = list.filter { !$0.hasImage }
        return withImage + withoutImage
    }

    private func animateIn() {
        popupView.transform = CGAffineTransform(translationX: 0, y: 30).scaledBy(x: 0.98, y: 0.98)
        popupView.alpha = 0

        UIView.animate(withDuration: 0.25) {
            self.dimmedView.alpha = 1
            self.popupView.alpha = 1
            self.popupView.transform = .identity
        }
    }

    private func animateOut(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.2, animations: {
            self.dimmedView.alpha = 0
            self.popupView.alpha = 0
            self.popupView.transform = CGAffineTransform(translationX: 0, y: 20).scaledBy(x: 0.98, y: 0.98)
        }) { _ in
            completion?()
        }
    }

    @objc private func dismissPopup() {
        animateOut { [weak self] in
            self?.dismiss(animated: false)
        }
    }

    private func openInstagram(for attendee: Attendee) {
        let instaId = attendee.instagramUserId?
            .replacingOccurrences(of: "@", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !instaId.isEmpty else { return }

        let appUrlString = "instagram://user?username=\(instaId)"
        if let appUrl = URL(string: appUrlString),
           UIApplication.shared.canOpenURL(appUrl) {
            UIApplication.shared.open(appUrl)
            return
        }

        let webUrlString = "https://instagram.com/\(instaId)"
        if let webUrl = URL(string: webUrlString) {
            UIApplication.shared.open(webUrl)
        }
    }
}

extension GuestListPopupVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        attendees.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: GuestListPopupCell.identifier,
            for: indexPath
        ) as? GuestListPopupCell else {
            return UITableViewCell()
        }

        let attendee = attendees[indexPath.row]
        cell.configure(with: attendee, isLast: indexPath.row == attendees.count - 1)

        cell.onInstagramTap = { [weak self] in
            self?.openInstagram(for: attendee)
        }

        return cell
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard hasMore,
              !isFetchingMore,
              scrollView.contentSize.height > 0 else {
            return
        }

        let distanceFromBottom =
        scrollView.contentSize.height -
        scrollView.contentOffset.y -
        scrollView.bounds.height

        if distanceFromBottom <= 80 {
            fetchMoreAttendees()
        }
    }
}
