//
//  ArtistVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit

final class ArtistDetailsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var segmentView: UIView!

    private var upcomingEvents: [String] = []
    private var pastEvents: [String] = []

    private let segmentControl = SSSegmentedControl()

    enum SegmentType: Int {
        case upcoming = 0
        case past = 1
    }

    private var selectedSegment: SegmentType = .upcoming

    override func viewDidLoad() {
        super.viewDidLoad()

        setupTableView()
        setupSegmentControl()
        loadDummyData()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()

        segmentView.layer.cornerRadius = segmentView.bounds.height / 2
        segmentView.clipsToBounds = true

        segmentControl.layer.cornerRadius = segmentView.bounds.height / 2
        segmentControl.clipsToBounds = true
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.showsVerticalScrollIndicator = false

        tableView.register(
            VenueEventTVC.nib,
            forCellReuseIdentifier: VenueEventTVC.identifier
        )
    }

    private func setupSegmentControl() {
        segmentControl.translatesAutoresizingMaskIntoConstraints = false
        segmentView.addSubview(segmentControl)

        NSLayoutConstraint.activate([
            segmentControl.topAnchor.constraint(equalTo: segmentView.topAnchor),
            segmentControl.leadingAnchor.constraint(equalTo: segmentView.leadingAnchor),
            segmentControl.trailingAnchor.constraint(equalTo: segmentView.trailingAnchor),
            segmentControl.bottomAnchor.constraint(equalTo: segmentView.bottomAnchor)
        ])

        segmentControl.numberOfSegments = 2
        segmentControl.segmentsTitle = "Upcoming,Past"
        segmentControl.currentIndex = 0
        segmentControl.buttonPadding = 4

        segmentControl.backgroundColor = UIColor.white.withAlphaComponent(0.1)
        segmentControl.currentIndexBackgroundColor = UIColor.white.withAlphaComponent(0.2)
        segmentControl.currentIndexTitleColor = .white
        segmentControl.otherIndexTitleColor = .lightGray

        segmentControl.didTapSegment = { [weak self] index in
            guard let self = self else { return }

            self.selectedSegment = SegmentType(rawValue: index) ?? .upcoming
            self.tableView.reloadData()
        }
    }

    private func loadDummyData() {
        upcomingEvents = [
            "E11EVEN HALLOWEEN WEEK FT FAT JOE LIVE",
            "SUMMER NIGHT PARTY",
            "LATIN VIBES LIVE"
        ]

        pastEvents = [
            "RETRO NIGHT LIVE",
            "DJ FEST 2025",
            "FRIDAY BLACKOUT"
        ]

        tableView.reloadData()
    }

    private func currentEvents() -> [String] {
        switch selectedSegment {
        case .upcoming:
            return upcomingEvents
        case .past:
            return pastEvents
        }
    }

    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }

    @IBAction func onClickShareBtn(_ sender: Any) {
        // Share action
    }
}

extension ArtistDetailsVC: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return currentEvents().count
    }

    func tableView(
        _ tableView: UITableView,
        cellForRowAt indexPath: IndexPath
    ) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: VenueEventTVC.identifier,
            for: indexPath
        ) as! VenueEventTVC

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let event = currentEvents()[indexPath.row]
        print("Event:", event)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = currentEvents()[indexPath.row]
        print("Selected event:", event)
    }

    func tableView(
        _ tableView: UITableView,
        heightForRowAt indexPath: IndexPath
    ) -> CGFloat {
        return UITableView.automaticDimension
    }
}
