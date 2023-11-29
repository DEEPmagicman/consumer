//
//  PastPurchases&VisitsViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 26/12/22.
//

import UIKit

final class PastPurchasesVisitsViewController: UIViewController {

    @IBOutlet private weak var pastPurchasesTableView: UITableView!
    @IBOutlet private weak var zeroCaseView: UIView!

    private var bookings = [Booking]()
    private var isLoading = true
    private var hasMany = false
    var skipValue = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        getPastPurchases()
        pastPurchasesTableView.delegate = self
        pastPurchasesTableView.dataSource = self
        pastPurchasesTableView.register(UINib(nibName: "PurchaseDetailsTVC", bundle: nil), forCellReuseIdentifier: "PurchaseDetailsTVC")
        pastPurchasesTableView.register(UINib(nibName: "FooterView", bundle: nil), forHeaderFooterViewReuseIdentifier: "FooterView")
        pastPurchasesTableView.contentInset = UIEdgeInsets(top: 40, left: 0, bottom: 0, right: 0)
        pastPurchasesTableView.setupPadding()
        pastPurchasesTableView.groupStyleSpacing()
    }
    
    private func getPastPurchases() {
        PaymentPresenter.getPastTicket(skip: skipValue) { [weak self] isSuccess, errMsg, bookings, hasMany in
            guard let self = self else { return }
            if isSuccess {
                self.isLoading = false
                if self.skipValue == 0 {
                    self.bookings.removeAll()
                }
                for booking in bookings {
                    self.bookings.append(booking)
                }
                if hasMany {
                    self.skipValue += 10
                    print("---\(self.skipValue)")
                }
                self.hasMany = hasMany
                self.zeroCaseView.isHidden = !(bookings.count == 0)
                self.pastPurchasesTableView.reloadData()
            }
        }
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
}

extension PastPurchasesVisitsViewController: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        bookings.count
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        358
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "PurchaseDetailsTVC", for: indexPath) as! PurchaseDetailsTVC
        cell.selectionStyle = .none
        if bookings[indexPath.row].eventId == nil {
            if bookings[indexPath.row].isCompedTicket == true, let inviteLink = bookings[indexPath.row].inviteLink {
                cell.eventNameLbl.text = inviteLink.name
                cell.monthLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMM)
                cell.dateLbl.text = inviteLink.date.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .DD)
            } else if bookings[indexPath.row].bookingType == "TABLE_BOOKING" {
                cell.eventNameLbl.text = Constant.String.tableReservation
                cell.dateLbl.text = bookings[indexPath.row].floorPlanTimeSlotBooking?.first?.floorPlanTableTimeSlot.date.convertDateFormat(from: .YYYYMMDD, to: .DD)
                cell.monthLbl.text = bookings[indexPath.row].floorPlanTimeSlotBooking?.first?.floorPlanTableTimeSlot.date.convertDateFormat(from: .YYYYMMDD, to: .MMM)
            } else {
                cell.eventNameLbl.text = Constant.String.liveCoverTicket
                cell.dateLbl.text = bookings[indexPath.row].createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .DD)
                cell.monthLbl.text = bookings[indexPath.row].createdAt.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .MMM)
            }
            cell.bgImage.sd_setImage(with: URL(string: (bookings[indexPath.row].venueObject?.venueAttachment.first?.key ?? "").imageURL))
            cell.venueLogoImageView.sd_setImage(with: URL(string: (bookings[indexPath.row].venueObject?.logo?.key ?? "").imageURL))
            cell.venueLogoImageView.isHidden = false
        } else {
            cell.eventNameLbl.text = bookings[indexPath.row].event?.title ?? "Untitle Event"
            cell.dateLbl.text = bookings[indexPath.row].event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .DD, useDayLightSavingTime: true, customTimeZone: bookings[indexPath.row].venueObject?.useTimezone ?? "")
            cell.monthLbl.text = bookings[indexPath.row].event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .MMM, useDayLightSavingTime: true, customTimeZone: bookings[indexPath.row].venueObject?.useTimezone ?? "")
            cell.bgImage.sd_setImage(with: URL(string: (bookings[indexPath.row].event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
            cell.venueLogoImageView.isHidden = true
        }
        cell.ticketTypeImage.image = bookings[indexPath.row].bookingType == "TABLE_BOOKING" ? UIImage(named: "ic-people-logo") : UIImage(named: "ic-ticket-logo")
        cell.ticketCountLbl.text = "\(bookings[indexPath.row].bookingHasItem.count)"
        cell.cityNameLbl.text = bookings[indexPath.row].venueObject?.name
        cell.setUI()
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Navigate.to.paymentDetailVC(self, booking: bookings[indexPath.row])
    }

//    func scrollViewDidScroll(_ scrollView: UIScrollView) {
//        guard let tableView = self.pastPurchasesTableView else {return}
//
//        let visibleCells = tableView.visibleCells
//
//        if visibleCells.count == 0 {
//            return
//        }
//
//        guard let topCell = visibleCells.first else {
//            return
//        }
//
//        for cell in visibleCells {
//            cell.contentView.alpha = 0.9
//        }
//
//        let cellHeight = topCell.frame.size.height - 1
//        let tableViewTopPosition = tableView.frame.origin.y
//
//        let topCellPositionInTableView = tableView.rectForRow(at: tableView.indexPath(for: topCell)!)
//
//        let topCellPosition = tableView.convert(topCellPositionInTableView, to: tableView.superview).origin.y
//
//        let modifier: CGFloat = 1.5
//        let topCellOpacity = 1.5 - ((tableViewTopPosition - topCellPosition) / cellHeight) * modifier
//
//        topCell.contentView.alpha = topCellOpacity
//    }
    
    func tableView(_ tableView: UITableView, viewForFooterInSection section: Int) -> UIView? {
        let footer = self.pastPurchasesTableView.dequeueReusableHeaderFooterView(withIdentifier: "FooterView") as? FooterView
        footer?.loader.startAnimating()
        return footer
    }
    
    func tableView(_ tableView: UITableView, heightForFooterInSection section: Int) -> CGFloat {
        if isLoading {
            return 50
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
        if indexPath.row == (bookings.count) - 1 && hasMany && isLoading == false {
            isLoading = true
            DispatchQueue.main.async {
                self.pastPurchasesTableView.reloadData()
            }
            getPastPurchases()
        }
    }
}
