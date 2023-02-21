//
//  AllVenues.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 16/09/2022.
//

import UIKit

class AllVenues: BaseController {

    @IBOutlet weak var homeTabCollectionView: UICollectionView!
    @IBOutlet weak var lblCity: UILabelDeviceClass!
    @IBOutlet weak var venueListTableView: UITableView!
    
    var arrTabBarOptions = [TabBarOption(label: Strings.FEATURED.text, index: 0, icon: UIImage(named: "featured"), selectedIcon: nil, isSelected: true),
                            TabBarOption(label: Strings.CITY_VIEWS.text, index: 1, icon: UIImage(named: "cityviews"), selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.ROOFTOP.text, index: 2, icon: UIImage(named: "rooftop"), selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.WATERFRONT.text, index: 3, icon: UIImage(named: "waterfront"), selectedIcon: nil, isSelected: false),
                            TabBarOption(label: Strings.STEAKHOUSE.text, index: 4, icon: UIImage(named: "steakhouse"), selectedIcon: nil, isSelected: false)]

    var selectedIndex = 0
    var venueDelegate = VenuePresenter()
    var venueList = [Venue]()
    var from = 0
    var hasMore = false
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
        fetchAllVenue()
        
    }
    
    private func fetchAllVenue() {
        self.venueDelegate.getVenues(from: self.from) { isSuccess, errMsg, venueList, hasMore in
            if isSuccess {
                for venue in venueList {
                    self.venueList.append(venue)
                }
                if hasMore {
                    self.from = self.venueList.count
                }
                self.venueListTableView.reloadData()
                self.hasMore = hasMore
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }

    }

    
    @IBAction func onBtnChangeLocation(_ sender: UIButton) {
        self.navigationController?.pushViewController(NotificationVC(), animated: true)
    }
    @IBAction func onBtnSearch(_ sender: UIButton) {
        self.navigationController?.pushViewController(Search(), animated: true)
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
}
//MARK: - Helper Methods
extension AllVenues {
    private func setUI(){
        self.registerCells()
        self.lblCity.text = Constants.localizedCity
    }
    private func registerCells(){
        self.homeTabCollectionView.register(UINib(nibName: "TabVenueCVC", bundle: nil), forCellWithReuseIdentifier: "TabVenueCVC")
        self.venueListTableView.register(UINib(nibName: "VenueTVC", bundle: nil), forCellReuseIdentifier: "VenueTVC")
    }
}

extension AllVenues: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrTabBarOptions.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TabVenueCVC", for: indexPath) as! TabVenueCVC
        let data = self.arrTabBarOptions[indexPath.item]
        cell.setData(data: data)
        return cell
    }
}
extension AllVenues: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let height = self.homeTabCollectionView.frame.height
        let width = self.homeTabCollectionView.frame.width / 5
        let size = CGSize(width: width, height: height)
        return size
    }
}

extension AllVenues: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if self.selectedIndex != indexPath.item {
            for index in 0..<self.arrTabBarOptions.count {
                self.arrTabBarOptions[index].isSelected = false
            }
            self.arrTabBarOptions[indexPath.item].isSelected = true
            self.selectedIndex = indexPath.item
            collectionView.reloadData()
            
        }
    }
}

extension AllVenues: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venueList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "VenueTVC", for: indexPath) as! VenueTVC
        let data = self.venueList[indexPath.row]
        cell.selectionStyle = .none
        cell.setDataNew(data: data, seeAll: false)
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        switch indexPath.section {
        case 0:
            return UITableView.automaticDimension
        default:
            return UITableView.automaticDimension
        }
    }
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row ==  venueList.count - 1 {
            if self.hasMore {
                self.fetchAllVenue()
            }
        }
    }
  
}
extension AllVenues: VenueDetailProtocol {
    func didSelect(index: Int) {
        Utility.main.topViewController()?.navigationController?.pushViewController(VenueDetails(), animated: true)
    }
}
