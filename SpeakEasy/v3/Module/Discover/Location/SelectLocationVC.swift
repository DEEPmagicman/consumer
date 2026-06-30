//
//  SelectLocationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit
import Combine

enum SelectLocationMode {
    case selectCity
    case updatePrimaryLocation
}

final class SelectLocationVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var searchTextfeild: UITextField!
    
    @IBOutlet weak var editSeachCloseBtn: UIButton!
    @IBOutlet weak var editSearchTextFeild: UITextField!
    @IBOutlet weak var bgView: UIView!

    @IBOutlet weak var searchFeildNormelMode: UIView!
    @IBOutlet weak var searchFeildEditMode: UIView!

    @IBOutlet weak var discriptionLbl: UILabel!
    @IBOutlet weak var pageTitleLbl: UILabel!

    @IBOutlet weak var applyBtn: UIView!
    @IBOutlet weak var updateLocationBtn: PrimaryButton!
    @IBOutlet weak var editBtn: UIButton!
    @IBOutlet weak var editBtnView: UIView!
    @IBOutlet weak var primaryLocationLbl: UILabel!
    @IBOutlet weak var primaryLocationView: UIView!

    // MARK: - Properties

    var mode: SelectLocationMode = .selectCity {
        didSet {
            guard isViewLoaded else { return }
            setupUI()
            fetchCityList()
        }
    }

    private var fullCityList = [MVPCity]()
    private var displayList = [MVPCity]()

    private var primaryCity = ""
     var selectedFilterCity: String? {
        didSet {
            guard isViewLoaded else { return }
            updateApplyButtonState()
            tableView.reloadData()
        }
    }
    private var selectedCity = ""
     var initialFilterCity: String? {
        didSet {
            guard isViewLoaded else { return }
            updateApplyButtonState()
        }
    }
    private var initialPrimaryCity = ""
    var persistsFilterSelection = true {
        didSet {
            guard isViewLoaded else { return }
            normalizeFilterSelectionIfNeeded()
            setupUI()
            tableView.reloadData()
        }
    }
    
    var onSelectFilterCity: ((String?) -> Void)?
    var isInitialPrimarySelection = false
    var onSelectPrimaryCity: ((String) -> Void)?

    private var venueService = VenueService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        primaryCity = UserDefault.shared.primaryCity ?? ""
        selectedCity = primaryCity
        initialPrimaryCity = primaryCity
        if persistsFilterSelection {
            selectedFilterCity = selectedFilterCity ?? UserDefault.shared.filterCity
        }
        normalizeFilterSelectionIfNeeded()
        initialFilterCity = initialFilterCity ?? selectedFilterCity
        setupTableView()
        setupSearch()
        setupUI()
        fetchCityList()
        bindSelectedCity()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        bgView.applyScreenBgGradient(direction: .topToBottom)
    }
    
    @IBAction func onClickEditBtn(_ sender: Any) {

        let vc = SelectLocationVC()

        vc.mode = .updatePrimaryLocation

//        vc.modalPresentationStyle = .fullScreen

        present(vc, animated: true)
    }
}

// MARK: - Setup

private extension SelectLocationVC {
    
    private func bindSelectedCity() {
        UserDefault.shared.localCityPublisher
            .removeDuplicates()
            .map { _ in self.resolvedCity() }
            .receive(on: RunLoop.main)
            .sink { [weak self] city in
                self?.primaryLocationLbl.text = city
            }
            .store(in: &cancellables)
    }
    
    private func resolvedCity() -> String {
        let city = UserDefault.shared.localCity
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return city.isEmpty ? "New York" : city
    }

    func setupTableView() {

        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            SelectLocationTVC.nib,
            forCellReuseIdentifier: SelectLocationTVC.identifier
        )

        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
    }

    func setupSearch() {

        searchTextfeild.addTarget(
            self,
            action: #selector(textDidChange),
            for: .editingChanged
        )
        
        editSearchTextFeild.addTarget(
               self,
               action: #selector(textDidChange(_:)),
               for: .editingChanged
           )
    }

    func setupUI() {

        switch mode {

        case .selectCity:

            pageTitleLbl.text = "Select City"
            primaryLocationView.isHidden = !persistsFilterSelection
            discriptionLbl.isHidden = !persistsFilterSelection

            searchFeildNormelMode.isHidden = false
            searchFeildEditMode.isHidden = true

            updateLocationBtn.isHidden = true

            editBtnView.isHidden = false

            updateApplyButtonState()

        case .updatePrimaryLocation:

            pageTitleLbl.text = isInitialPrimarySelection ? "Select City" : "Location"
            primaryLocationView.isHidden = isInitialPrimarySelection

            searchFeildNormelMode.isHidden = true
            searchFeildEditMode.isHidden = false

            editBtnView.isHidden = true
            discriptionLbl.isHidden = false
            updateLocationBtn.setTitle(
                isInitialPrimarySelection ? "Continue" : "Update location",
                for: .normal
            )

            updateLocationButtonState()
        }
    }
    
    func updateApplyButtonState() {
        updateLocationBtn.isHidden = true
        applyBtn.isHidden =
        normalizedCity(selectedFilterCity) == normalizedCity(initialFilterCity)
    }

    func updateLocationButtonState() {
        applyBtn.isHidden = true
        updateLocationBtn.isHidden =
        selectedCity == initialPrimaryCity
    }

    func normalizeFilterSelectionIfNeeded() {
        guard normalizedCity(selectedFilterCity) == normalizedCity(primaryCity) else {
            return
        }

        selectedFilterCity = nil

        if persistsFilterSelection {
            UserDefault.shared.filterCity = nil
        }
    }

    func normalizedCity(_ city: String?) -> String {
        city?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }
}

