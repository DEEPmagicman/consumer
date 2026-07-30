//
//  SearchEventVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit

final class SearchEventVC: BaseSearchSheetVC {

    private let venue: SearchVenueItem?

    private let searchField = UITextField()
    private let tableView = UITableView()
    private let emptyView = SearchEmptyStateView()
    private let dateButton = UIButton(type: .system)

    private var events: [SearchEventItem] = []
    private var searchWorkItem: DispatchWorkItem?
    private var searchRequestID = 0
    private var hasMoreEvents = false
    private var isLoadingMore = false
    private let pageSize = 10

    private let leftDateLabel = UILabel()
    private let rightDateLabel = UILabel()
    
    var venueID: String = ""
    
    private var fromDate: Date?
    private var toDate: Date?

    private var isLoading = false

    init(venue: SearchVenueItem? = nil) {
        self.venue = venue
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        self.venue = nil
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        titleLabel.text = "Search"
        setupUI()
        loadSuggested()
    }

    private func setupUI() {
        setupSearchField()
        setupTable()
        setupEmpty()
        setupDateButton()
    }

    private func setupSearchField() {
        searchField.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.06)
        searchField.textColor = .white
        searchField.tintColor = .white
        searchField.font = Constant.Font.geistRegular(size: 16)
        searchField.layer.cornerRadius = 25
        searchField.layer.borderColor = UIColor.white.withAlphaComponent(0.04).cgColor
        searchField.layer.borderWidth = 0.5
        searchField.layer.cornerCurve = .continuous
        searchField.clipsToBounds = true
        searchField.placeholder = "Search event"
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
    }

    private func setupTable() {
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false
        tableView.dataSource = self
        tableView.delegate = self
        tableView.register(SearchEventCell.self, forCellReuseIdentifier: SearchEventCell.identifier)
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
            tableView.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -92)
        ])
    }
    
    private func setupDateButton() {

        dateButton.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.04)
        dateButton.layer.cornerRadius = 16
        dateButton.layer.cornerCurve = .continuous
        dateButton.addTarget(self, action: #selector(onClickDate), for: .touchUpInside)
        dateButton.translatesAutoresizingMaskIntoConstraints = false

        leftDateLabel.text = "Search by Date"
        leftDateLabel.textColor = UIColor(hex: "#737373")
        leftDateLabel.font = Constant.Font.geistRegular(size: 16)

        rightDateLabel.text = "Add Dates"
        rightDateLabel.textColor = .white
        rightDateLabel.font = Constant.Font.geistMedium(size: 16)

        [leftDateLabel, rightDateLabel].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
            dateButton.addSubview($0)
        }

        sheetView.addSubview(dateButton)

        NSLayoutConstraint.activate([

            dateButton.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            dateButton.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -16),
            dateButton.bottomAnchor.constraint(equalTo: sheetView.safeAreaLayoutGuide.bottomAnchor, constant: -16),
            dateButton.heightAnchor.constraint(equalToConstant: 56),

            leftDateLabel.leadingAnchor.constraint(equalTo: dateButton.leadingAnchor, constant: 20),
            leftDateLabel.centerYAnchor.constraint(equalTo: dateButton.centerYAnchor),

            rightDateLabel.trailingAnchor.constraint(equalTo: dateButton.trailingAnchor, constant: -20),
            rightDateLabel.centerYAnchor.constraint(equalTo: dateButton.centerYAnchor)
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

    private func loadSuggested() {
        searchEvents(nil, reset: true)
    }

    @objc private func onSearchChanged() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        searchWorkItem?.cancel()

        guard !keyword.isEmpty else {
            searchEvents(nil, reset: true)
            return
        }
        
        let work = DispatchWorkItem { [weak self] in
            self?.searchEvents(keyword, reset: true)
        }

        searchWorkItem = work
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45, execute: work)
    }

    @objc private func onClickDate() {
        let vc = SearchDateFilterVC()
        vc.fromDate = fromDate
        vc.toDate = toDate

        vc.onApply = { [weak self] from, to in
            guard let self else { return }
            self.fromDate = from
            self.toDate = to
            self.updateDateButton()
            self.searchEvents(self.searchField.text, reset: true)
        }
        present(vc, animated: true)
    }
    
    private func updateDateButton() {

        guard let fromDate, let toDate else {

            leftDateLabel.text = "Search by Date"
            leftDateLabel.textColor = UIColor(hex: "#737373")

            rightDateLabel.text = "Add Dates"
            rightDateLabel.textColor = .white
            return
        }

        leftDateLabel.text = "\(fromDate.shortDisplay()) - \(toDate.shortDisplay())"
        leftDateLabel.textColor = .white

        rightDateLabel.text = "Edit"
        rightDateLabel.textColor = .white.withAlphaComponent(0.7)
    }

    private func searchEvents(_ keyword: String?, reset: Bool) {
        let trimmedKeyword =
        keyword?.trimmingCharacters(in: .whitespacesAndNewlines)
        let searchKeyword = trimmedKeyword?.isEmpty == false
            ? trimmedKeyword
            : nil

        if reset {
            searchRequestID += 1
            isLoading = true
            isLoadingMore = false
            hasMoreEvents = false
            events.removeAll()
        } else {
            isLoadingMore = true
        }

        let requestID = searchRequestID

        tableView.isHidden = false
        tableView.reloadData()
        
        SearchFlowService.shared.searchEvents(
            venueId: venue?.venueUniqueId ?? venueID,
            keyword: searchKeyword,
            fromDate: fromDate,
            toDate: toDate,
            skip: reset ? 0 : events.count,
            take: pageSize
        ) { [weak self] isSuccess, _, events, hasMore in
            guard let self else { return }
            guard self.searchRequestID == requestID else { return }

            self.isLoading = false
            self.isLoadingMore = false
            self.hasMoreEvents = isSuccess ? hasMore : false

            if reset {
                self.events = isSuccess ? events : []
            } else if isSuccess {
                self.events.append(contentsOf: events)
            }

            let hasResults = !self.events.isEmpty

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

    private func loadMoreEventsIfNeeded() {
        guard !isLoading,
              !isLoadingMore,
              hasMoreEvents,
              !events.isEmpty else { return }

        searchEvents(searchField.text, reset: false)
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

extension SearchEventVC: UITableViewDataSource, UITableViewDelegate {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if isLoading {
            return 3
        }

        return events.count + (isLoadingMore ? 1 : 0)
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        if isLoading || indexPath.row >= events.count {
            let cell = tableView.dequeueReusableCell(
                withIdentifier: SearchShimmerCell.identifier,
                for: indexPath
            ) as! SearchShimmerCell

            cell.startShimmer()
            return cell
        }

        let cell = tableView.dequeueReusableCell(
            withIdentifier: SearchEventCell.identifier,
            for: indexPath
        ) as! SearchEventCell

        cell.configure(events[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard events.indices.contains(indexPath.row),
              let event = events[indexPath.row].event else { return }

        let presenter =
        navigationController?.presentingViewController ??
        presentingViewController

        dismiss(animated: true) {
            Navigate.eventDetailsVC(
                presenter ?? self,
                event: event
            )
        }
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

        loadMoreEventsIfNeeded()
    }
}
