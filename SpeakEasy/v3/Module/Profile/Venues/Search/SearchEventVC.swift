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

    private let leftDateLabel = UILabel()
    private let rightDateLabel = UILabel()
    
    var venueID: String = ""
    
    private var fromDate: Date?
    private var toDate: Date?

    private var isLoading = false
    
    private let dummyEvents: [SearchEventItem] = [
        SearchEventItem(
            id: "1",
            title: "The Grand Hall",
            dateText: "Apr 18 at 8PM",
            imageURL: nil
        ),
        SearchEventItem(
            id: "2",
            title: "Skyline Rooftop",
            dateText: "Apr 18 at 8PM",
            imageURL: nil
        ),
        SearchEventItem(
            id: "3",
            title: "Ocean View Lounge",
            dateText: "Apr 18 at 8PM",
            imageURL: nil
        ),
        SearchEventItem(
            id: "4",
            title: "Downtown Club",
            dateText: "Apr 18 at 8PM",
            imageURL: nil
        ),
        SearchEventItem(
            id: "5",
            title: "Sunset Terrace",
            dateText: "Apr 18 at 8PM",
            imageURL: nil
        )
    ]
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
//        loadSuggested() // enable after api implement
        
        //MARK: Dummy Data
        emptyView.isHidden = false
//        searchEvents("A")
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

        leftDateLabel.text = "Search by date"
        leftDateLabel.textColor = UIColor(hex: "#737373")
        leftDateLabel.font = Constant.Font.geistRegular(size: 16)

        rightDateLabel.text = "Add dates"
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
        searchEvents(nil)
    }

    @objc private func onSearchChanged() {
        let keyword = searchField.text?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        searchWorkItem?.cancel()

        guard !keyword.isEmpty else {
            events.removeAll()
            tableView.reloadData()
            UIView.animate(withDuration: 0.25) {
                self.emptyView.alpha = 1 // need to change 0 after api
            } completion: { _ in
                self.emptyView.isHidden = false // need to change true after api
            }
            return
        }
        
        let work = DispatchWorkItem { [weak self] in
            self?.searchEvents(keyword)
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
            self.searchEvents(self.searchField.text)
        }

        vc.modalPresentationStyle = .overFullScreen
        vc.modalTransitionStyle = .crossDissolve
        present(vc, animated: true)
    }
    
    private func updateDateButton() {

        guard let fromDate, let toDate else {

            leftDateLabel.text = "Search by date"
            leftDateLabel.textColor = UIColor(hex: "#737373")

            rightDateLabel.text = "Add dates"
            rightDateLabel.textColor = .white
            return
        }

        leftDateLabel.text = "\(fromDate.shortDisplay()) - \(toDate.shortDisplay())"
        leftDateLabel.textColor = .white

        rightDateLabel.text = "Edit"
        rightDateLabel.textColor = .white.withAlphaComponent(0.7)
    }

    private func searchEvents(_ keyword: String?) {
        isLoading = true
        tableView.isHidden = false
        tableView.reloadData()
        
        SearchFlowService.shared.searchEvents(
            venueId: venue?.id,
            keyword: keyword,
            fromDate: fromDate,
            toDate: toDate
        ) { [weak self] events in
            guard let self else { return }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                self.isLoading = false
                self.events = events
                self.events = self.dummyEvents // remove this line after correct api  implement
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
        isLoading ? 3 : events.count
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
            withIdentifier: SearchEventCell.identifier,
            for: indexPath
        ) as! SearchEventCell

        cell.configure(events[indexPath.row])
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        if events.count <= indexPath.row { return }
//        let event = events[indexPath.row]
    }
}
