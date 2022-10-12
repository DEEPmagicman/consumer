//
//  BottleMenue.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/1/22.
//

import UIKit

class BottleMenu: UIViewController {

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
        return 8
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableViewBottleMenue.dequeueReusableCell(withIdentifier: "BottleMenuTVC", for: indexPath) as? BottleMenuTVC else { return UITableViewCell() }
//        cell.setDat(data: true)
        return cell
    }
}
