//
//  PremiumSearchVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 16/06/26.
//

import UIKit
import SDWebImage

private struct PremiumSearchEventItem {
    let title: String
    let venueName: String
    let dateText: String
    let placeholder: UIImage?
}

final class PremiumSearchVC: UIViewController {

    private let headerView = PremiumSearchHeaderView()
    private let collectionView: UICollectionView

    private let allSuggestions = [
        "Stanton NYC",
        "Stan House",
        "Station 19"
    ]

    private let venueResult = SearchVenueItem(
        id: "dummy-stanton-nyc",
        name: "Stanton NYC",
        imageURL: nil
    )

    private let allEvents: [PremiumSearchEventItem] = [
        PremiumSearchEventItem(
            title: "Friday",
            venueName: "STANTON NYC",
            dateText: "Apr 18 at 8PM",
            placeholder: UIImage(resource: .premiumExpBg)
        ),
        PremiumSearchEventItem(
            title: "Arodes with Losardt",
            venueName: "STANTON NYC",
            dateText: "Apr 18 at 8PM",
            placeholder: UIImage(resource: .premiumExpBg)
        ),
        PremiumSearchEventItem(
            title: "Anthony Attalla",
            venueName: "STANTON NYC",
            dateText: "May 2 at 10PM",
            placeholder: UIImage(resource: .premiumExpBg)
        ),
        PremiumSearchEventItem(
            title: "Arodes with Losardt",
            venueName: "STANTON NYC",
            dateText: "Apr 18 at 8PM",
            placeholder: UIImage(resource: .premiumExpBg)
        ),
        PremiumSearchEventItem(
            title: "Friday Late Night",
            venueName: "STANTON NYC",
            dateText: "Apr 25 at 11PM",
            placeholder: UIImage(resource: .premiumExpBg)
        ),
        PremiumSearchEventItem(
            title: "Station Sessions",
            venueName: "STATION 19",
            dateText: "May 9 at 9PM",
            placeholder: UIImage(resource: .premiumExpBg)
        )
    ]

    private var filteredSuggestions: [String] = []
    private var filteredEvents: [PremiumSearchEventItem] = []
    private var currentQuery = ""
    private var shouldShowVenue = false
    private var lastCollectionLayoutWidth: CGFloat = 0

    init() {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.showsHeaders = true
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(nibName: nil, bundle: nil)
        layout.delegate = self
    }

    required init?(coder: NSCoder) {
        let layout = PinterestLayout()
        layout.numberOfColumns = 2
        layout.sectionInsets = UIEdgeInsets(top: 0, left: 24, bottom: 34, right: 24)
        layout.interItemSpacing = 14
        layout.lineSpacing = 22
        layout.showsHeaders = true
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        super.init(coder: coder)
        layout.delegate = self
    }

    deinit {
        NotificationCenter.default.removeObserver(self)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        applySearch("")
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        headerView.reloadUser()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        headerView.searchView.focus()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        view.applyScreenBgGradient()
        refreshCollectionLayoutIfNeeded()
    }

    private func setupUI() {
        setupHeader()
        setupCollectionView()
        setupKeyboardObservers()
        setupConstraints()
    }

    private func setupHeader() {
        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.delegate = self
        headerView.searchView.onTextChanged = { [weak self] text in
            self?.applySearch(text)
        }
        view.addSubview(headerView)
    }

    private func setupCollectionView() {
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.showsVerticalScrollIndicator = false
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.alwaysBounceVertical = true
        collectionView.keyboardDismissMode = .interactive
        collectionView.dataSource = self
        collectionView.delegate = self
        collectionView.register(
            OrderCardCollectionCell.self,
            forCellWithReuseIdentifier: OrderCardCollectionCell.identifier
        )
        collectionView.register(
            PremiumSearchHeaderSupplementaryView.self,
            forSupplementaryViewOfKind: UICollectionView.elementKindSectionHeader,
            withReuseIdentifier: PremiumSearchHeaderSupplementaryView.identifier
        )
        view.addSubview(collectionView)
    }

