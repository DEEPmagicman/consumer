//
//  Messages.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 03/09/2022.
//

import UIKit

class Messages: BaseController {

    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
        self.tableView.register(UINib(nibName: "SenderTVC", bundle: nil), forCellReuseIdentifier: "SenderTVC")
        self.tableView.register(UINib(nibName: "ReceiverTVC", bundle: nil), forCellReuseIdentifier: "ReceiverTVC")
        self.tableView.register(UINib(nibName: "BookingStatusTVC", bundle: nil), forCellReuseIdentifier: "BookingStatusTVC")
        self.tableView.register(UINib(nibName: "BookingRequestTVC", bundle: nil), forCellReuseIdentifier: "BookingRequestTVC")
    }

    
}
extension Messages: UITextFieldDelegate {
    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        self.tableView.layoutSubviews()
        return true
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        self.tableView.layoutSubviews()
    }
}
//MARK: TableView
extension Messages: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.row == 0 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "BookingStatusTVC") as! BookingStatusTVC
            return cell
        }
        if indexPath.row == 1 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "ReceiverTVC") as! ReceiverTVC
            return cell
        }
        if indexPath.row == 2 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "SenderTVC") as! SenderTVC
            return cell
        }
        if indexPath.row == 3 {
            let cell = self.tableView.dequeueReusableCell(withIdentifier: "BookingRequestTVC") as! BookingRequestTVC
            return cell
        }
        return UITableViewCell()
    }
}
