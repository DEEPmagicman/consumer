//
//  SearchVenueVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit

final class SearchVenueVC: BaseSearchSheetVC {

    enum SearchMode {
        case followed
        case global
    }

    private let searchField = UITextField()
    private let tableView = UITableView()
    private let emptyView = SearchEmptyStateView()

    private var venues: [SearchVenueItem] = []
    private var searchWorkItem: DispatchWorkItem?
    private var hasMoreVenues = false
    private var isLoading = false
    private var isLoadingMore = false
    private let pageSize = 10
    private let venueService = VenueService()

    var initialKeyword: String?
    var searchMode: SearchMode = .followed
    
    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Search"
        setupUI()
    }

    private func setupUI() {
        setupSearchField()
        setupTable()
        setupEmpty()

        let keyword =
        initialKeyword?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
        searchField.text = keyword

        if keyword.isEmpty {
            emptyView.isHidden = false
            tableView.isHidden = true
        } else {
            searchVenues(keyword, skip: 0, reset: true)
        }
    }

    private func setupSearchField() {
        searchField.backgroundColor = UIColor(hex: "#141414")
        searchField.textColor = .white
        searchField.tintColor = .white
        searchField.font = Constant.Font.geistRegular(size: 16)
        searchField.layer.cornerRadius = 25
        searchField.layer.borderColor = UIColor.white.withAlphaComponent(0.04).cgColor
        searchField.layer.borderWidth = 0.5
        searchField.layer.cornerCurve = .continuous
        searchField.clipsToBounds = true
        searchField.placeholder =
        searchMode == .followed ? "Search followed venues" : "Search venues"
        searchField.leftView = makeSearchIcon()
        searchField.leftViewMode = .always
        searchField.addTarget(self, action: #selector(onSearchChanged), for: .editingChanged)
        searchField.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(searchField)

        NSLayoutConstraint.activate([
            searchField.topAnchor.constraint(equalTo: closeBtn.bottomAnchor, constant: 16),
            searchField.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            searchField.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -16),
            searchField.heightAnchor.constraint(equalToConstant: 50)
        ])

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            self.searchField.becomeFirstResponder()
        }
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchVenueCell.self, forCellReuseIdentifier: SearchVenueCell.identifier)
        tableView.register(
            SearchShimmerCell.self,
            forCellReuseIdentifier: SearchShimmerCell.identifier
        )
        tableView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(tableView)

        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: searchField.bottomAnchor, constant: 18),
            tableView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            tableView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -16),
            tableView.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor)
        ])
    }
    
    private func setupEmpty() {

        emptyView.isHidden = true
        emptyView.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(emptyView)

        NSLayoutConstraint.activate([

            emptyView.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),
            emptyView.centerYAnchor.constraint(equalTo: sheetView.centerYAnchor, constant: -40),

            emptyView.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 30),
            emptyView.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -30)
        ])
    }

    @objc private func onSearchChanged() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        searchWorkItem?.cancel()

        guard !keyword.isEmpty else {
            venues.removeAll()
            UIView.animate(withDuration: 0.25) {
                self.emptyView.alpha = 0
            } completion: { _ in
                self.emptyView.isHidden = true
            }
            tableView.reloadData()
            return
        }

        let work = DispatchWorkItem { [weak self] in
            self?.searchVenues(keyword, skip: 0, reset: true)
        }

        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    private func searchVenues(
        _ keyword: String,
        skip: Int,
        reset: Bool
    ) {
        if reset {
            isLoading = true
            isLoadingMore = false
            venues.removeAll()
        } else {
            isLoadingMore = true
        }

        tableView.isHidden = false
        tableView.reloadData()

        fetchVenues(
            keyword: keyword,
            skip: skip
        ) { [weak self] isSuccess, _, venues, hasMore in
            guard let self else { return }

            self.isLoading = false
            self.isLoadingMore = false

            if reset {
                self.venues = isSuccess ? venues : []
            } else if isSuccess {
                self.venues.append(contentsOf: venues)
            }

            self.hasMoreVenues = isSuccess ? hasMore : false

            let hasResults = !self.venues.isEmpty

            if hasResults {
                UIView.animate(withDuration: 0.25) {
                    self.emptyView.alpha = 0
                } completion: { _ in
                    self.emptyView.isHidden = true
                }
            } else {
                self.emptyView.isHidden = false
                self.emptyView.alpha = 0

                UIView.animate(withDuration: 0.25) {
                    self.emptyView.alpha = 1
                }
            }

            self.tableView.isHidden = !hasResults
            self.tableView.reloadData()
        }
    }

    private func fetchVenues(
        keyword: String,
        skip: Int,
        completion: @escaping (
            Bool,
            String?,
            [SearchVenueItem],
            Bool
        ) -> Void
    ) {

        switch searchMode {
        case .followed:
            venueService.fetchFollowedVenues(
                skip: skip,
                take: pageSize,
                search: keyword
            ) { isSuccess, errorMessage, venues, hasMore in
                completion(
                    isSuccess,
                    errorMessage,
                    venues.map {
                        SearchVenueItem(
                            id: $0.id,
                            name: $0.name,
                            imageURL: ($0.logo?.key ?? $0.venueAttachment?.first?.key)?.imageURL,
                            venue: $0
                        )
                    },
                    hasMore
                )
            }

        case .global:
            SearchFlowService.shared.searchVenues(
                keyword: keyword,
                skip: skip,
                take: pageSize,
                completion: completion
            )
        }
    }

    private func loadMoreVenuesIfNeeded() {
        let keyword =
        searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        guard !keyword.isEmpty,
              !isLoading,
              !isLoadingMore,
              hasMoreVenues else { return }

        searchVenues(
            keyword,
            skip: venues.count,
            reset: false
        )
    }

    private func makeSearchIcon() -> UIView {
        let container = UIView(frame: CGRect(x: 0, y: 0, width: 36, height: 42))
        let imageView = UIImageView(image: UIImage(resource: .searchIconV3))
        imageView.tintColor = AppColor.primaryWhiteColor.withAlphaComponent(0.8)
        imageView.contentMode = .scaleAspectFit
        imageView.frame = CGRect(x: 12, y: 13, width: 16, height: 16)
        container.addSubview(imageView)
        return container
    }
}

