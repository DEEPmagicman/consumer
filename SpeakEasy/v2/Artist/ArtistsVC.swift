//
//  ArtistsVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit

final class ArtistsVC: UIViewController, SJSegmentedViewControllerViewSource {

    @IBOutlet weak var tableView: UITableView!

    // MARK: - Data
    private var artists: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadArtists()
    }

    // MARK: - Segmented Scroll Source
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        return tableView
    }

    // MARK: - Setup
    private func setupTableView() {

        tableView.delegate = self
        tableView.dataSource = self

        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.alwaysBounceVertical = true

        tableView.register(
            UINib(nibName: "ArtistsTableViewCell", bundle: nil),
            forCellReuseIdentifier: "ArtistsTableViewCell"
        )
    }

    // MARK: - Data
    private func loadArtists() {

        artists = [
            "Artist 1",
            "Artist 2",
            "Artist 3",
            "Artist 4",
            "Artist 5",
            "Artist 6"
        ]

        tableView.reloadData()
    }
}

// MARK: - UITableViewDataSource
extension ArtistsVC: UITableViewDataSource {

    func tableView(_ tableView: UITableView,
                   numberOfRowsInSection section: Int) -> Int {
        return artists.count
    }

    func tableView(_ tableView: UITableView,
                   cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: "ArtistsTableViewCell",
            for: indexPath
        ) as? ArtistsTableViewCell else {
            return UITableViewCell()
        }

        let artistName = artists[indexPath.row]

        cell.selectionStyle = .none
        cell.backgroundColor = .clear
        cell.configure(name: artistName)

        return cell
    }
}

// MARK: - UITableViewDelegate
extension ArtistsVC: UITableViewDelegate {

    func tableView(_ tableView: UITableView,
                   didSelectRowAt indexPath: IndexPath) {

        Navigate.to.gotoArtistDetailsVC(self)
    }
}
