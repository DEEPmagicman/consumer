//
//  MVPCitySelectionVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 27/02/23.
//

import UIKit

protocol CitySelectionDelegate: AnyObject {
    func citySelected(city: String)
}

final class MVPCitySelectionVC: UIViewController {

    @IBOutlet weak var cityListTableView: UITableView!
    
    private var cityList = [MVPCity]()
    private var presenter = MVPPresenter()
    weak var citySelectionDelegate: CitySelectionDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()

        cityListTableView.register(UINib(nibName: "CitySelectionTableCell", bundle: nil), forCellReuseIdentifier: "CitySelectionTableCell")
        fetchCityList()
    }
    
    private func fetchCityList() {
        Loader.show()
        presenter.mvpCityListAPi { cityList, isSuccess, errMsg in
            if isSuccess {
                self.cityList = cityList
                self.cityListTableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
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
        cityList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CitySelectionTableCell", for: indexPath) as? CitySelectionTableCell
        let data = cityList[indexPath.row]
        cell?.lblCity.text = data.value
        cell?.imgCity.isHidden = true
        cell?.containtView.backgroundColor = .clear
        cell?.contentView.backgroundColor = .clear
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        UserDefault.shared.localCity = cityList[indexPath.row].value
        navigationController?.popViewController(animated: true)
        UserDefault.shared.defaultCitySelected = true
        self.citySelectionDelegate?.citySelected(city: cityList[indexPath.row].value)
    }
}
