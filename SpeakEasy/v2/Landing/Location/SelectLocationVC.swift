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
    
    private var fullCityList = [MVPCity]()
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
        self.view.applyScreenBgGradient(direction: .bottomToTop)
    }

    @IBAction func onClickBack(_ sender: Any) {
        self.dismiss(animated: false)
    }
    
    @IBAction func onClickSearchClosebtn(_ sender: Any) {
        searchTextfeild.text = ""
        closeBtn.isHidden = true
        displayList = fullCityList
        tableView.reloadData()
    }

    @objc private func textDidChange() {
        let searchText = searchTextfeild.text?
            .trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

        closeBtn.isHidden = searchText.isEmpty

        if searchText.isEmpty {
            displayList = fullCityList
        } else {
            displayList = fullCityList.filter {
                $0.value.lowercased().contains(searchText.lowercased())
            }
        }

        tableView.reloadData()
    }

    private func fetchCityList() {
        mvpPresenter.mvpCityListAPi { [weak self] cityList, isSuccess, errMsg in
            guard let self = self else {
                Loader.hide()
                return
            }
            if isSuccess {
                self.fullCityList = cityList
                self.displayList = cityList

                if !self.userLocationCity.isEmpty,
                   cityList.contains(where: { $0.value == self.userLocationCity }) {
                    self.selectedCity = self.userLocationCity
                }

                self.tableView.reloadData()
            } else {
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
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
        cell.selectionStyle = .none

        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        selectedCity = displayList[indexPath.row].value
        UserDefault.shared.user?.city = selectedCity
        UserDefault.shared.localCity = selectedCity
        tableView.reloadData()
    }
}
