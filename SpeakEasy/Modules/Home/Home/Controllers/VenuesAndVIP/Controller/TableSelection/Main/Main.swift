//
//  Main.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/6/22.
//

import UIKit
import SwiftUI

//struct TableAttributes {
//    var tableNumber: String
//    var tableStatus: TableStatusType
//    var tableCapacity: Int
//    var isSelected: Bool
//    var timeSlot: String
//    var minimumSpend: String
//    var leftX: Int
//    var topY: Int
//}
//
//struct MainTableCellData {
//    var isSelected: Bool? = false
//    var lblTableNumber : String? = ""
//    var lblNumberOfSeats : String? = ""
//    var lblTimeSlots : String? = ""
//    var lblMinSpend : String? = ""
//}

class Main: UIViewController {
    
    @IBOutlet weak var viewTable9:  UIView!//0
    @IBOutlet weak var viewTable10: UIView!//1
    @IBOutlet weak var viewTable11: UIView!//2
    @IBOutlet weak var viewTable12: UIView!//3
    @IBOutlet weak var viewTable13: UIView!//4
    @IBOutlet weak var viewTable14: UIView!//5
    @IBOutlet weak var viewTable15: UIView!//6
    @IBOutlet weak var viewTable16: UIView!//7
    @IBOutlet weak var viewTable17: UIView!//8
    @IBOutlet weak var viewTable18: UIView!//9
    @IBOutlet weak var viewTable22: UIView!//10
    @IBOutlet weak var viewTable23: UIView!//11
    @IBOutlet weak var viewTable24: UIView!//12
    @IBOutlet weak var viewTable33: UIView!//13
    @IBOutlet weak var viewTable34: UIView!//14
    @IBOutlet weak var viewTable35: UIView!//15
    @IBOutlet weak var viewTable36: UIView!//16
    @IBOutlet weak var viewTable37: UIView!//17
    @IBOutlet weak var viewTable38: UIView!//18
    @IBOutlet weak var viewTable41: UIView!//19
    @IBOutlet weak var viewTable42: UIView!//20
    @IBOutlet weak var viewTable51: UIView!//21
    @IBOutlet weak var viewTableC1: UIView!//22
    
    var arrTables = [TableAttributes(tableNumber: "1",  tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX: 129,topY: 226,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "2", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:195,topY: 226,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "3", tableStatus: .available, tableCapacity: 4, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:261,topY: 226,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "4", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:378,topY: 226,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "5", tableStatus: .none,      tableCapacity: 8, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:550,topY: 226,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "6", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:778,topY: 209,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "7", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:685,topY: 105,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "8", tableStatus: .available, tableCapacity: 3, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:571,topY: 140,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "9", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:129,topY: 444,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "10", tableStatus: .none,      tableCapacity: 9, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:195,topY: 444,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "11", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:261,topY: 444,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "12", tableStatus: .available, tableCapacity: 8, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:327,topY: 444,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "13", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:457,topY: 308,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "14", tableStatus: .available, tableCapacity: 5, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:457,topY: 402,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "15", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:550,topY: 226,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "16", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:550,topY: 391,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "17", tableStatus: .none,      tableCapacity: 3, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:634,topY: 267,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "18", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:634,topY: 329,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "19", tableStatus: .available, tableCapacity: 3, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:634,topY: 391,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "20", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:571,topY: 498,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "21", tableStatus: .none,      tableCapacity: 8, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:685,topY: 498,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "22", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:685,topY: 564,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "23", tableStatus: .available, tableCapacity: 9, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:778,topY: 498,size:"small",shape:"square"),
                     TableAttributes(tableNumber: "24", tableStatus: .available, tableCapacity: 9, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:778,topY: 585,size:"small",shape:"square")]
    
    var table9  = ViewRewardTable()
    var table10 = ViewRewardTable()
    var table11 = ViewRewardTable()
    var table12 = ViewRewardTable()
    var table13 = ViewRewardTable()
    var table14 = ViewRewardTable()
    var table15 = ViewRewardTable()
    var table16 = ViewRewardTable()
    var table17 = ViewRewardTable()
    var table18 = ViewRewardTable()
    var table22 = ViewRewardTable()
    var table23 = ViewRewardTable()
    var table24 = ViewRewardTable()
    var table33 = ViewRewardTable()
    var table34 = ViewRewardTable()
    var table35 = ViewRewardTable()
    var table36 = ViewRewardTable()
    var table37 = ViewRewardTable()
    var table38 = ViewRewardTable()
    var table41 = ViewRewardTable()
    var table42 = ViewRewardTable()
    var table51 = ViewRewardTable()
    var tableC1 = ViewRewardTable()
    
