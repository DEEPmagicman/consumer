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
    
    var userLocationCity = ""
    private var arrCityList = [MVPCity]()
    private var displayList = [MVPCity]()
    private var selectedCity = ""
    private var presenter = OnBoardingPresenter()
    private var cityListDelegate = MVPPresenter()
    private var from = 0
    private var hasMore = false
    private var searchText = ""
    private var lastSearch = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        continueBtn.isUserInteractionEnabled = false
        continueBtn.alpha = 0.5
        selectCityInfoLbl.highlightBold([Constant.String.enableLocationServices], size: 15, textColor: Constant.Color.purpleColor)
        
        selectCityTableView.register(UINib(nibName: "CitySelectionTableCell", bundle: nil), forCellReuseIdentifier: "CitySelectionTableCell")
        searchTextField.delegate = self
        searchTextField.addTarget(self, action: #selector(searchFieldTextChange), for: .editingChanged)
        fetchCityList()
    }
    
    private func fetchCityList() {
        cityListDelegate.mvpCityListAPi() { [weak self] cityList, isSuccess in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.arrCityList = cityList
                self.displayList = cityList
                if self.userLocationCity != "", cityList.contains(where: { list in
                    list.value == self.userLocationCity
                }) {
                    self.selectedCity = self.userLocationCity
                    self.continueBtn.isUserInteractionEnabled = true
                    self.continueBtn.alpha = 1
                }
                self.selectCityTableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: "city Not Found", message: "")
            }
            Loader.hide()
        }
        
//        self.presenter.getCityListAPi(from: from, searchText: searchText) { [weak self] cityList, hasMore, isSuccess in
//            guard let self = self else {
//                Loader.hide()
//                return
//            }
//            if isSuccess {
//                for city in cityList {
//                    if city.isDeleted == false {
//                        self.arrCityList.append(city)
//                    }
//                }
//                if hasMore {
//                    self.from = self.arrCityList.count
//                    self.hasMore = hasMore
//                }
//                self.selectCityTableView.reloadData()
//            } else {
//                Alert.showAlertSheet(style: .alert, title: "city Not Found", message: "")
//            }
//            Loader.hide()
//        }
    }
    
    @objc func searchFieldTextChange() {
        // TODO: search for city flow with API check once
        NSObject.cancelPreviousPerformRequests(withTarget: self, selector: #selector(updateSearch), object: lastSearch)
        lastSearch = searchTextField.text ?? ""
        self.perform(#selector(updateSearch), with: lastSearch, afterDelay: 0.5)
    }
    
    @objc private func updateSearch(_ text: String) {
//        self.from = 0
//        self.searchText = text
//        self.arrCityList.removeAll()
//        self.selectCityTableView.reloadData()
//        self.hasMore = false
//        self.fetchCityList()
        if text == "" {
            displayList = arrCityList
        } else {
            displayList = arrCityList.filter { $0.value.lowercased().contains(text.lowercased()) }
        }
        selectCityTableView.reloadData()
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        presenter.editUserProfileApi(city: self.selectedCity, isProfileCompleted: true) { [weak self] isSuccess,errorMsg  in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                UserDefault.shared.user?.city = self.selectedCity
                UserDefault.shared.localCity = self.selectedCity
                UserDefault.shared.isLoggedIn = true
                UserDefault.shared.user?.isProfileCompleted = true
                AppDelegate.shared.changeRootViewController()
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
        displayList.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "CitySelectionTableCell", for: indexPath) as? CitySelectionTableCell
        let data = displayList[indexPath.row]
        cell?.lblCity.text = data.value
        cell?.imgCity.isHidden = true
        if data.value == selectedCity {
            cell?.contentView.backgroundColor = Constant.Color.customGray.withAlphaComponent(0.5)
        } else {
            cell?.containtView.backgroundColor = .clear
            cell?.contentView.backgroundColor = .clear
        }
        cell?.selectionStyle = .none
        return cell ?? UITableViewCell()
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCity = displayList[indexPath.row].value
        selectCityTableView.reloadData()
        continueBtn.isUserInteractionEnabled = true
        continueBtn.alpha = 1
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == displayList.count - 1 {
            if self.hasMore {
                self.fetchCityList()
            }
        }
    }
}
