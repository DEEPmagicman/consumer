//
//  SearchAndAddFriend.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 01/09/2022.
//

import UIKit

class SearchAndAddFriend: UIViewController {

    @IBOutlet weak var searchTableView: UITableView!
    @IBOutlet weak var tfSearch: UITextField!
    @IBOutlet weak var searchResultText: UILabelDeviceClass!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
        self.tfSearch.delegate = self
    }
    
    @IBAction func onBtnCancel(_ sender: UIButton) {
        self.tfSearch.text = nil
    }
    func registerCell() {
        self.searchTableView.register(UINib(nibName: "SearchAndAddTVC", bundle: nil), forCellReuseIdentifier: "SearchAndAddTVC")
    }
}

//MARK: - UITableViewDataSource
extension SearchAndAddFriend: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 12
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "SearchAndAddTVC", for: indexPath) as? SearchAndAddTVC else { return UITableViewCell() }
        return cell
    }
}
//MARK: - UITableViewDelegate
extension SearchAndAddFriend: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    }
}

extension SearchAndAddFriend: UITextFieldDelegate {
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.searchResultText.text = "Results for \(textField.text ?? "")"
    }
}
