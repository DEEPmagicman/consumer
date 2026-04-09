//
//  ArtistVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 09/04/26.
//

import UIKit

final class ArtistDetailsVC: UIViewController {

    @IBOutlet weak var tableView: UITableView!

    private var upcomingEvents: [String] = []
    private var pastEvents: [String] = []

    override func viewDidLoad() {
        super.viewDidLoad()
        setupTableView()
        loadDummyData()
    }

    private func setupTableView() {
        tableView.delegate = self
        tableView.dataSource = self
        tableView.backgroundColor = .clear
        tableView.separatorStyle = .none
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
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

    private func eventFor(_ indexPath: IndexPath) -> String {
        if indexPath.section == 0 {
            return upcomingEvents[indexPath.row]
        } else {
            return pastEvents[indexPath.row]
        }
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickShareBtn(_ sender: Any) {
    }
    
    
}

extension ArtistDetailsVC: UITableViewDelegate, UITableViewDataSource {

    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return upcomingEvents.count
        case 1:
            return pastEvents.count
        default:
            return 0
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell = tableView.dequeueReusableCell(
            withIdentifier: VenueEventTVC.identifier,
            for: indexPath
        ) as! VenueEventTVC

        cell.selectionStyle = .none
        cell.backgroundColor = .clear

        let event = eventFor(indexPath)

        return cell
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let event = eventFor(indexPath)
        print("Selected event: \(event)")
    }

    func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        switch section {
        case 0:
            return upcomingEvents.isEmpty ? nil : "Upcoming Events"
        case 1:
            return pastEvents.isEmpty ? nil : "Past Events"
        default:
            return nil
        }
    }

    func tableView(_ tableView: UITableView, willDisplayHeaderView view: UIView, forSection section: Int) {
        guard let header = view as? UITableViewHeaderFooterView else { return }
        header.textLabel?.textColor = .white
        header.textLabel?.font = UIFont.systemFont(ofSize: 18, weight: .semibold)
        header.contentView.backgroundColor = .clear
    }

    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        if section == 0 && upcomingEvents.isEmpty { return 0.01 }
        if section == 1 && pastEvents.isEmpty { return 0.01 }
        return 36
    }

    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 8
    }
}
