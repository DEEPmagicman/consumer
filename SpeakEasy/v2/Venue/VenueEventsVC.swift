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
    private var shimmerView: VenueEventsShimmerView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(VenueEventTVC.nib, forCellReuseIdentifier: VenueEventTVC.identifier)
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap))
          tap.cancelsTouchesInView = false
          tableView.addGestureRecognizer(tap)

        showShimmer()
        getEvents()
        
    }
    
    private func showShimmer() {
        let shimmer = VenueEventsShimmerView(frame: tableView.bounds)
        tableView.addSubview(shimmer)
        shimmer.start()
        shimmerView = shimmer
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
                self.shimmerView?.stop()
                self.tableView.reloadData()
            }
            
            if isSuccess {
                
                let newItems = list.filter { newEvent in
                    !self.events.contains(where: { $0.id == newEvent.id })
                }
                
                self.events.append(contentsOf: newItems)
                self.skip = self.events.count
                self.hasMore = hasMore
                
            } else {
                print(errMsg ?? "Error")
            }
        }
    }
}

extension VenueEventsVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return events.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell: VenueEventTVC = tableView.dequeue(
            withIdentifier: VenueEventTVC.identifier,
            for: indexPath
        )
        let event = events[indexPath.row]
        cell.configure(with: event)
        
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
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

import UIKit

final class VenueEventsShimmerView: UIView {
    
    private var shimmerViews: [ShimmerView] = []
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }
    
    private func make(_ frame: CGRect, corner: CGFloat = 10) {
        let v = ShimmerView(frame: frame)
        v.layer.cornerRadius = corner
        v.clipsToBounds = true
        addSubview(v)
        shimmerViews.append(v)
    }
    
    private func setupUI() {
        let width = UIScreen.main.bounds.width
        
        var y: CGFloat = 10
        
        for _ in 0..<6 {
            
            // image
            make(CGRect(x: 16, y: y, width: 80, height: 80), corner: 12)
            
            // title
            make(CGRect(x: 110, y: y + 10, width: width - 140, height: 16))
            
            // subtitle
            make(CGRect(x: 110, y: y + 35, width: width - 180, height: 14))
            
            // location
            make(CGRect(x: 110, y: y + 55, width: width - 200, height: 14))
            
            y += 100
        }
    }
    
    func start() {
        shimmerViews.forEach { $0.startAnimating() }
    }
    
    func stop() {
        shimmerViews.forEach { $0.stopAnimating() }
        removeFromSuperview()
    }
}