    private func setupKeyboardObservers() {
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillChangeFrame),
            name: UIResponder.keyboardWillChangeFrameNotification,
            object: nil
        )

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }

    private func setupConstraints() {
        NSLayoutConstraint.activate([
            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 10),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            headerView.heightAnchor.constraint(equalToConstant: 40),

            collectionView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 26),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func applySearch(_ text: String) {
        currentQuery = text.trimmingCharacters(in: .whitespacesAndNewlines)
        let lowercasedQuery = currentQuery.lowercased()

        if currentQuery.isEmpty {
            filteredSuggestions = []
            filteredEvents = allEvents
            shouldShowVenue = false
        } else {
            filteredSuggestions = allSuggestions.filter {
                $0.lowercased().contains(lowercasedQuery)
            }
            if currentQuery.count >= 5 {
                filteredSuggestions = []
            }

            shouldShowVenue = venueResult.name.lowercased().contains(lowercasedQuery)

            let matchingEvents = allEvents.filter {
                $0.title.lowercased().contains(lowercasedQuery)
                    || $0.venueName.lowercased().contains(lowercasedQuery)
            }
            filteredEvents = matchingEvents.isEmpty ? allEvents : matchingEvents
        }

        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.reloadData()
            collectionView.layoutIfNeeded()
        }
    }

    private func refreshCollectionLayoutIfNeeded() {
        let width = collectionView.bounds.width
        guard width > 0,
              abs(width - lastCollectionLayoutWidth) > 0.5 else { return }

        lastCollectionLayoutWidth = width
        UIView.performWithoutAnimation {
            collectionView.collectionViewLayout.invalidateLayout()
            collectionView.layoutIfNeeded()
        }
    }

    @objc
    private func keyboardWillChangeFrame(_ notification: Notification) {
        updateCollectionInsetsForKeyboard(notification, isHiding: false)
    }

    @objc
    private func keyboardWillHide(_ notification: Notification) {
        updateCollectionInsetsForKeyboard(notification, isHiding: true)
    }

    private func updateCollectionInsetsForKeyboard(
        _ notification: Notification,
        isHiding: Bool
    ) {
        let userInfo = notification.userInfo
        let duration = userInfo?[UIResponder.keyboardAnimationDurationUserInfoKey] as? TimeInterval ?? 0.25
        let curveRaw = (userInfo?[UIResponder.keyboardAnimationCurveUserInfoKey] as? NSNumber)?.uintValue ?? 0
        let options = UIView.AnimationOptions(rawValue: curveRaw << 16)

        let bottomInset: CGFloat
        if isHiding {
            bottomInset = 0
        } else if let frame = userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect {
            let convertedFrame = view.convert(frame, from: nil)
            bottomInset = max(0, view.bounds.maxY - convertedFrame.minY)
        } else {
            bottomInset = 0
        }

        UIView.animate(withDuration: duration, delay: 0, options: options) {
            self.collectionView.contentInset.bottom = bottomInset
            self.collectionView.verticalScrollIndicatorInsets.bottom = bottomInset
        }
    }

    private var headerHeight: CGFloat {
        var height: CGFloat = 0

        if !filteredSuggestions.isEmpty {
            height += CGFloat(filteredSuggestions.count) * 22
            height += CGFloat(max(filteredSuggestions.count - 1, 0)) * 18
            height += 28
        }

        if shouldShowVenue {
            height += 54
            height += 22
        }

        height += 28
        height += 18

        return max(height, 46)
    }
}

extension PremiumSearchVC: PremiumSearchHeaderViewDelegate {
    func premiumSearchHeaderDidTapProfile(_ view: PremiumSearchHeaderView) {
        if UserDefault.shared.isLoggedIn == true {
            Navigate.to.profileMenuVC(self)
        } else {
            Navigate.to.openPhoneLoginPopup(self)
        }
    }

    func premiumSearchHeaderDidTapMap(_ view: PremiumSearchHeaderView) {
        Navigate.to.gotoMapVC(self)
    }

    func premiumSearchHeaderDidTapSearch(_ view: PremiumSearchHeaderView) {
        headerView.searchView.focus()
    }

    func premiumSearchHeaderDidTapClear(_ view: PremiumSearchHeaderView) {
        applySearch("")
    }
}

