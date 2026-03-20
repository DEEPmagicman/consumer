//
//  VenueEventsVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

import UIKit

final class VenueEventsVC: UIViewController, SJSegmentedViewControllerViewSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
    }
    
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        tableView
    }
}

extension VenueEventsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        10
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell: VenueEventTVC = tableView.dequeue(withIdentifier: VenueEventTVC.identifier, for: indexPath)
        return cell
    }
}
