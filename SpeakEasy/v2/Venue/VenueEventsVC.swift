//
//  VenueEventsVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 19/03/26.
//

import UIKit

final class VenueEventsVC: UIViewController, SJSegmentedViewControllerViewSource {
    
    @IBOutlet weak var tableView: UITableView!
    
    var venueId = ""
    private var events: [Event] = []
    private var skip = 0
    private var hasMore = true
    private var isLoading = false
    private var page = 1
    private var isShimmerLoading = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
          tap.cancelsTouchesInView = false
          tableView.addGestureRecognizer(tap)

        getEvents()
        
    }
    
    func viewForSegmentControllerToObserveContentOffsetChange() -> UIView {
        tableView
    }
    
    func getEvents() {
        
        guard !isLoading else { return }
        guard hasMore else { return }
        
        isLoading = true
        
        VenuePresenter.getEventVenues(
            venueId: venueId,
            skip: skip,
            time: "UPCOMING"
        ) { [weak self] isSuccess, errMsg, list, hasMore in
            
            guard let self = self else { return }
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
            
            if isSuccess {
                
                let newItems = list.filter { newEvent in
                    !self.events.contains(where: { $0.id == newEvent.id })
                }
                
                self.events.append(contentsOf: newItems)
                self.skip = self.events.count
                self.hasMore = hasMore
                
                DispatchQueue.main.async {
                    self.stopShimmer()
                }
                
            } else {
                print(errMsg ?? "Error")
            }
        }
    }
    
    private func startShimmer() {
        isShimmerLoading = true
        tableView.reloadData()
    }

    private func stopShimmer() {
        isShimmerLoading = false
        tableView.reloadData()
    }
}

extension VenueEventsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return isShimmerLoading ? 6 : events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: VenueEventTVC = tableView.dequeue(
            withIdentifier: VenueEventTVC.identifier,
            for: indexPath
        )
        
        if isShimmerLoading {
            cell.startShimmer()
        } else {
            let event = events[indexPath.row]
            cell.configure(with: event)
        }
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        guard !isShimmerLoading else { return }
        
        let event = events[indexPath.row]
        Navigate.eventDetailsVC(self, event: event)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        
        let offsetY = scrollView.contentOffset.y
        let contentHeight = scrollView.contentSize.height
        let height = scrollView.frame.size.height
        
        if offsetY > contentHeight - height - 100 {
            getEvents()
        }
    }
    
    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
        let point = gesture.location(in: tableView)
        
        if let indexPath = tableView.indexPathForRow(at: point) {
            let event = events[indexPath.row]
            print("Tapped working ✅")
            Navigate.eventDetailsVC(self, event: event)
        }
    }
}
