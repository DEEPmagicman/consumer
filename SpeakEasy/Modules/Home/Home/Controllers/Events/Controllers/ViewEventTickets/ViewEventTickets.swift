//
//  ViewEventTickets.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/4/22.
//

import UIKit

class ViewEventTickets: UIViewController {
    
    @IBOutlet weak var viewFirstText: UIStackView!
    @IBOutlet weak var lblFirstTextPlus: UILabelDeviceClass!
    @IBOutlet weak var lblSecondText: UILabelDeviceClass!
    @IBOutlet weak var viewTransactionSummary: UIView!
    @IBOutlet weak var strechyTableView: UITableView!
    @IBOutlet weak var viewBottonSheet: UIView!
    @IBOutlet weak var tableViewBottom: NSLayoutConstraint!
    @IBOutlet weak var btnBuyTickets: UIButtonDeviceClass!
    
    private var toggel = true
    var headerView: UIView!
    var kTableHeaderHeight:CGFloat = 487.0
    var selectedTabAt = 0
    var topEventData: TopEventDataSet?

    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        self.loadHeaderView()
        self.strechyTableView.alpha = 0
        self.setupStreachyHeaderViewFrames()
//        self.updateHeaderView()
        self.strechyTableView.layoutIfNeeded()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.updateHeaderView()
        
        UIView.animate(withDuration: 0.02, delay: 0, options: .curveEaseOut) {
            self.strechyTableView.alpha = 1.0
        } completion: { _ in
            
        }
    }
    
    @IBAction func onBtnBottomSheetLine(_ sender: UIButton) {
        toggel = !toggel
        UIView.animate(withDuration: 0.2, delay: 0, options: UIView.AnimationOptions.curveEaseInOut) {
            self.updatedTransactionSummaryView()
        }
        self.strechyTableView.reloadRows(at: [IndexPath(row: 0, section: 3)], with: .none)
    }
    
    private func updatedTransactionSummaryView() {
        self.viewTransactionSummary.isHidden = toggel
        self.viewFirstText.isHidden = !toggel
        self.lblSecondText.isHidden = toggel
//        self.lblFirstTextPlus.isHidden = !toggel
        let title = toggel ? "Buy Ticket" : "Buy Ticket"
        self.btnBuyTickets.setTitle(title, for: .normal)
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        updateHeaderView()
    }
    
    @IBAction func onBtnProceed(_ sender: UIButtonDeviceClass) {
        let controller = TicketConfirmation()
        controller.screenType = .FromHome
        controller.topEventData = self.topEventData
        self.navigationController?.pushViewController(controller, animated: true)
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnShare(_ sender: UIButton) {
        Utility.main.shareSocialWith(text: "www.SpeakEasy.com")
    }
}
//MARK: - HELPER METHODS
extension ViewEventTickets {
    private func setUI(){
        self.registerCell()
        self.viewTransactionSummary.isHidden = toggel
        self.lblSecondText.isHidden = toggel
    }
    private func registerCell() {
        self.strechyTableView.register(UINib(nibName: "ViewEventTicketConfirmTVC", bundle: nil), forCellReuseIdentifier: "ViewEventTicketConfirmTVC")
        self.strechyTableView.register(UINib(nibName: "SelectedTicketTVC", bundle: nil), forCellReuseIdentifier: "SelectedTicketTVC")
        self.strechyTableView.register(UINib(nibName: "PaymentMethodTVC", bundle: nil), forCellReuseIdentifier: "PaymentMethodTVC")
        self.strechyTableView.register(UINib(nibName: "PaymentTableViewCell", bundle: nil), forCellReuseIdentifier: "PaymentTableViewCell")
    }
    private func loadHeaderView() {
        if strechyTableView.tableHeaderView == nil {
            let tableHeaderView  = ViewEventHeader.instanceFromNib() as! ViewEventHeader
            guard let data = self.topEventData else {return}
            tableHeaderView.setData(data: data)
            strechyTableView.tableHeaderView = tableHeaderView
        }
    }
    private func setupStreachyHeaderViewFrames() {
        strechyTableView.rowHeight = UITableView.automaticDimension
        headerView = strechyTableView.tableHeaderView
        strechyTableView.tableHeaderView = nil
        if headerView != nil {
            strechyTableView.addSubview(headerView)
        }
        strechyTableView.contentInset = UIEdgeInsets(top: kTableHeaderHeight, left: 0, bottom: 0, right: 0)
        strechyTableView.contentOffset = CGPoint(x: 0, y: -kTableHeaderHeight)
    }
    private func updateHeaderView() {
        
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
//MARK: - UITableViewDataSource
extension ViewEventTickets: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 4
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch section {
        case 0:
            return 1
        case 1:
            return 1
        case 2:
            return 1
        default:
            return 1
        }
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "SelectedTicketTVC", for: indexPath) as? SelectedTicketTVC else { return UITableViewCell() }
            return cell
        case 1:
            guard let cell = strechyTableView.dequeueReusableCell(withIdentifier: "ViewEventTicketConfirmTVC", for: indexPath) as? ViewEventTicketConfirmTVC else { return UITableViewCell() }
            return cell
        case 2:
            let cell = tableView.dequeueReusableCell(withIdentifier: "PaymentTableViewCell") as! PaymentTableViewCell
            cell.setUi(isSetting: false)
            return cell
        default:
            return UITableViewCell()
        }
    }
}
//MARK: - UITableViewDelegate
extension ViewEventTickets: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        if indexPath.section == 3 {
            return self.viewBottonSheet.frame.height
        }
        return UITableView.automaticDimension
    }
}
