//
//  UpsellTicketVC.swift
//  SpeakEasy-Consumer
//
//  Created by Sanjay on 28/02/24.
//

import UIKit

class UpSellTicketVC: UIViewController {
    
    @IBOutlet weak var ticketTypeTableView: UITableView!
    @IBOutlet weak var continueBtn: UIButton!
    
    private var appClipTickets : [AppClipTicket] = []
    private var isMaxTicketReached = false
    private var maxTicket = 20
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ticketTypeTableView.register(UINib(nibName: "ticketTypeTableViewCell", bundle: nil), forCellReuseIdentifier: "ticketTypeTableViewCell")
        
        // add dummy data
        let newElement = AppClipTicket(id: "abc", name: "Coat Check", price: 10.0,description: "Required for each guest with coat",selectedQuantity:0)
        self.appClipTickets.append(newElement)
        
        let newElement2 = AppClipTicket(id: "abcd", name: "Backpack & bags", price: 15.0 , description: "Required for each guest with backs & bags",selectedQuantity:0)
        self.appClipTickets.append(newElement2)
        
    }
    
    private func updateContinueBtn() {
        if self.appClipTickets.allSatisfy({ $0.selectedQuantity == 0 || $0.selectedQuantity == nil  }) {
            continueBtn.setTitle(Constant.String.skipAndContinueBtnTitle, for: .normal)
        }else{
            continueBtn.setTitle(Constant.String.continueBtnTitle, for: .normal)
        }
    }
    
    @IBAction func onClickBackBtn(_ sender: Any) {
        Navigate.to.back(self)
    }
    @IBAction func onClickContinueBtn(_ sender: Any) {
        
    }
    
}

extension UpSellTicketVC: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return appClipTickets.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ticketTypeTableViewCell", for: indexPath) as! ticketTypeTableViewCell
        cell.ticketTypeLbl.text = appClipTickets[indexPath.row].name
        cell.infoLbl.text = appClipTickets[indexPath.row].description
        cell.ticketPriceLbl.text = "$\(appClipTickets[indexPath.row].price)"
        cell.ticketPlusMinusView.isHidden = !(appClipTickets[indexPath.row].selectedQuantity ?? 0 > 0)
        if let quantity = appClipTickets[indexPath.row].selectedQuantity {
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
            if  appClipTickets[indexPath.row].selectedQuantity == nil || appClipTickets[indexPath.row].selectedQuantity == 0 {
                var quantity = appClipTickets[indexPath.row].selectedQuantity ?? 0
                quantity = quantity + 1
                self.appClipTickets[indexPath.row].selectedQuantity = quantity
            }
            updateContinueBtn()
            ticketTypeTableView.reloadData()
        }
    }
    
    @objc func minusBtnClick(_ sender: UIButton) {
        if let totalTicket = appClipTickets[sender.tag].selectedQuantity {
            if totalTicket > 1 {
                appClipTickets[sender.tag].selectedQuantity = totalTicket - 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else if totalTicket == 1 {
                appClipTickets[sender.tag].selectedQuantity = nil
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            }
        }
    }
    
    @objc func plusBtnClick(_ sender: UIButton) {
        
        if isMaxTicketReached {
            Alert.showToast(Constant.String.maxTicketSelectionReached)
            return
        }
        if let totalTicket = appClipTickets[sender.tag].selectedQuantity {
            if totalTicket < maxTicket {
                appClipTickets[sender.tag].selectedQuantity = totalTicket + 1
                ticketTypeTableView.reloadData()
                updateContinueBtn()
            } else {
                Alert.showToast(Constant.String.maxTicketSelectionReached)
            }
        }
    }
}