extension PremiumSearchVC: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        filteredEvents.count
    }

    func collectionView(
        _ collectionView: UICollectionView,
        cellForItemAt indexPath: IndexPath
    ) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: OrderCardCollectionCell.identifier,
            for: indexPath
        ) as! OrderCardCollectionCell

        guard filteredEvents.indices.contains(indexPath.item) else { return cell }

        let item = filteredEvents[indexPath.item]
        cell.configure(
            OrderCardViewModel(
                imageURL: nil,
                placeholder: item.placeholder,
                badgeText: nil,
                title: item.title,
                subtitle: item.venueName,
                dateText: item.dateText,
                statusText: nil,
                statusBgColor: nil,
                statusTextColor: nil
            )
        )

        return cell
    }

    func collectionView(
        _ collectionView: UICollectionView,
        viewForSupplementaryElementOfKind kind: String,
        at indexPath: IndexPath
    ) -> UICollectionReusableView {
        let header = collectionView.dequeueReusableSupplementaryView(
            ofKind: kind,
            withReuseIdentifier: PremiumSearchHeaderSupplementaryView.identifier,
            for: indexPath
        ) as! PremiumSearchHeaderSupplementaryView

        header.configure(
            suggestions: filteredSuggestions,
            venue: venueResult,
            showsVenue: shouldShowVenue
        )

        header.onSuggestion = { [weak self] suggestion in
            self?.headerView.searchView.setText(suggestion)
        }

        header.onViewVenue = { [weak self] in
            guard let self else { return }
            Navigate.to.eventsListVC(self, venue: self.venueResult)
        }

        return header
    }
}

extension PremiumSearchVC: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        // Dummy search data does not have a full Event model yet.
    }
}

extension PremiumSearchVC: PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat {
        guard filteredEvents.indices.contains(indexPath.item) else {
            return 0.1
        }

        let event = filteredEvents[indexPath.item]
        let imageHeight = width * 1.2
        let titleFont = Constant.Font.geistMedium(size: 15)
        let venueFont = Constant.Font.geistMedium(size: 14)
        let dateFont = Constant.Font.geistMedium(size: 14)

        let titleHeight = event.title.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: titleFont],
            context: nil
        ).height

        let venueHeight = event.venueName.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: venueFont],
            context: nil
        ).height

        let dateHeight = event.dateText.boundingRect(
            with: CGSize(width: width, height: .greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            attributes: [.font: dateFont],
            context: nil
        ).height

        return ceil(imageHeight + 16 + titleHeight + 3 + venueHeight + 10 + dateHeight)
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {
        headerHeight
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        0
    }
}

private final class PremiumSearchHeaderSupplementaryView: UICollectionReusableView {

    private let stackView = UIStackView()
    private let suggestionsStack = UIStackView()
    private let venueView = PremiumSearchVenueResultView()
    private let titleLabel = UILabel()

    var onSuggestion: ((String) -> Void)?
    var onViewVenue: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        onSuggestion = nil
        onViewVenue = nil
    }

    private func setup() {
        backgroundColor = .clear

        stackView.translatesAutoresizingMaskIntoConstraints = false
        stackView.axis = .vertical
        stackView.spacing = 0
        addSubview(stackView)

        suggestionsStack.axis = .vertical
        suggestionsStack.spacing = 18
        stackView.addArrangedSubview(suggestionsStack)

        venueView.onViewVenue = { [weak self] in
            self?.onViewVenue?()
        }
        stackView.addArrangedSubview(venueView)

        titleLabel.text = "Upcoming events"
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 20)
        stackView.addArrangedSubview(titleLabel)

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 24),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -24),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }

    func configure(suggestions: [String], venue: SearchVenueItem, showsVenue: Bool) {
        suggestionsStack.arrangedSubviews.forEach {
            suggestionsStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }

        suggestionsStack.isHidden = suggestions.isEmpty

        suggestions.forEach { suggestion in
            let row = PremiumSearchSuggestionRow()
            row.configure(title: suggestion)
            row.onTap = { [weak self] in
                self?.onSuggestion?(suggestion)
            }
            suggestionsStack.addArrangedSubview(row)
        }

        stackView.setCustomSpacing(suggestions.isEmpty ? 0 : 28, after: suggestionsStack)

        venueView.configure(venue)
        venueView.isHidden = !showsVenue
        stackView.setCustomSpacing(showsVenue ? 22 : 0, after: venueView)
        stackView.setCustomSpacing(18, after: titleLabel)
    }
}

