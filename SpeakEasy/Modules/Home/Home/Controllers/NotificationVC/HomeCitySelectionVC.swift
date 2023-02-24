//
//  NotificationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 8/30/22.
//

import UIKit
struct CitySelection {
        
        var name : String
        var img : String
    }
    
class HomeCitySelectionVC: UIViewController {

    var arrCitySelection = [CitySelection(name: "Chicago, IL", img: "New York, NY 1"),
                            CitySelection(name: "Cleveland, OH", img: "Miami, FL")]
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var lblCity: UILabelDeviceClass!
    @IBOutlet weak var citySkyline: UIImageView!
    
    var cityDelegate = OnBoardingPresenter()
    var arrCityList = [City]()
    var selectedCity = ""
    var from = 0
    var hasMore = false
    var searchText = ""
    var lastSearch = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    
    private func fatchCityList() {
        print(searchText)
        self.cityDelegate.getCityListAPi(from: from, searchText: searchText) { cityList, hasMore, isSuccess in
            if isSuccess {
                for city in cityList {
                    if city.isDeleted == false {
                        self.arrCityList.append(city)
                    }
                }
                if hasMore {
                    self.from = self.arrCityList.count
                }
                self.hasMore = hasMore
//                self.selectCityTableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: "city Not Found", message: "")
            }
            Loader.hide()
        }
    }

    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
    func setUI() {
        tableView.setupPadding()
        self.lblCity.text = Constants.localizedCity
        self.citySkyline.image = UIImage(named: Constants.localizedMap)
        
        
        //Fix this (don't show for now)
//        citySkyline.isHidden = true
        
        self.registerCell()
    }
    
    func registerCell() {
        self.tableView.register(UINib(nibName: "NotificationTVC", bundle: nil), forCellReuseIdentifier: "NotificationTVC")
    }
}
//MARK: - UITableViewDataSource
 extension HomeCitySelectionVC: UITableViewDataSource {
     func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
         return self.arrCitySelection.count
     }
     func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
         guard let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationTVC", for: indexPath) as? NotificationTVC else { return UITableViewCell() }
         cell.selectionStyle = .none
         let data = self.arrCitySelection[indexPath.row]
         cell.setData(data: data)
         return cell
     }
 }
//MARK: - UITableViewDelegate
extension HomeCitySelectionVC: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let city = self.arrCitySelection[indexPath.row].name.components(separatedBy: ",").first
        let cityMap = self.arrCitySelection[indexPath.row].img
        Constants.localizedCity = city ?? ""
        Constants.localizedMap = cityMap
        UserDefault.shared.localCity = city ?? ""
        AppDelegate.shared.changeRootViewController()
    }
    
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        guard let tableView = self.tableView else {return}
        
        let visibleCells = tableView.visibleCells

        if visibleCells.count == 0 {
            return
        }

        guard let topCell = visibleCells.first else {
            return
        }

        for cell in visibleCells {
            cell.contentView.alpha = 1.0
        }

        let cellHeight = topCell.frame.size.height - 1
        let tableViewTopPosition = tableView.frame.origin.y
        
        let topCellPositionInTableView = tableView.rectForRow(at: tableView.indexPath(for: topCell)!)

        let topCellPosition = tableView.convert(topCellPositionInTableView, to: tableView.superview).origin.y

        let modifier: CGFloat = 2.5
        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier

        topCell.contentView.alpha = topCellOpacity
    }
}
