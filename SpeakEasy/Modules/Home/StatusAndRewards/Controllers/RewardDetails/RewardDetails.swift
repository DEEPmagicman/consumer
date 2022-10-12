//
//  RewardDetails.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit

class RewardDetails: UIViewController {

    @IBOutlet weak var strechyTableView: UITableView!
    var headerView: UIView!
    var kTableHeaderHeight: CGFloat = 0.0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
        self.loadHeaderView()
        
        self.setupStreachyHeaderViewFrames()
        self.updateHeaderView()
        self.strechyTableView.layoutIfNeeded()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnProceedToBookings(_ sender: UIButton) {
        self.navigationController?.pushViewController(TableSelection(), animated: true)
//        AppDelegate.shared.showHome(selectedIndex: 1)
    }
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return UITableView.automaticDimension
    }
}

extension RewardDetails {
    
    func registerCell() {
        self.strechyTableView.register(UINib(nibName: "RewardDetailsStretchyTVC", bundle: nil), forCellReuseIdentifier: "RewardDetailsStretchyTVC")
    }
    private func loadHeaderView() {
        if strechyTableView.tableHeaderView == nil {
            let tableHeaderView  = HeaderViewCustom.instanceFromNib()
            strechyTableView.contentOffset = CGPoint(x: 0, y: -32)
            strechyTableView.tableHeaderView = tableHeaderView
        }
    }
    func setupStreachyHeaderViewFrames() {
        kTableHeaderHeight = self.view.frame.height * 0.4
        strechyTableView.rowHeight = UITableView.automaticDimension
        headerView = strechyTableView.tableHeaderView
        strechyTableView.tableHeaderView = nil
        strechyTableView.addSubview(headerView)
        strechyTableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        strechyTableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
    }
    func updateHeaderView() {
        
        var headerRect = CGRect(x: 0, y: -kTableHeaderHeight, width: strechyTableView.bounds.width, height: kTableHeaderHeight)
        if strechyTableView.contentOffset.y < -kTableHeaderHeight {
            headerRect.origin.y = strechyTableView.contentOffset.y
            headerRect.size.height = -strechyTableView.contentOffset.y
        }
        debugPrint(headerRect)
        if headerView != nil {
            headerView.frame = headerRect
        }
    }
}

extension RewardDetails: UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "RewardDetailsStretchyTVC", for: indexPath) as? RewardDetailsStretchyTVC else { return UITableViewCell() }
        cell.indentationLevel = 2;
        return cell
    }
}

extension RewardDetails: UITableViewDelegate {
    
}
