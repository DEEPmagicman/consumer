//
//  Main.swift
//  SpeakEasy-Consumer
//
//  Created by Mustafa Siddique on 9/6/22.
//

import UIKit
import SwiftUI

struct TableAttributes {
    var tableNumber: String
    var tableStatus: TableStatusType
    var tableCapacity: Int
    var isSelected: Bool
    var timeSlot: String
    var minimumSpend: String
    var leftX: Int
    var topY: Int
}

struct FixValue {
    static let smallHeight = 70
    static let smallWeight = 70
    static let mediumHeight = 70
    static let mediumWeight = 80
    static let largeHeight = 70
    static let largeWeight = 90
    static var scale = 1 // default scale 1 as it is as per data
}

class Main1: UIViewController {
    
    @IBOutlet weak var floorView: UIView!
    @IBOutlet weak var floorViewHeight: NSLayoutConstraint!
    @IBOutlet weak var floorViewWidth: NSLayoutConstraint!
    @IBOutlet weak var floorScrollView: UIScrollView!
    @IBOutlet weak var scrollInsideView: UIView!
    @IBOutlet weak var tableView: UITableView!
    
    var from = ""
    var arrTables = [TableAttributes]()
    
    var mainTable = [TableAttributes(tableNumber: "1",  tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX: 129,topY: 226),
                     TableAttributes(tableNumber: "2", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:195,topY: 226),
                     TableAttributes(tableNumber: "3", tableStatus: .available, tableCapacity: 4, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:261,topY: 226),
                     TableAttributes(tableNumber: "4", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:378,topY: 226),
                     TableAttributes(tableNumber: "5", tableStatus: .none,      tableCapacity: 8, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:550,topY: 226),
                     TableAttributes(tableNumber: "6", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:778,topY: 209),
                     TableAttributes(tableNumber: "7", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:685,topY: 105),
                     TableAttributes(tableNumber: "8", tableStatus: .available, tableCapacity: 3, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:571,topY: 140),
                     TableAttributes(tableNumber: "9", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:129,topY: 444),
                     TableAttributes(tableNumber: "10", tableStatus: .none,      tableCapacity: 9, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:195,topY: 444),
                     TableAttributes(tableNumber: "11", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:261,topY: 444),
                     TableAttributes(tableNumber: "12", tableStatus: .available, tableCapacity: 8, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:327,topY: 444),
                     TableAttributes(tableNumber: "13", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:457,topY: 308),
                     TableAttributes(tableNumber: "14", tableStatus: .available, tableCapacity: 5, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:457,topY: 402),
                     TableAttributes(tableNumber: "15", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:550,topY: 226),
                     TableAttributes(tableNumber: "16", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:550,topY: 391),
                     TableAttributes(tableNumber: "17", tableStatus: .none,      tableCapacity: 3, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:634,topY: 267),
                     TableAttributes(tableNumber: "18", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:634,topY: 329),
                     TableAttributes(tableNumber: "19", tableStatus: .available, tableCapacity: 3, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:634,topY: 391),
                     TableAttributes(tableNumber: "20", tableStatus: .none,      tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:571,topY: 498),
                     TableAttributes(tableNumber: "21", tableStatus: .none,      tableCapacity: 8, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:685,topY: 498),
                     TableAttributes(tableNumber: "22", tableStatus: .available, tableCapacity: 2, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:685,topY: 564),
                     TableAttributes(tableNumber: "23", tableStatus: .available, tableCapacity: 9, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:778,topY: 498),
                     TableAttributes(tableNumber: "24", tableStatus: .available, tableCapacity: 9, isSelected: false, timeSlot: "10PM - 12AM", minimumSpend: "$1200",leftX:778,topY: 585)]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setUI()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        setTable()
        
    }
    
    @IBAction func onBtnProceed(_ sender: UIButtonDeviceClass) {
        Utility.main.topViewController()?.navigationController?.pushViewController(BookingRequests(), animated: true)
    }
}
//MARK: - Helper Methods
extension Main1 {
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
    
    func setTable() {
        
        if from == "main" {
            self.arrTables = mainTable
        } else if from == "lotus" {
            self.arrTables = mainTable
        } else {
            self.arrTables = mainTable
        }
        
        floorScrollView.delegate = self
        floorScrollView.minimumZoomScale = 0.25
        floorScrollView.maximumZoomScale = 5.0
        FixValue.scale = 1
        
        floorViewHeight.constant = CGFloat(671.scaledValue) // max y
        floorViewWidth.constant = CGFloat(875.scaledValue) // max x
        arrTables.forEach { table in
            if let viewTable = ViewRewardTable.instanceFromNib() as? ViewRewardTable {
                let leftX = table.leftX.scaledValue
                let topY = table.topY.scaledValue
                
                viewTable.tag = (Int(table.tableNumber) ?? 0) - 1
                var width = 0
                var height = 0
//
//                switch table.size {
//                case "small":
//                    width = FixValue.smallWeight
//                    height = FixValue.smallHeight
//                case "medium":
//                    width = FixValue.mediumWeight
//                    height = FixValue.mediumHeight
//                case "large":
//                    width = FixValue.largeWeight
//                    height = FixValue.largeHeight
//                default:
//                    break
//                }
                
                // default table height/width as per figma
                height = 62.scaledValue
                width = 62.scaledValue
                
//                switch table.shape {
//                case "circle":
//                    height = width
//                    viewDemo.seatImg.layer.cornerRadius = CGFloat((height - 20) / 2)
////                    viewDemo.seatImg.image = AssestImage.circuleTable
//                case "rectangle":
////                    viewDemo.seatImg.image = AssestImage.recTable
//                    break
//                case "square":
//                    height = width
////                    viewDemo.seatImg.image = AssestImage.squareTable
//                default:
//                    break
//                }
                viewTable.setData(data: table)
                viewTable.frame = CGRect(x: leftX , y: topY , width: width, height: height)
                self.floorView.addSubview(viewTable)
                
                let tap = UITapGestureRecognizer(target: self, action: #selector(self.didSelectTablAt(_:)))
                viewTable.isUserInteractionEnabled = true
                viewTable.addGestureRecognizer(tap)
            }
        }
    }
        
    func upDateView(index: Int) {
        self.floorView.subviews.forEach { view in
            if let view = view as? ViewRewardTable {
                if view.tag == index {
                    view.setData(data: self.arrTables[index])
                }
            }
        }
    }
    
    @objc func didSelectTablAt(_ sender: UITapGestureRecognizer) {
        let tag = sender.view?.tag ?? 0
        let tableStatus = self.arrTables[tag].tableStatus
        if tableStatus == .available {
            for i in 0..<self.arrTables.count {
                self.arrTables[i].isSelected = false
                upDateView(index: i)
            }
           
            self.arrTables[tag].isSelected = !self.arrTables[tag].isSelected
            upDateView(index: tag)
        } else {
            Utility.main.showAlert(message: "This table is not available", title: "")
        }
        
        self.tableView.reloadData()
        self.tableView.scrollToRow(at: IndexPath(row: tag, section: 0), at: .middle, animated: true)
    }
}
//MARK: - UITableViewDataSource
extension Main1: UITableViewDataSource {
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
extension Main1: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let tableStatus = self.arrTables[indexPath.row].tableStatus
        if tableStatus != .available {
            Utility.main.showAlert(message: "This table is not available", title: "")
        }
        else {
            for i in 0..<self.arrTables.count {
                self.arrTables[i].isSelected = false
                upDateView(index: i)
            }
            self.arrTables[indexPath.row].isSelected = true
            upDateView(index: indexPath.row)
            
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


extension Main1: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return scrollInsideView
    }
}
