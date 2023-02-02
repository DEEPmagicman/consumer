//
//  BottleMenue.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/1/22.
//

import UIKit

struct DrinkGroup {
    var drinkType: String
    var drinkOne: String?
    var drinkTwo: String?
    var drinkThree: String?
    var drinkFour: String?
}

class BottleMenu: UIViewController {
    
    var venueDelegate = VenuePresenter()
    var arrDrinks = [DrinkGroup(drinkType: "Champagne", drinkOne: "Moet Nectar Rose", drinkTwo: "Dom Perignon", drinkThree: "Veuve Brut", drinkFour: "Poema"), DrinkGroup(drinkType: "Vodka", drinkOne: "Titos", drinkTwo: "Grey Goose", drinkThree: "Absolut", drinkFour: "Finlandia"), DrinkGroup(drinkType: "Tequila", drinkOne: "Casamigos", drinkTwo: "Patron Anejo", drinkThree: "Don Julio Blanco", drinkFour: "Don Julio 1942 Magnum"), DrinkGroup(drinkType: "Whiskey", drinkOne: "Jim Beam", drinkTwo: "Jack Daniels", drinkThree: "Crown Royal", drinkFour: "Makers Mark")]
    var drinkList = [BottleCategory]()
    var from = 0

    @IBOutlet weak var tableViewBottleMenue: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
        fetchBottleList()
    }
    
    private func fetchBottleList() {
        self.venueDelegate.getBottleList(venueId: "63d8b439a46f9d979e7a0c1b") { isSuccess, errMsg, bottleList, hasMore in
            if isSuccess {
                for drink in bottleList {
                    self.drinkList.append(drink)
                }
                if hasMore {
                    self.from = self.drinkList.count
                    self.fetchBottleList()
                    return
                }
                self.tableViewBottleMenue.reloadData()
                print(self.drinkList)

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
    
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
//MARK: - Helper methods
extension BottleMenu {
    private func setUI() {
        registerCell()
        self.tableViewBottleMenue.setupPadding()
        self.tableViewBottleMenue.groupStyleSpacing()
    }
    private func registerCell() {
        self.tableViewBottleMenue.register(UINib(nibName: "BottleMenuTVC", bundle: nil), forCellReuseIdentifier: "BottleMenuTVC")
        self.tableViewBottleMenue.register(UINib(nibName: "BottleCategoryHeaderView", bundle: nil), forHeaderFooterViewReuseIdentifier: "BottleCategoryHeaderView")
    }
}
//MARK: - UITableViewDataSource
extension BottleMenu: UITableViewDataSource {
    func numberOfSections(in tableView: UITableView) -> Int {
        return self.drinkList.count
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.drinkList[section].bottleMenu?.count ?? 0
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableViewBottleMenue.dequeueReusableCell(withIdentifier: "BottleMenuTVC", for: indexPath) as? BottleMenuTVC else { return UITableViewCell() }
        cell.lblType.text = self.drinkList[indexPath.section].bottleMenu?[indexPath.row].drinkName
        return cell
    }
}

extension BottleMenu: UITableViewDelegate {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = tableView.dequeueReusableHeaderFooterView(withIdentifier: "BottleCategoryHeaderView") as? BottleCategoryHeaderView
        let data = self.drinkList[section].name
        header?.categoryLbl.text = data
        return header
    }
    
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            return 25
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        return 10
    }
}
