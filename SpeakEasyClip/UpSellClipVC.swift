//
//  UpSellClipVC.swift
//  SpeakEasyClip
//
//  Created by MAC on 05/03/24.
//

import UIKit

final class UpSellClipVC: UIViewController {

    @IBOutlet weak var upSellTitle: UILabel!
    @IBOutlet weak var upSellDescription: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var continueBtn: UIButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        tableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        getUpSellTicket(withLoader: true)
        upSellTitle.text = venue?.venueSettings?.addOnsBookingFeesSettings?.pageTitle ?? "UpSell"
        upSellDescription.text = venue?.venueSettings?.addOnsBookingFeesSettings?.description ?? "-"
    }
    
    var upSellTicket = [UpSellTicket]()
    private var isMaxTicketReached = false
    private var maxTicket = 20
    var venue: ClipVenue?
    
    private func getUpSellTicket(withLoader: Bool = true) {
        guard let url = URL(string: "\(SharedURL.baseURL)/consumer/\(venue?.id ?? "")/add-ons") else { return }
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        
        var param = ["include": "addOns"] as [String: Any]
        param["isAppClipPayment"] = true
        let bodyData = try? JSONSerialization.data(
            withJSONObject: param,
            options: [.prettyPrinted]
        )
        request.addValue("*/*", forHTTPHeaderField: "accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = bodyData
        
        if withLoader {
            AppClipLoader.showLoader(self.view)
        }
        URLSession.shared.dataTask(with: request) { data, respons, error in
            guard let data = data,
                  let json = try? JSONSerialization.jsonObject(with: data, options: []) as? [String : Any] else {
                AppClipLoader.hideLoader()
                return
            }
            let decoder = JSONDecoder()
            guard let venueData = try? JSONSerialization.data(withJSONObject: json, options: .prettyPrinted) else {
                AppClipLoader.hideLoader()
                return
            }
//            let ticketData = venueData ["list"]
//            self.venueDetail = try? decoder.decode([UpSellTicket].self, from: venueData)
//            UserDefaults.standard.setValue(self.venueDetail?.id ?? "", forKey: "venueIdLong")
//            self.setUpUI()
            DispatchQueue.main.async {
//                self.updateContinueBtn(forceRemove: true)
                AppClipLoader.hideLoader()
            }
        }.resume()
    }
    
    @IBAction func onClickContinue(_ sender: Any) {
        
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        navigationController?.popViewController(animated: true)
    }
}

extension UpSellClipVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        tableView.backgroundColor = .black
        return upSellTicket.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
        cell.ticketTypeLbl.text = upSellTicket[indexPath.row].addOns?.name ?? ""
        cell.infoLbl.text = upSellTicket[indexPath.row].addOns?.description ?? ""
        cell.ticketPriceLbl.text = "$\(upSellTicket[indexPath.row].price)"
        cell.ticketPlusMinusView.isHidden = !(upSellTicket[indexPath.row].selectedQuantity ?? 0 > 0)
        if let quantity = upSellTicket[indexPath.row].selectedQuantity {
            cell.totalTicketLbl.text = "\(quantity)"
        }
        cell.plusBtn.alpha = isMaxTicketReached ? 0.5 : 1
        cell.plusBtn.isEnabled = isMaxTicketReached ? false : true
        cell.minusBtn.tag = indexPath.row
        cell.minusBtn.addTarget(self, action: #selector(minusBtnClick), for: .touchUpInside)
        cell.plusBtn.tag = indexPath.row
        cell.plusBtn.addTarget(self, action: #selector(plusBtnClick), for: .touchUpInside)
        cell.selectionStyle = .none
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        if (tableView.cellForRow(at: indexPath) as? ticketTypeTableViewCell) != nil {
            if  upSellTicket[indexPath.row].selectedQuantity == nil || upSellTicket[indexPath.row].selectedQuantity == 0 {
                var quantity = upSellTicket[indexPath.row].selectedQuantity ?? 0
                quantity = quantity + 1
                self.upSellTicket[indexPath.row].selectedQuantity = quantity
            }
//            updateContinueBtn()
            tableView.reloadData()
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = upSellTicket[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                upSellTicket[sender.tag].selectedQuantity = totalTicket - 1
                tableView.reloadData()
//                updateContinueBtn()
            } else if totalTicket == 1 {
                upSellTicket[sender.tag].selectedQuantity = nil
                tableView.reloadData()
//                updateContinueBtn()
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        if isMaxTicketReached {
            return
        }
        if let totalTicket = upSellTicket[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                upSellTicket[sender.tag].selectedQuantity = totalTicket + 1
                tableView.reloadData()
//                updateContinueBtn()
            } else {
                return
            }
        }
    }
}
