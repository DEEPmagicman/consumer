//
//  Search.swift
//  SpeakEasy-Consumer
//
//  Created by M.Usman Bin Rehan on 05/09/2022.
//

import UIKit

class Search: BaseController {

    var arrayHeaders = [HeaderOption(label: Strings.VENUES.text, icon: nil),
                        HeaderOption(label: Strings.EVENTS.text, icon: nil)]
    
    var hasVenues = true
    var hasEvents = true
    
    @IBOutlet weak var tfSeach: UITextFieldDeviceClass!
    @IBOutlet weak var lblSearchResultsFor: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblNoResultFoundFor: UILabelDeviceClass!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        // Do any additional setup after loading the view.
    }
    @IBAction func onTfSearch(_ sender: UITextField) {
        let searchText = sender.text ?? ""
        
        if searchText.isEmpty {
            self.resetSearchVenues()
            self.resetSearchEvents()
            self.tableView.alpha = 0.0
        }
        else {
            self.tableView.alpha = 1.0
            self.searchVenues()
            self.searchEvents()
        }
    }
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    @IBAction func onBtnNotification(_ sender: UIButton) {
        self.navigationController?.pushViewController(NotificationCitySelection(), animated: true)
    }
}
extension Search {
    private func setUI(){
        tableView.groupStyleSpacing()
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        self.registerCells()
    }
    private func registerCells(){
        self.tableView.register(UINib(nibName: "HotVenuesTVC", bundle: nil), forCellReuseIdentifier: "HotVenuesTVC")
        self.tableView.register(UINib(nibName: "AllEventsTVC", bundle: nil), forCellReuseIdentifier: "AllEventsTVC")
        self.tableView.register(UINib(nibName: "NoResultFoundTVC", bundle: nil), forCellReuseIdentifier: "NoResultFoundTVC")
    }
    private func searchVenues(){
        guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? HotVenuesTVC else {return}
        cell.searchText = self.tfSeach.text ?? ""
        cell.searchVenue()
        self.hasVenues = cell.hasVenue
        self.tableView.reloadData()
    }
    private func searchEvents(){
        guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AllEventsTVC else {return}
        cell.searchText = self.tfSeach.text ?? ""
        cell.searchEvent()
        
        self.hasEvents = cell.hasEvent
        self.tableView.reloadData()
    }
    
    private func resetSearchVenues(){
        guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 0)) as? HotVenuesTVC else {return}
        cell.searchText = ""
        cell.searchVenue()
        
        self.hasVenues = true
        self.tableView.reloadData()
    }
    private func resetSearchEvents(){
        guard let cell = self.tableView.cellForRow(at: IndexPath(row: 0, section: 1)) as? AllEventsTVC else {return}
        cell.searchText = ""
        cell.searchEvent()
        
        self.hasEvents = true
        self.tableView.reloadData()
    }
}
extension Search: UITextFieldDelegate {
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        let searchedText = textField.text ?? ""
        
        if searchedText.isEmpty {
            self.lblSearchResultsFor.text = nil
            
            self.resetSearchVenues()
            self.resetSearchEvents()
        }
        else {
            self.lblSearchResultsFor.text = "\(Strings.SEARCH_RESULTS.text): \"\(textField.text ?? "")\""
        }

        return true
    }
}
extension Search: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 3
    }
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 1
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch indexPath.section {
        case 0:
            let cell = tableView.dequeueReusableCell(withIdentifier: "HotVenuesTVC", for: indexPath) as! HotVenuesTVC
            return cell
        case 1:
            let cell = tableView.dequeueReusableCell(withIdentifier: "AllEventsTVC", for: indexPath) as! AllEventsTVC
            cell.tag = 0
            cell.viewSeperator.isHidden = true
            return cell
        default:
            let cell = tableView.dequeueReusableCell(withIdentifier: "NoResultFoundTVC", for: indexPath) as! NoResultFoundTVC
            let searchedFor = self.tfSeach.text ?? ""
            cell.setData(hasVenues: self.hasVenues, hasEvents: self.hasEvents, searchedFor: searchedFor)
            return cell
        }
    }
}
extension Search: UITableViewDelegate {
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            let height = tableView.frame.height * 0.6
            return self.hasVenues ? height:0.0
        case 1:
            let height = tableView.frame.height * 0.36
            return self.hasEvents ? height:0.0
        default:
            if !self.hasVenues || !self.hasEvents {
                let height = tableView.frame.height * 0.36
                return height
            }
            else {
                return 0.0
            }
        }
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        switch section {
        case 0:
            return self.hasVenues ? 52.0:0.0
        case 1:
            return self.hasEvents ? 52.0:0.0
        default:
            return 0.0
        }
    }
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        if section != 2 {
            let header = HeaderView.instanceFromNib() as! HeaderView
            let data = self.arrayHeaders[section]
            header.setData(data: data)
            return header
        }
        return nil
    }
}
