//
//  SearchVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 22/12/25.
//

import UIKit

final class SearchVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var shimmerView: UIView! // optional if you already have in storyboard

    @IBOutlet weak var searchFeild: UITextField!
    private var rows: [SearchRow] = []

    private var events: [String] = []
    private var venues: [String] = []
    private var artists: [String] = []

    // ✅ Shimmer
    private var shimmerContainer: VenueEventsShimmerView?
    private var isShimmerLoading: Bool = true

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()

        // ✅ Start shimmer
        showShimmer()

        // ✅ Simulate API
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            self.isShimmerLoading = false
            self.stopShimmer()

            self.loadDummyData()
            self.buildRows()
        }
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        shimmerContainer?.frame = tableView.bounds
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none

        tableView.register(UINib(nibName: VenueEventTVC.identifier, bundle: nil),
                           forCellReuseIdentifier: VenueEventTVC.identifier)

        tableView.register(UINib(nibName: SearchVenueTableViewCell.identifier, bundle: nil),
                           forCellReuseIdentifier: SearchVenueTableViewCell.identifier)

        tableView.register(UINib(nibName: SearchArtistTableViewCell.identifier, bundle: nil),
                           forCellReuseIdentifier: SearchArtistTableViewCell.identifier)
    }

    // MARK: - Dummy Data

    private func loadDummyData() {
        events = ["Event 1", "Event 2", "Event 3"]
        venues = ["Partner 1", "Partner 2"]
        artists = ["Artist 1", "Artist 2", "Artist 3", "Artist 4"]
    }

    private func buildRows() {
        rows.removeAll()

        rows.append(contentsOf: events.map { .event($0) })
        rows.append(contentsOf: venues.map { .venue($0) })
        rows.append(contentsOf: artists.map { .artist($0) })

        tableView.reloadData()
    }

    // MARK: - Shimmer

    private func showShimmer() {
        let shimmer = VenueEventsShimmerView(frame: tableView.bounds)
        tableView.addSubview(shimmer)
        shimmer.start()
        shimmerContainer = shimmer
    }

    private func stopShimmer() {
        shimmerContainer?.stop()
        shimmerContainer?.removeFromSuperview()
        shimmerContainer = nil
    }

    // MARK: - Actions

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
}

// MARK: - Row Type

extension SearchVC {
    enum SearchRow {
        case event(String)
        case venue(String)
        case artist(String)
    }
}

// MARK: - UITableViewDelegate, UITableViewDataSource

extension SearchVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isShimmerLoading ? 6 : rows.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        // ✅ Shimmer state
        if isShimmerLoading {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: VenueEventTVC.identifier,
                for: indexPath
            ) as! VenueEventTVC

            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.alpha = 0

            return cell
        }

        // ✅ Real data
        switch rows[indexPath.row] {

        case .event(let event):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: VenueEventTVC.identifier,
                for: indexPath
            ) as! VenueEventTVC

            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.alpha = 1
            // cell.configure(with: event)

            return cell

        case .venue(let venue):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchVenueTableViewCell.identifier,
                for: indexPath
            ) as! SearchVenueTableViewCell

            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.alpha = 1
            // cell.configure(with: venue)

            return cell

        case .artist(let artist):
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchArtistTableViewCell.identifier,
                for: indexPath
            ) as! SearchArtistTableViewCell

            cell.selectionStyle = .none
            cell.backgroundColor = .clear
            cell.contentView.alpha = 1
            // cell.configure(with: artist)

            return cell
        }
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Navigate.to.gotoArtistDetailsVC(self)
    }
}