// MARK: - Actions

extension SelectLocationVC {

    @IBAction func onClickBack(_ sender: Any) {
        dismiss(animated: true)
    }

    @IBAction func onClickSearchClosebtn(_ sender: Any) {

        searchTextfeild.text = ""

        closeBtn.isHidden = true

        displayList = fullCityList

        tableView.reloadData()
    }
    
    @IBAction func onClickEditSearchClosebtn(_ sender: Any) {

        editSearchTextFeild.text = ""

        editSeachCloseBtn.isHidden = true

        displayList = fullCityList

        tableView.reloadData()
    }

    @IBAction func onClickApply(_ sender: Any) {

        let city = normalizedCity(selectedFilterCity) == normalizedCity(primaryCity)
            ? nil
            : selectedFilterCity

        if persistsFilterSelection {
            UserDefault.shared.filterCity = city
        }
        onSelectFilterCity?(city)

        dismiss(animated: true)
    }
    
    @IBAction func onClickUpdateLocation(_ sender: Any) {

        guard !selectedCity.isEmpty else { return }

        if isInitialPrimarySelection {
            UserDefault.shared.setPrimaryCity(selectedCity)
            UserDefault.shared.filterCity = nil
            onSelectPrimaryCity?(selectedCity)
            dismiss(animated: true)
            return
        }

        Navigate.to.presentLocationUpdatePopup(
            from: self,
            title: "You're updating your preferred location to \(selectedCity)?",
            subtitle: "Premium bookings, priority reservations, and high-demand experiences all in one place."
        ) { [weak self] in

            guard let self else { return }

            UserDefault.shared.localCity =
            self.selectedCity

            if UserDefault.shared.filterCity?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(self.selectedCity) == .orderedSame {
                UserDefault.shared.filterCity = nil
            }

            self.primaryLocationLbl.text =
            self.selectedCity

            self.dismiss(animated: true)
        }
    }
}

// MARK: - Search

private extension SelectLocationVC {

    @objc
    func textDidChange(_ textField: UITextField) {

        let searchText = textField.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        switch textField {

        case searchTextfeild:

            closeBtn.isHidden = searchText.isEmpty

        case editSearchTextFeild:

            editSeachCloseBtn.isHidden = searchText.isEmpty

        default:
            break
        }

        if searchText.isEmpty {

            displayList = fullCityList

        } else {

            displayList = fullCityList.filter {
                $0.value.lowercased()
                    .contains(searchText.lowercased())
            }
        }

        tableView.reloadData()
    }
}

// MARK: - API

private extension SelectLocationVC {

    func fetchCityList() {

        venueService.fetchCityList { [weak self] cityList, isSuccess, errMsg in

            guard let self else {
                return
            }

            if isSuccess {
                
                switch self.mode {

                case .selectCity:

                    let primaryLocation = UserDefault.shared.localCity
                        .trimmingCharacters(in: .whitespacesAndNewlines)
                        .lowercased()

                    self.fullCityList = cityList.filter {
                        $0.value.trimmingCharacters(in: .whitespacesAndNewlines)
                            .lowercased() != primaryLocation
                    }

                case .updatePrimaryLocation:

                    self.fullCityList = cityList
                }

                self.displayList = self.fullCityList

                self.tableView.reloadData()

            } else {

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }
}

// MARK: - UITableView

extension SelectLocationVC:
UITableViewDelegate,
UITableViewDataSource {

    func tableView(
        _ tableView: UITableView,
        numberOfRowsInSection section: Int
    ) -> Int {

        return displayList.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell: SelectLocationTVC = tableView.dequeue(
            withIdentifier: SelectLocationTVC.identifier,
            for: indexPath
        )

        let city = displayList[indexPath.row]

        let isSelected: Bool

        switch mode {

        case .selectCity:

            isSelected = city.value == selectedFilterCity

        case .updatePrimaryLocation:

            isSelected = city.value == selectedCity
        }

        cell.configure(
            with: city,
            isSelected: isSelected
        )

        cell.selectionStyle = .none

        return cell
    }

    func tableView(
        _ tableView: UITableView,
        didSelectRowAt indexPath: IndexPath
    ) {

        let city = displayList[indexPath.row].value

        switch mode {

        case .selectCity:
            if selectedFilterCity == city {

                selectedFilterCity = nil

            } else {

                selectedFilterCity = city
            }

            updateApplyButtonState()

        case .updatePrimaryLocation:

            selectedCity = city

            updateLocationButtonState()
        }

        tableView.reloadData()
    }
}
