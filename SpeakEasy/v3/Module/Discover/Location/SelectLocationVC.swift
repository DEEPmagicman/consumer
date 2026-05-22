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
    
    
    // MARK: - Properties

    var mode: SelectLocationMode = .selectCity

    private var fullCityList = [MVPCity]()
    private var displayList = [MVPCity]()

    private var primaryCity = ""
     var selectedFilterCity: String?
    private var selectedCity = ""
     var initialFilterCity: String?
    private var initialPrimaryCity = ""
    
    var onSelectFilterCity: ((String?) -> Void)?

    private var presenter = OnBoardingPresenter()
    private var mvpPresenter = MVPPresenter()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        primaryCity = UserDefault.shared.localCity
        selectedCity = primaryCity
        initialPrimaryCity = primaryCity
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

            searchFeildNormelMode.isHidden = false
            searchFeildEditMode.isHidden = true

            updateLocationBtn.isHidden = true

            editBtnView.isHidden = false
            discriptionLbl.isHidden = false

            updateApplyButtonState()

        case .updatePrimaryLocation:

            pageTitleLbl.text = "Location"

            searchFeildNormelMode.isHidden = true
            searchFeildEditMode.isHidden = false

            editBtnView.isHidden = true
            discriptionLbl.isHidden = false

            updateLocationButtonState()
        }
    }
    
    func updateApplyButtonState() {
        updateLocationBtn.isHidden = true
        applyBtn.isHidden =
        selectedFilterCity == initialFilterCity
    }

    func updateLocationButtonState() {
        applyBtn.isHidden = true
        updateLocationBtn.isHidden =
        selectedCity == initialPrimaryCity
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

        onSelectFilterCity?(selectedFilterCity)

        dismiss(animated: true)
    }
    
    
    

    @IBAction func onClickUpdateLocation(_ sender: Any) {

        guard !selectedCity.isEmpty else { return }

        Navigate.to.presentLocationUpdatePopup(
            from: self,
            title: "You're updating your preferred location to \(selectedCity)?",
            subtitle: "Premium bookings, priority reservations, and high-demand experiences all in one place."
        ) { [weak self] in

            guard let self else { return }

            UserDefault.shared.localCity =
            self.selectedCity

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

        mvpPresenter.mvpCityListAPi { [weak self] cityList, isSuccess, errMsg in

            guard let self else {
                Loader.hide()
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
