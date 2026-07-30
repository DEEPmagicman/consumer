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

    private lazy var emptyStateView: UIView = {
        let container = UIView()
        container.backgroundColor = .clear

        let titleLabel = UILabel()
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.text = "No Cities Found"
        titleLabel.textAlignment = .center
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 16)

        let subtitleLabel = UILabel()
        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Try searching for another city."
        subtitleLabel.textAlignment = .center
        subtitleLabel.textColor = UIColor.white.withAlphaComponent(0.58)
        subtitleLabel.font = Constant.Font.geistRegular(size: 13)
        subtitleLabel.numberOfLines = 0

        container.addSubview(titleLabel)
        container.addSubview(subtitleLabel)

        NSLayoutConstraint.activate([
            titleLabel.centerYAnchor.constraint(equalTo: container.centerYAnchor, constant: -18),
            titleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            titleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24),

            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 8),
            subtitleLabel.leadingAnchor.constraint(equalTo: container.leadingAnchor, constant: 24),
            subtitleLabel.trailingAnchor.constraint(equalTo: container.trailingAnchor, constant: -24)
        ])

        return container
    }()

    var mode: SelectLocationMode = .selectCity {
        didSet {
            guard isViewLoaded else { return }
            setupUI()
            fetchCityList()
        }
    }

    private var fullCityList = [MVPCity]()
    private var displayList = [MVPCity]()
    private var isLoadingCityList = false
    private let cityShimmerRowCount = 8

    private var primaryCity = ""
     var selectedFilterCity: String? {
        didSet {
            guard isViewLoaded else { return }
            updateApplyButtonState()
            reloadCityList()
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
            reloadCityList()
        }
    }
    
    var onSelectFilterCity: ((String?) -> Void)?
    var isInitialPrimarySelection = false
    var onSelectPrimaryCity: ((String) -> Void)?
    private var didApplyInitialPrimaryFallback = false

    private var venueService = VenueService()
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Lifecycle

    override func viewDidLoad() {
        super.viewDidLoad()

        let storedPrimaryCity = UserDefault.shared.primaryCity ?? ""
        primaryCity = storedPrimaryCity.isEmpty
            ? UserDefault.shared.primaryDisplayCity
            : storedPrimaryCity
        selectedCity = storedPrimaryCity
        initialPrimaryCity = storedPrimaryCity
        if persistsFilterSelection {
            selectedFilterCity = selectedFilterCity ?? UserDefault.shared.filterCity
        }
        normalizeFilterSelectionIfNeeded()
        normalizeInitialFilterSelectionIfNeeded()
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

    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        applyFallbackPrimaryCityIfNeeded()
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
        UserDefault.shared.primaryDisplayCity
    }

    func setupTableView() {

        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            SelectLocationTVC.nib,
            forCellReuseIdentifier: SelectLocationTVC.identifier
        )
        tableView.register(
            SelectLocationShimmerCell.self,
            forCellReuseIdentifier: SelectLocationShimmerCell.identifier
        )

        tableView.showsVerticalScrollIndicator = false
        tableView.showsHorizontalScrollIndicator = false
        tableView.rowHeight = 77
        tableView.estimatedRowHeight = 77
        updateEmptyState()
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
                isInitialPrimarySelection ? "Continue" : "Update Location",
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
        normalizedCity(selectedCity) == normalizedCity(initialPrimaryCity)
    }

    func normalizeFilterSelectionIfNeeded() {
        guard persistsFilterSelection else { return }
        guard normalizedCity(selectedFilterCity) == normalizedCity(primaryCity) else {
            return
        }

        selectedFilterCity = nil

        if persistsFilterSelection {
            UserDefault.shared.filterCity = nil
        }
    }

    func normalizeInitialFilterSelectionIfNeeded() {
        guard normalizedCity(initialFilterCity) == normalizedCity(primaryCity) else {
            return
        }

        initialFilterCity = nil
    }

    func normalizedCity(_ city: String?) -> String {
        city?
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .lowercased() ?? ""
    }

    func applyFallbackPrimaryCityIfNeeded() {
        guard isInitialPrimarySelection else { return }
        guard !didApplyInitialPrimaryFallback else { return }
        guard !UserDefault.shared.hasPrimaryLocation else { return }

        let fallbackCity = firstAvailableCity()
        guard !fallbackCity.isEmpty else { return }

        didApplyInitialPrimaryFallback = true
        UserDefault.shared.setPrimaryCity(fallbackCity)
        UserDefault.shared.filterCity = nil
        onSelectPrimaryCity?(fallbackCity)
    }

    func firstAvailableCity() -> String {
        let firstCity = (fullCityList.isEmpty
            ? UserDefault.shared.cachedCityList
            : fullCityList
        )
        .map { $0.value.trimmingCharacters(in: .whitespacesAndNewlines) }
        .first { !$0.isEmpty }

        if let firstCity {
            return firstCity
        }

        let fallbackCity = UserDefault.shared.primaryDisplayCity
            .trimmingCharacters(in: .whitespacesAndNewlines)

        return fallbackCity.isEmpty ? "Chicago" : fallbackCity
    }

    func reloadCityList() {
        tableView.reloadData()
        updateEmptyState()
    }

    func updateEmptyState() {
        let shouldShowEmptyState =
            !isLoadingCityList &&
            displayList.isEmpty &&
            !currentSearchText().isEmpty

        tableView.backgroundView = shouldShowEmptyState ? emptyStateView : nil
    }
}

