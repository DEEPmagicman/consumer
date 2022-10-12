//
//  ManageFriends.swift
//  SpeakEasy-Consumer
//
//  Created by Osama on 01/09/2022.
//

import UIKit

class ManageFriends: UIViewController {

    @IBOutlet weak var manageFriendsTableView: UITableView!
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
    }
    
    func registerCell() {
        self.manageFriendsTableView.register(UINib(nibName: "ManageFriendTVC", bundle: nil), forCellReuseIdentifier: "ManageFriendTVC")
    }
}

//MARK: - UITableViewDataSource
extension ManageFriends: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 12
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "ManageFriendTVC", for: indexPath) as? ManageFriendTVC else { return UITableViewCell() }
        return cell
    }
}
//MARK: - UITableViewDelegate
extension ManageFriends: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
//        self.navigationController?.pushViewController(Friends(), animated: true)
    }
}
