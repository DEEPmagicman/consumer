//
//  MVPVenueListVc.swift
//  SpeakEasy-Consumer
//
//  Created by avi on 26/01/23.
//

import UIKit

class MVPVenueListVc: UIViewController {

    @IBOutlet weak var cityNameLbl: UILabelDeviceClass!
    @IBOutlet weak var venueListTableView: UITableView!
        
     var venuelist = [
        VenuesVIPEventDataSet(imgEventCover: UIImage(named:"HotVenueRemainingBG1"), lblPerformerName: "Bounce Sporting Club", imgBrandLogo: UIImage(named:"HotVenueRemainingLogo1"), isLive: false, isFavourite: false, lblEventFees: "$55", lblEventWaitingTime: "10 mins", lblEventClosingTime: "Closes 2:00 AM",location: "335 N. Dearborn St. California",phoneNumber: "(224) 888-576", upcomingEvents: [TopEventDataSet](), description: "bounceDescription", hours: [HoursDataSet(day: "Monday", time: "4:00 PM - 11:00 PM")])]
    
    override func viewDidLoad() {
        super.viewDidLoad()

        self.venueListTableView.register(UINib(nibName: "venueTableCell", bundle: nil), forCellReuseIdentifier: "venueTableCell")
    }
    
}

extension MVPVenueListVc: UITableViewDataSource, UITableViewDelegate {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.venuelist.count
    }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
            let cell = tableView.dequeueReusableCell(withIdentifier: "venueTableCell", for: indexPath) as! venueTableCell
               let data = self.venuelist[indexPath.row]
            cell.setData(data: data)
            return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        Navigate.to.MVPVenueDetailViewController(self)
    }
}
