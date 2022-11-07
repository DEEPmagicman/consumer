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
    
    var arrDrinks = [DrinkGroup(drinkType: "Champagne", drinkOne: "Moet Nectar Rose", drinkTwo: "Dom Perignon", drinkThree: "Veuve Brut", drinkFour: "Poema"), DrinkGroup(drinkType: "Vodka", drinkOne: "Titos", drinkTwo: "Grey Goose", drinkThree: "Absolut", drinkFour: "Finlandia"), DrinkGroup(drinkType: "Tequila", drinkOne: "Casamigos", drinkTwo: "Patron Anejo", drinkThree: "Don Julio Blanco", drinkFour: "Don Julio 1942 Magnum"), DrinkGroup(drinkType: "Whiskey", drinkOne: "Jim Beam", drinkTwo: "Jack Daniels", drinkThree: "Crown Royal", drinkFour: "Makers Mark")]

    @IBOutlet weak var tableViewBottleMenue: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setUI()
    }
    @IBAction func onBtnBack(_ sender: UIButton) {
        self.navigationController?.popViewController(animated: true)
    }
    
}
//MARK: - Helper methods
extension BottleMenu {
    private func setUI() {
        registerCell()
    }
    private func registerCell() {
        self.tableViewBottleMenue.register(UINib(nibName: "BottleMenuTVC", bundle: nil), forCellReuseIdentifier: "BottleMenuTVC")
    }
}
//MARK: - UITableViewDelegate
extension BottleMenu: UITableViewDelegate {
    
}
//MARK: - UITableViewDataSource
extension BottleMenu: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrDrinks.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableViewBottleMenue.dequeueReusableCell(withIdentifier: "BottleMenuTVC", for: indexPath) as? BottleMenuTVC else { return UITableViewCell() }
        cell.lblType.text = arrDrinks[indexPath.row].drinkType
        cell.lblDrinkOne.text = arrDrinks[indexPath.row].drinkOne
        cell.lblDrinkTwo.text = arrDrinks[indexPath.row].drinkTwo
        cell.lblDrinkThree.text = arrDrinks[indexPath.row].drinkThree
        cell.lblDrinkFour.text = arrDrinks[indexPath.row].drinkFour
//        cell.setDat(data: true)
        return cell
    }
}
