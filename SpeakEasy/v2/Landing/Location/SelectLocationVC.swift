//
//  SelectLocationVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 23/12/25.
//

import UIKit

final class SelectLocationVC: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var closeBtn: UIButton!
    @IBOutlet weak var searchTextfeild: UITextField!
    
    private var displayList = [MVPCity]()
    private var selectedCity = ""
    private var presenter = OnBoardingPresenter()
    private var mvpPresenter = MVPPresenter()
    var userLocationCity = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()

        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(SelectLocationTVC.nib, forCellReuseIdentifier: SelectLocationTVC.identifier)
        
        searchTextfeild.addTarget(
             self,
             action: #selector(textDidChange),
             for: .editingChanged
         )

        userLocationCity = UserDefault.shared.localCity
        fetchCityList()
    }

    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickSearchClosebtn(_ sender: Any) {
        searchTextfeild.text = ""
        closeBtn.isHidden = true
        tableView.reloadData()
    }

    
    @objc private func textDidChange() {
        let hasText = !(searchTextfeild.text?.isEmpty ?? true)
        closeBtn.isHidden = !hasText
    }

    
    private func fetchCityList() {
        mvpPresenter.mvpCityListAPi { [weak self] cityList, isSuccess, errMsg in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.displayList = cityList
                if self.userLocationCity != "", cityList.contains(where: { list in
                    list.value == self.userLocationCity
                }) {
                    self.selectedCity = self.userLocationCity
                }
                self.tableView.reloadData()
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
}

extension SelectLocationVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return displayList.count
    }

    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {

        let cell: SelectLocationTVC = tableView.dequeue(
            withIdentifier: SelectLocationTVC.identifier,
            for: indexPath
        )

        let city = displayList[indexPath.row]
        cell.configure(with: city, isSelected: city.value == selectedCity)

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCity = displayList[indexPath.row].value
        UserDefault.shared.user?.city = self.selectedCity
        UserDefault.shared.localCity = self.selectedCity
        tableView.reloadData()
    }
}
