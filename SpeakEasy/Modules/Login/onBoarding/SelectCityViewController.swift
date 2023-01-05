//
//  SelectCityViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit

final class SelectCityViewController: UIViewController {

    @IBOutlet weak var selectCityInfoLbl: UILabel!
    @IBOutlet weak var selectCityTableView: UITableView!
    @IBOutlet weak var continueBtn: UIButton!
    
    var arrCityList = [CitySelection(name: "Chicago, IL", img: "New York, NY 1"),
                            CitySelection(name: "Cleveland, OH", img: "Miami, FL"),CitySelection(name: "surat", img: "New York, NY 1"),CitySelection(name: "Baroda", img: "New York, NY 1"),CitySelection(name: "Ahmedabad", img: "Miami, FL")]
    var selectedCity = ""
    var onBoardingDelegate = OnBoardingPresenter()
    
    override func viewDidLoad() {
        super.viewDidLoad()

        selectCityInfoLbl.highlightBold(["Enable Location Services"], size: 15, textColor: Constant.Color.primaryColor)
        
        self.selectCityTableView.register(UINib(nibName: "NotificationTVC", bundle: nil), forCellReuseIdentifier: "NotificationTVC")

    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.editUserProfileApi(city: self.selectedCity) { isSuccess,errorMsg  in
            if isSuccess {
                UserDefault.shared.user?.city = self.selectedCity
                Navigate.to.selectVibesVc(self)
            } else {
                if errorMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errorMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
            Loader.hide()
        }
    }
}

extension SelectCityViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrCityList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "NotificationTVC", for: indexPath) as? NotificationTVC
        let data = arrCityList[indexPath.row]
        cell?.setData(data: data)
        cell?.containtView.backgroundColor = .clear
        cell?.contentView.backgroundColor = .clear
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCity = arrCityList[indexPath.row].name
//        Navigate.to.selectVibesVc(self)
    }
    
}
