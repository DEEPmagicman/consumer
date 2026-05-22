//
//  MapViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/05/26.
//

import UIKit

final class SegmentedTabView: UIView {

    
    var onSelectionChanged: ((Int) -> Void)?

    private(set) var selectedIndex: Int = 0 {
        didSet { updateSelection(animated: true) }
    }

    // MARK: - Private UI
    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.distribution = .fillEqually
        sv.alignment = .fill
        sv.translatesAutoresizingMaskIntoConstraints = false
        return sv
    }()

    private let indicatorView: UIView = {
        let v = UIView()
        v.backgroundColor = .white
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private let separatorLine: UIView = {
        let v = UIView()
        v.backgroundColor = UIColor.white.withAlphaComponent(0.12)
        v.translatesAutoresizingMaskIntoConstraints = false
        return v
    }()

    private var buttons: [UIButton] = []
    private var indicatorLeading: NSLayoutConstraint!
    private var indicatorWidth: NSLayoutConstraint!

    private let items: [String]

    // MARK: - Init
    init(items: [String]) {
        self.items = items
        super.init(frame: .zero)
        setup()
    }

    required init?(coder: NSCoder) {
        self.items = []
        super.init(coder: coder)
        setup()
    }

    // MARK: - Setup
    private func setup() {
        addSubview(stackView)
        addSubview(separatorLine)
        addSubview(indicatorView)

        NSLayoutConstraint.activate([
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor),
            stackView.topAnchor.constraint(equalTo: topAnchor),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor),

            separatorLine.leadingAnchor.constraint(equalTo: leadingAnchor),
            separatorLine.trailingAnchor.constraint(equalTo: trailingAnchor),
            separatorLine.bottomAnchor.constraint(equalTo: bottomAnchor),
            separatorLine.heightAnchor.constraint(equalToConstant: 1),

            indicatorView.bottomAnchor.constraint(equalTo: bottomAnchor),
            indicatorView.heightAnchor.constraint(equalToConstant: 2),
        ])

        // Placeholder constraints — updated in layoutSubviews once width is known
        indicatorLeading = indicatorView.leadingAnchor.constraint(equalTo: leadingAnchor)
        indicatorWidth = indicatorView.widthAnchor.constraint(equalToConstant: 44)
        indicatorLeading.isActive = true
        indicatorWidth.isActive = true

        for (i, title) in items.enumerated() {
            let btn = makeButton(title: title, index: i)
            buttons.append(btn)
            stackView.addArrangedSubview(btn)
        }
    }

    private func makeButton(title: String, index: Int) -> UIButton {
        let btn = UIButton(type: .custom)
        btn.tag = index
        btn.addTarget(self, action: #selector(tabTapped(_:)), for: .touchUpInside)

        // Default state — inactive color
        btn.setAttributedTitle(attributedTitle(title, isSelected: false), for: .normal)
        btn.setAttributedTitle(attributedTitle(title, isSelected: true), for: .selected)
        return btn
    }

    private func attributedTitle(_ text: String, isSelected: Bool) -> NSAttributedString {
        let color: UIColor = isSelected ? .white : UIColor(hex: "#737373")
        let font = UIFont(name: "Geist-SemiBold", size: 17)
            ?? UIFont.systemFont(ofSize: 17, weight: .semibold)

        return NSAttributedString(
            string: text,
            attributes: [.foregroundColor: color, .font: font]
        )
    }

    // MARK: - Layout
    override func layoutSubviews() {
        super.layoutSubviews()
        guard !buttons.isEmpty else { return }
        let tabWidth = bounds.width / CGFloat(items.count)
        indicatorWidth.constant = tabWidth
        indicatorLeading.constant = CGFloat(selectedIndex) * tabWidth
    }

    // MARK: - Actions
    @objc private func tabTapped(_ sender: UIButton) {
        guard sender.tag != selectedIndex else { return }
        selectedIndex = sender.tag
        onSelectionChanged?(selectedIndex)
    }

    // MARK: - Update UI
    private func updateSelection(animated: Bool) {
        // Update button selected states
        for btn in buttons {
            btn.isSelected = btn.tag == selectedIndex
        }

        // Slide indicator
        let tabWidth = bounds.width / CGFloat(items.count)
        indicatorLeading.constant = CGFloat(selectedIndex) * tabWidth

        let update = {
            self.layoutIfNeeded()
        }

        if animated {
            UIView.animate(withDuration: 0.25, delay: 0, options: .curveEaseInOut, animations: update)
        } else {
            update()
        }
    }

    // MARK: - Public API
    func selectTab(at index: Int, animated: Bool = true) {
        guard index < items.count else { return }
        if animated {
            selectedIndex = index
        } else {
            selectedIndex = index
            updateSelection(animated: false)
        }
    }
}

class MapViewController: UIViewController {

    @IBOutlet weak var tabView: UIView!
    @IBOutlet weak var tableView: UITableView!

    // MARK: - Tab Bar
    private let segmentedTab = SegmentedTabView(items: ["Venues", "Events"])

    private var selectedIndex: Int = 0

    override func viewDidLoad() {
        super.viewDidLoad()

        setupSegmentedTab()
        setupTableView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.applyScreenBgGradient()
    }
    // MARK: - Setup Segmented Tab

    private func setupSegmentedTab() {
        segmentedTab.translatesAutoresizingMaskIntoConstraints = false
        tabView.addSubview(segmentedTab)

        NSLayoutConstraint.activate([
            segmentedTab.leadingAnchor.constraint(equalTo: tabView.leadingAnchor),
            segmentedTab.trailingAnchor.constraint(equalTo: tabView.trailingAnchor),
            segmentedTab.topAnchor.constraint(equalTo: tabView.topAnchor),
            segmentedTab.bottomAnchor.constraint(equalTo: tabView.bottomAnchor)
        ])

        segmentedTab.onSelectionChanged = { [weak self] index in
            guard let self else { return }

            self.selectedIndex = index
            self.tableView.reloadData()
        }
    }

    // MARK: - Setup TableView

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self

        tableView.register(
            UINib(nibName: "MapVenueTableViewCell", bundle: nil),
            forCellReuseIdentifier: "MapVenueTableViewCell"
        )

        tableView.register(
            UINib(nibName: "MapEventsTableViewCell", bundle: nil),
            forCellReuseIdentifier: "MapEventsTableViewCell"
        )
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    
    @IBAction func onClickFilterbtn(_ sender: Any) {
        Navigate.to.filtersVC(self)
    }
    
    
}

// MARK: - UITableViewDelegate & UITableViewDataSource

extension MapViewController: UITableViewDelegate, UITableViewDataSource {

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 10
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        if selectedIndex == 0 {

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "MapVenueTableViewCell",
                for: indexPath
            ) as? MapVenueTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none

            return cell

        } else {

            guard let cell = tableView.dequeueReusableCell(
                withIdentifier: "MapEventsTableViewCell",
                for: indexPath
            ) as? MapEventsTableViewCell else {
                return UITableViewCell()
            }
            cell.selectionStyle = .none

            return cell
        }
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return UITableView.automaticDimension
    }

    func tableView(
        _ tableView: UITableView,
        estimatedHeightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return 120
    }
}
