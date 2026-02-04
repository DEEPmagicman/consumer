//
//  AllVenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 26/12/25.
//

import UIKit

final class AllVenueVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var venueTitleLbl: UILabel!
    
    private var venueList: [ClipVenue] = []
    private var presenter = MVPPresenter()

    private var skip = 0
    private var hasMore = true
    private var isLoading = false

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        fetchVenues()
        setupVenueTitle()
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VenueTVC.nib, forCellReuseIdentifier: VenueTVC.identifier)
        tableView.separatorStyle = .none
    }
    
    private func setupVenueTitle() {
        let city = resolvedCity()
        venueTitleLbl.text = "Venues in \(city)"
    }
    
    private func resolvedCity() -> String {
        let city = UserDefault.shared.localCity
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return city.isEmpty ? "New York" : city
    }

    private func fetchVenues(showLoader: Bool = true) {
        guard !isLoading, hasMore else { return }

        isLoading = true
        if showLoader { Loader.show() }

        presenter.getVenueListForMVP(
            from: skip,
            status: VenueStatus.open.rawValue
        ) { [weak self] isSuccess, errMsg, venues, hasMore in
            guard let self = self else { return }

            if isSuccess {
                self.venueList.append(contentsOf: venues)
                self.skip = self.venueList.count
                self.hasMore = hasMore
                self.tableView.reloadData()
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }

            self.isLoading = false
            Loader.hide()
        }
    }
}

extension AllVenueVC: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return venueList.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell: VenueTVC = tableView.dequeue(
            withIdentifier: VenueTVC.identifier,
            for: indexPath
        )

        let venue = venueList[indexPath.row]
        cell.configure(with: venue)
        cell.selectionStyle = .none

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        willDisplay cell: UITableViewCell,
        forRowAt indexPath: IndexPath
    ) {
        if indexPath.row == venueList.count - 2 {
            fetchVenues(showLoader: false)
        }
    }
}