// MARK: - Actions

extension SelectLocationVC {

    @IBAction func onClickBack(_ sender: Any) {
        AppHaptic.navigation()
        applyFallbackPrimaryCityIfNeeded()
        dismiss(animated: true)
    }

    @IBAction func onClickSearchClosebtn(_ sender: Any) {
        AppHaptic.tap()

        searchTextfeild.text = ""

        closeBtn.isHidden = true

        displayList = fullCityList

        reloadCityList()
    }
    
    @IBAction func onClickEditSearchClosebtn(_ sender: Any) {
        AppHaptic.tap()

        editSearchTextFeild.text = ""

        editSeachCloseBtn.isHidden = true

        displayList = fullCityList

        reloadCityList()
    }

    @IBAction func onClickApply(_ sender: Any) {
        AppHaptic.success()

        let selectedCity = selectedFilterCity?
            .trimmingCharacters(in: .whitespacesAndNewlines)

        let city = persistsFilterSelection &&
            normalizedCity(selectedCity) == normalizedCity(primaryCity)
            ? nil
            : selectedCity

        if persistsFilterSelection {
            UserDefault.shared.filterCity = city
        }
        onSelectFilterCity?(city)

        dismiss(animated: true)
    }
    
    @IBAction func onClickUpdateLocation(_ sender: Any) {

        guard !selectedCity.isEmpty else {
            AppHaptic.error()
            return
        }

        AppHaptic.primaryAction()

        if isInitialPrimarySelection {
            didApplyInitialPrimaryFallback = true
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

            UserDefault.shared.setPrimaryCity(self.selectedCity)

            if UserDefault.shared.filterCity?
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .caseInsensitiveCompare(self.selectedCity) == .orderedSame {
                UserDefault.shared.filterCity = nil
            }

            self.primaryLocationLbl.text =
            self.selectedCity

            self.onSelectPrimaryCity?(self.selectedCity)
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

        reloadCityList()
    }

    func applyCurrentSearch() {
        let searchText = currentSearchText()

        if searchText.isEmpty {
            displayList = fullCityList
        } else {
            displayList = fullCityList.filter {
                $0.value.lowercased()
                    .contains(searchText.lowercased())
            }
        }
    }

    func currentSearchText() -> String {
        let text: String?

        switch mode {
        case .selectCity:
            text = searchTextfeild.text
        case .updatePrimaryLocation:
            text = editSearchTextFeild.text
        }

        return text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    }
}

// MARK: - API

private extension SelectLocationVC {

