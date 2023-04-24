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
    
    var arrCityList = [MVPCity]()
    var cityListDelegate = MVPPresenter()
    var citySelectionDelegate: CitySelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cityListTableView.register(UINib(nibName: "CitySelectionTableCell", bundle: nil), forCellReuseIdentifier: "CitySelectionTableCell")
        fetchCityList()
    }
    
    private func fetchCityList() {
        Loader.show()
        self.cityListDelegate.mvpCityListAPi() { cityList, isSuccess in
            if isSuccess {
                self.arrCityList = cityList
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
        cell?.lblCity.text = data.value
        cell?.imgCity.isHidden = true
        cell?.containtView.backgroundColor = .clear
        cell?.contentView.backgroundColor = .clear
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserDefault.shared.localCity = arrCityList[indexPath.row].value
        navigationController?.popViewController(animated: true)
        UserDefault.shared.defaultCitySelected = true
        self.citySelectionDelegate?.citySelected(city: arrCityList[indexPath.row].value)
    }
}