extension SearchVenueVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        isLoading ? 3 : venues.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if isLoading {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchShimmerCell.identifier,
                for: indexPath
            ) as! SearchShimmerCell

            cell.startShimmer()
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchVenueCell.identifier,
            for: indexPath
        ) as! SearchVenueCell

        cell.configure(venues[indexPath.row])
        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if venues.count <= indexPath.row { return }
        let venue = venues[indexPath.row]
        
        Navigate.to.eventsListVC(
            self, venue: venue
        )

//        let presenter =
//        navigationController?.presentingViewController ??
//        presentingViewController
//
//        dismiss(animated: true) {
//            if let venueDetails = venue.venue {
//                let venueListVC =
//                presenter as? VenueListVC ??
//                (presenter as? UINavigationController)?.topViewController as? VenueListVC
//
//                Navigate.to.venueVC(
//                    presenter ?? self,
//                    venueDetails: venueDetails
//                ) { updatedVenue, isFollowing in
//                    venueListVC?.handleFollowStateChange(
//                        venue: updatedVenue,
//                        isFollowing: isFollowing
//                    )
//                }
//            }
//        }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let threshold: CGFloat = 120
        let offsetY = scrollView.contentOffset.y
        let visibleHeight = scrollView.bounds.height
        let contentHeight = scrollView.contentSize.height

        guard contentHeight > 0,
              offsetY + visibleHeight + threshold >= contentHeight else {
            return
        }

        loadMoreVenuesIfNeeded()
    }
}