    var isTablePlaced = false
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.placeTables()
    }
    
    @IBAction func onBtnProceed(_ sender: UIButtonDeviceClass) {
        Utility.main.topViewController()?.navigationController?.pushViewController(BookingRequests(), animated: true)
    }
}
//MARK: - Helper Methods
extension Main {
    private func setUI(){
        if #available(iOS 15.0, *) {
            self.tableView.sectionHeaderTopPadding = 0.0
        } else {
            // Fallback on earlier versions
        }
        self.registerCells()
    }
    private func registerCells(){
        self.tableView.register(UINib(nibName: "MainTVC", bundle: nil), forCellReuseIdentifier: "MainTVC")
        self.tableView.register(UINib(nibName: "MainTableTVC", bundle: nil), forCellReuseIdentifier: "MainTableTVC")
    }
    func placeTables() {
        if self.isTablePlaced == false {
            
            let parentProportionalFrame = self.viewTable13.frame
            
            for (index,table) in self.arrTables.enumerated() {
                switch index {
                case 0:
                    self.table9 = self.getTableView(data: table)
                    self.table9.frame = parentProportionalFrame
                    
                    self.table9.btnTable.tag = index
                    self.table9.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable9.addSubview(self.table9)
                case 1:
                    self.table10 = self.getTableView(data: table)
                    self.table10.frame = parentProportionalFrame
                    
                    self.table10.btnTable.tag = index
                    self.table10.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable10.addSubview(self.table10)
                case 2:
                    self.table11 = self.getTableView(data: table)
                    self.table11.frame = parentProportionalFrame
                    
                    self.table11.btnTable.tag = index
                    self.table11.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable11.addSubview(self.table11)
                case 3:
                    self.table12 = self.getTableView(data: table)
                    self.table12.frame = parentProportionalFrame
                    
                    self.table12.btnTable.tag = index
                    self.table12.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable12.addSubview(self.table12)
                case 4:
                    self.table13 = self.getTableView(data: table)
                    self.table13.frame = parentProportionalFrame
                    
                    self.table13.btnTable.tag = index
                    self.table13.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable13.addSubview(self.table13)
                case 5:
                    self.table14 = self.getTableView(data: table)
                    self.table14.frame = parentProportionalFrame
                    
                    self.table14.btnTable.tag = index
                    self.table14.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable14.addSubview(self.table14)
                case 6:
                    self.table15 = self.getTableView(data: table)
                    self.table15.frame = parentProportionalFrame
                    
                    self.table15.btnTable.tag = index
                    self.table15.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable15.addSubview(self.table15)
                case 7:
                    self.table16 = self.getTableView(data: table)
                    self.table16.frame = parentProportionalFrame
                    
                    self.table16.btnTable.tag = index
                    self.table16.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable16.addSubview(self.table16)
                case 8:
                    self.table17 = self.getTableView(data: table)
                    self.table17.frame = parentProportionalFrame
                    
                    self.table17.btnTable.tag = index
                    self.table17.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable17.addSubview(self.table17)
                case 9:
                    self.table18 = self.getTableView(data: table)
                    self.table18.frame = parentProportionalFrame
                    
                    self.table18.btnTable.tag = index
                    self.table18.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable18.addSubview(self.table18)
                case 10:
                    self.table22 = self.getTableView(data: table)
                    self.table22.frame = parentProportionalFrame
                    
                    self.table22.btnTable.tag = index
                    self.table22.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable22.addSubview(self.table22)
                case 11:
                    self.table23 = self.getTableView(data: table)
                    self.table23.frame = parentProportionalFrame
                    
                    self.table23.btnTable.tag = index
                    self.table23.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable23.addSubview(self.table23)
                case 12:
                    self.table24 = self.getTableView(data: table)
                    self.table24.frame = parentProportionalFrame
                    
                    self.table24.btnTable.tag = index
                    self.table24.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable24.addSubview(self.table24)
                case 13:
                    self.table33 = self.getTableView(data: table)
                    self.table33.frame = parentProportionalFrame
                    
                    self.table33.btnTable.tag = index
                    self.table33.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable33.addSubview(self.table33)
                case 14:
                    self.table34 = self.getTableView(data: table)
                    self.table34.frame = parentProportionalFrame
                    
                    self.table34.btnTable.tag = index
                    self.table34.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable34.addSubview(self.table34)
                case 15:
                    self.table35 = self.getTableView(data: table)
                    self.table35.frame = parentProportionalFrame
                    
                    self.table35.btnTable.tag = index
                    self.table35.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable35.addSubview(self.table35)
                case 16:
                    self.table36 = self.getTableView(data: table)
                    self.table36.frame = parentProportionalFrame
                    
                    self.table36.btnTable.tag = index
                    self.table36.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable36.addSubview(self.table36)
                case 17:
                    self.table37 = self.getTableView(data: table)
                    self.table37.frame = parentProportionalFrame
                    
                    self.table37.btnTable.tag = index
                    self.table37.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable37.addSubview(self.table37)
                case 18:
                    self.table38 = self.getTableView(data: table)
                    self.table38.frame = parentProportionalFrame
                    
                    self.table38.btnTable.tag = index
                    self.table38.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable38.addSubview(self.table38)
                case 19:
                    self.table41 = self.getTableView(data: table)
                    self.table41.frame = parentProportionalFrame
                    
                    self.table41.btnTable.tag = index
                    self.table41.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable41.addSubview(self.table41)
                case 20:
                    self.table42 = self.getTableView(data: table)
                    self.table42.frame = parentProportionalFrame
                    
                    self.table42.btnTable.tag = index
                    self.table42.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable42.addSubview(self.table42)
                case 21:
                    self.table51 = self.getTableView(data: table)
                    self.table51.frame = parentProportionalFrame
                    
                    self.table51.btnTable.tag = index
                    self.table51.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTable51.addSubview(self.table51)
                case 22:
                    self.tableC1 = self.getTableView(data: table)
                    self.tableC1.frame = parentProportionalFrame
                    
                    self.tableC1.btnTable.tag = index
                    self.tableC1.btnTable.addTarget(self, action: #selector(self.didSelectTablAt(_:)), for: .touchUpInside)
                    
                    self.viewTableC1.addSubview(self.tableC1)
                default:
                    break
                }
            }
            
            self.isTablePlaced = true
        }
    }
    func getTableView(data: TableAttributes)->ViewRewardTable{
        let table = ViewRewardTable.instanceFromNib() as! ViewRewardTable
        table.setData(data: data)
        return table
    }
    private func setTableStatus(index: Int, updatedTable: TableAttributes){
        switch index {
        case 0:
            self.table9.setData(data: updatedTable)
            
        case 1:
            self.table10.setData(data: updatedTable)
            
        case 2:
            self.table11.setData(data: updatedTable)
            
        case 3:
            self.table12.setData(data: updatedTable)
            
        case 4:
            self.table13.setData(data: updatedTable)
            
        case 5:
            self.table14.setData(data: updatedTable)
            
        case 6:
            self.table15.setData(data: updatedTable)
            
        case 7:
            self.table16.setData(data: updatedTable)
            
        case 8:
            self.table17.setData(data: updatedTable)
            
        case 9:
            self.table18.setData(data: updatedTable)
            
        case 10:
            self.table22.setData(data: updatedTable)
            
        case 11:
            self.table23.setData(data: updatedTable)
            
        case 12:
            self.table24.setData(data: updatedTable)
            
        case 13:
            self.table33.setData(data: updatedTable)
            
        case 14:
            self.table34.setData(data: updatedTable)
            
        case 15:
            self.table35.setData(data: updatedTable)
            
        case 16:
            self.table36.setData(data: updatedTable)
            
        case 17:
            self.table37.setData(data: updatedTable)
            
        case 18:
            self.table38.setData(data: updatedTable)
            
        case 19:
            self.table41.setData(data: updatedTable)
            
        case 20:
            self.table42.setData(data: updatedTable)
            
        case 21:
            self.table51.setData(data: updatedTable)
            
        case 22:
            self.tableC1.setData(data: updatedTable)
            
        default:
            break
        }
    }
    @objc func didSelectTablAt(_ sender: UIButton) {
        let tableStatus = self.arrTables[sender.tag].tableStatus
        if tableStatus == .available {
            for i in 0..<self.arrTables.count {
                self.arrTables[i].isSelected = false
                
                self.setTableStatus(index: i, updatedTable: self.arrTables[i])
            }
            
            self.arrTables[sender.tag].isSelected = !self.arrTables[sender.tag].isSelected
            self.setTableStatus(index: sender.tag, updatedTable: self.arrTables[sender.tag])
        }
        
        self.tableView.reloadData()
        self.tableView.scrollToRow(at: IndexPath(row: sender.tag, section: 0), at: .middle, animated: true)
    }
}
//MARK: - UITableViewDataSource
extension Main: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.arrTables.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "MainTableTVC", for: indexPath) as! MainTableTVC
        let data = self.arrTables[indexPath.row]
        cell.setData(data: data)
        return cell
    }
}
extension Main: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableStatus = self.arrTables[indexPath.row].tableStatus
        if tableStatus != .available {
            Utility.main.showAlert(message: "This table is not available", title: "")
        }
        else {
            for i in 0..<self.arrTables.count {
                self.arrTables[i].isSelected = false
                self.setTableStatus(index: i, updatedTable: self.arrTables[i])
            }
            self.arrTables[indexPath.row].isSelected = true
            self.setTableStatus(index: indexPath.row, updatedTable: self.arrTables[indexPath.row])
            
            DispatchQueue.main.async {
                tableView.reloadData()
            }
        }
    }
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let header = MainHeader.instanceFromNib() as! MainHeader
        return header
    }
    func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
        return 48.0
    }
}