    func fetchCityList() {
        let cachedCityList = UserDefault.shared.cachedCityList
        guard cachedCityList.isEmpty else {
            fullCityList = cachedCityList
            applyCurrentSearch()
            isLoadingCityList = false
            reloadCityList()
            return
        }

        guard !isLoadingCityList else { return }

        isLoadingCityList = true
        reloadCityList()

        venueService.fetchCityList { [weak self] cityList, isSuccess, errMsg in

            guard let self else {
                return
            }

            DispatchQueue.main.async {
                if isSuccess {
                    self.isLoadingCityList = false
                    self.fullCityList = cityList
                    UserDefault.shared.cachedCityList = cityList
                    self.applyCurrentSearch()
                    self.reloadCityList()
                } else {
                    self.isLoadingCityList = false
                    self.reloadCityList()

                    Alert.showAlertSheet(
                        style: .alert,
                        title: errMsg ?? Constant.String.somethingWrong,
                        message: ""
                    )
                }
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

        if isLoadingCityList {
            return cityShimmerRowCount
        }

        return displayList.count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if isLoadingCityList {
            let cell: SelectLocationShimmerCell = tableView.dequeue(
                withIdentifier: SelectLocationShimmerCell.identifier,
                for: indexPath
            )
            cell.selectionStyle = .none
            cell.startShimmer()
            return cell
        }

        let cell: SelectLocationTVC = tableView.dequeue(
            withIdentifier: SelectLocationTVC.identifier,
            for: indexPath
        )

        let city = displayList[indexPath.row]

        let isSelected: Bool

        switch mode {

        case .selectCity:

            isSelected = normalizedCity(city.value) == normalizedCity(selectedFilterCity)

        case .updatePrimaryLocation:

            isSelected = normalizedCity(city.value) == normalizedCity(selectedCity)
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

        guard !isLoadingCityList else { return }
        guard displayList.indices.contains(indexPath.row) else { return }

        let city = displayList[indexPath.row].value
        AppHaptic.selectionChanged()

        switch mode {

        case .selectCity:
            if normalizedCity(selectedFilterCity) == normalizedCity(city) {

                selectedFilterCity = nil

            } else {

                selectedFilterCity = city
            }

            updateApplyButtonState()

        case .updatePrimaryLocation:

            selectedCity = city

            updateLocationButtonState()
        }

        reloadCityList()
    }
}

private final class SelectLocationShimmerCell: UITableViewCell {

    private let iconContainer = UIView()
    private let iconView = ShimmerViewV3(frame: .zero, lighter: true)
    private let titleView = ShimmerViewV3()
    private let checkView = ShimmerViewV3(frame: .zero, lighter: true)
    private let dividerView = UIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setup()
    }

    required init?(coder: NSCoder) {
        fatalError()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        startShimmer()
    }

    private func setup() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear

        iconContainer.translatesAutoresizingMaskIntoConstraints = false
        iconContainer.backgroundColor = .clear
        iconContainer.layer.cornerRadius = 9
        iconContainer.layer.cornerCurve = .continuous
        iconContainer.layer.borderWidth = 1
        iconContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.04).cgColor
        contentView.addSubview(iconContainer)

        [iconView, titleView, checkView, dividerView].forEach {
            $0.translatesAutoresizingMaskIntoConstraints = false
        }

        [iconView, titleView, checkView].forEach {
            $0.layer.cornerCurve = .continuous
        }

        iconContainer.addSubview(iconView)
        contentView.addSubview(titleView)
        contentView.addSubview(checkView)
        contentView.addSubview(dividerView)

        iconView.layer.cornerRadius = 5
        titleView.layer.cornerRadius = 5
        checkView.layer.cornerRadius = 8
        dividerView.backgroundColor = UIColor.white.withAlphaComponent(0.07)

        NSLayoutConstraint.activate([
            iconContainer.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            iconContainer.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 23),
            iconContainer.widthAnchor.constraint(equalToConstant: 40),
            iconContainer.heightAnchor.constraint(equalToConstant: 40),

            iconView.centerXAnchor.constraint(equalTo: iconContainer.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleView.leadingAnchor.constraint(equalTo: iconContainer.trailingAnchor, constant: 20),
            titleView.centerYAnchor.constraint(equalTo: iconContainer.centerYAnchor),
            titleView.widthAnchor.constraint(equalToConstant: 132),
            titleView.heightAnchor.constraint(equalToConstant: 18),

            checkView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -6),
            checkView.centerYAnchor.constraint(equalTo: titleView.centerYAnchor),
            checkView.widthAnchor.constraint(equalToConstant: 16),
            checkView.heightAnchor.constraint(equalToConstant: 16),

            dividerView.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            dividerView.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            dividerView.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -2),
            dividerView.heightAnchor.constraint(equalToConstant: 1),

            contentView.heightAnchor.constraint(greaterThanOrEqualToConstant: 77)
        ])

        startShimmer()
    }

    func startShimmer() {
        iconView.startShimmer()
        titleView.startShimmer()
        checkView.startShimmer()
    }
}
