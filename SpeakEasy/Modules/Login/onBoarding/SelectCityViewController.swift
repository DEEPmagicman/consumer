//
//  SelectCityViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 12/12/22.
//

import UIKit

final class SelectCityViewController: UIViewController, UITextFieldDelegate {

    @IBOutlet weak var selectCityInfoLbl: UILabel!
    @IBOutlet weak var selectCityTableView: UITableView!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var searchTextField: UITextField!
    
    var arrCityList = [City]()
    var selectedCity = ""
    var onBoardingDelegate = OnBoardingPresenter()
    var from = 0
    var hasMore = false
    var searchText = ""
    var lastSearch = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        selectCityInfoLbl.highlightBold(["Enable Location Services"], size: 15, textColor: Constant.Color.primaryColor)
        
        self.selectCityTableView.register(UINib(nibName: "NotificationTVC", bundle: nil), forCellReuseIdentifier: "NotificationTVC")
        self.searchTextField.delegate = self
        self.searchTextField.addTarget(self, action: #selector(searchFieldTextChange), for: .editingChanged)
        fatchCityList()

    }
    
    private func fatchCityList() {
        print(searchText)
        self.onBoardingDelegate.getCityListAPi(from: from, searchText: searchText) { cityList, hasMore, isSuccess in
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
                self.selectCityTableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: "city Not Found", message: "")
            }
            Loader.hide()
        }
    }
    
    @objc func searchFieldTextChange() {
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateSearch), object: lastSearch)
             lastSearch = searchTextField.text ?? ""
             self.perform(#selector(updateSearch), with: lastSearch, afterDelay: 0.5)
    }
    
    @objc private func updateSearch(_ text: String) {
        self.from = 0
        self.searchText = text
        self.arrCityList.removeAll()
        self.selectCityTableView.reloadData()
        self.hasMore = false
        self.fatchCityList()
        
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        self.onBoardingDelegate.editUserProfileApi(city: self.selectedCity) { isSuccess,errorMsg  in
            if isSuccess {
                UserDefault.shared.user?.city = self.selectedCity
                Navigate.to.connectSocialMediaVc(self)
//                Navigate.to.selectVibesVc(self)
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
        cell?.setDataCity(data: data)
        cell?.containtView.backgroundColor = .clear
        cell?.contentView.backgroundColor = .clear
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.selectedCity = arrCityList[indexPath.row].name
//        Navigate.to.selectVibesVc(self)
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == arrCityList.count - 1 {
            if self.hasMore {
                self.fatchCityList()
            }
        }
    }
    
}
