//
//  MVPCitySelectionVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 27/02/23.
//

import UIKit

protocol CitySelectionDelegate {
    func citySelected(city: String)
}

class MVPCitySelectionVC: UIViewController {

    @IBOutlet weak var cityListTableView: UITableView!
    
    var arrCityList = [City]()
    var selectedCity = ""
    var onBoardingDelegate = OnBoardingPresenter()
    var from = 0
    var hasMore = false
    var citySelectionDelegate: CitySelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cityListTableView.register(UINib(nibName: "CitySelectionTableCell", bundle: nil), forCellReuseIdentifier: "CitySelectionTableCell")
        fetchCityList()
    }
    
    private func fetchCityList() {
        self.onBoardingDelegate.getCityListAPi(from: from) { cityList, hasMore, isSuccess in
            if isSuccess {
                for city in cityList {
                    if city.isDeleted == false {
                        self.arrCityList.append(city)
                    }
                }
                if hasMore {
                    self.from = self.arrCityList.count
                    self.hasMore = hasMore
                }
                self.cityListTableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: "city Not Found", message: "")
            }
            Loader.hide()
        }
    }


    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension MVPCitySelectionVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        arrCityList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CitySelectionTableCell", for: indexPath) as? CitySelectionTableCell
        let data = arrCityList[indexPath.row]
        cell?.setDataCity(data: data, hideCityImg: true)
        cell?.containtView.backgroundColor = .clear
        cell?.contentView.backgroundColor = .clear
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCity = arrCityList[indexPath.row].name
        navigationController?.popViewController(animated: true)
        self.citySelectionDelegate?.citySelected(city: self.selectedCity)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == arrCityList.count - 1 {
            if self.hasMore {
                self.fetchCityList()
            }
        }
    }
}