private final class PremiumSearchSuggestionRow: UIControl {

    private let iconView = UIImageView()
    private let titleLabel = UILabel()
    var onTap: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        translatesAutoresizingMaskIntoConstraints = false
        addTarget(self, action: #selector(onPressed), for: .touchUpInside)

        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconView.image = UIImage(resource: .searchIconV3)
        iconView.tintColor = .white
        iconView.contentMode = .scaleAspectFit
        addSubview(iconView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 14)
        addSubview(titleLabel)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 22),
            iconView.leadingAnchor.constraint(equalTo: leadingAnchor),
            iconView.centerYAnchor.constraint(equalTo: centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 18),
            iconView.heightAnchor.constraint(equalToConstant: 18),

            titleLabel.leadingAnchor.constraint(equalTo: iconView.trailingAnchor, constant: 14),
            titleLabel.trailingAnchor.constraint(equalTo: trailingAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: centerYAnchor)
        ])
    }

    func configure(title: String) {
        titleLabel.text = title
    }

    @objc private func onPressed() {
        onTap?()
    }
}

private final class PremiumSearchVenueResultView: UIView {

    private let imageView = UIImageView()
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    private let button = UIButton(type: .system)
    var onViewVenue: (() -> Void)?

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        backgroundColor = .clear

        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 6
        imageView.layer.cornerCurve = .continuous
        addSubview(imageView)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistRegular(size: 14)
        addSubview(titleLabel)

        subtitleLabel.translatesAutoresizingMaskIntoConstraints = false
        subtitleLabel.text = "Venue"
        subtitleLabel.textColor = .white.withAlphaComponent(0.55)
        subtitleLabel.font = Constant.Font.geistRegular(size: 10)
        addSubview(subtitleLabel)

        button.translatesAutoresizingMaskIntoConstraints = false
        button.setTitle("View venue", for: .normal)
        button.setTitleColor(.black, for: .normal)
        button.titleLabel?.font = Constant.Font.geistMedium(size: 10)
        button.backgroundColor = .white
        button.layer.cornerRadius = 14
        button.layer.cornerCurve = .continuous
        button.addTarget(self, action: #selector(onButton), for: .touchUpInside)
        addSubview(button)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 54),

            imageView.leadingAnchor.constraint(equalTo: leadingAnchor),
            imageView.centerYAnchor.constraint(equalTo: centerYAnchor),
            imageView.widthAnchor.constraint(equalToConstant: 40),
            imageView.heightAnchor.constraint(equalToConstant: 40),

            button.trailingAnchor.constraint(equalTo: trailingAnchor),
            button.centerYAnchor.constraint(equalTo: centerYAnchor),
            button.widthAnchor.constraint(equalToConstant: 80),
            button.heightAnchor.constraint(equalToConstant: 28),

            titleLabel.leadingAnchor.constraint(equalTo: imageView.trailingAnchor, constant: 8),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: button.leadingAnchor, constant: -12),
            titleLabel.topAnchor.constraint(equalTo: imageView.topAnchor, constant: 5),

            subtitleLabel.leadingAnchor.constraint(equalTo: titleLabel.leadingAnchor),
            subtitleLabel.trailingAnchor.constraint(equalTo: titleLabel.trailingAnchor),
            subtitleLabel.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 2)
        ])
    }

    func configure(_ item: SearchVenueItem) {
        titleLabel.text = item.name

        if let imageURL = item.imageURL, let url = URL(string: imageURL) {
            imageView.sd_setImage(with: url, placeholderImage: UIImage(named: "newSpeakeasy"))
        } else {
            imageView.image = UIImage(named: "newSpeakeasy") ?? Constant.Icon.uploadImage
        }
    }

    @objc private func onButton() {
        onViewVenue?()
    }
}
