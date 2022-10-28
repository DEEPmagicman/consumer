//
//  All.swift
//  SpeakEasy-Consumer
//
//  Created by Admin on 15/09/2022.
//

import UIKit

class All: BaseController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    var arrayAllEvents = [
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR", lblEventDate: "Saturday, June 18",location: "632 N. Dearborn St."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG2"), lblPerformerName: "Valentino Khan", lblVenueName: "Soundbar", lblEventDate: "Saturday, July 9",location: "586 N. Dearborn St."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG3"), lblPerformerName: "Nathan Scott", lblVenueName: "TAO", lblEventDate: "Thursday, July 7",location: "335 N. Dearborn St."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR", lblEventDate: "Saturday, June 18",location: "586 N. Dearborn St."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR", lblEventDate: "Saturday, June 18",location: "586 N. Dearborn St."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG1"), lblPerformerName: "Ferreck Dawn", lblVenueName: "SPYBAR", lblEventDate: "Saturday, June 18",location: "586 N. Dearborn St."),
        TopEventDataSet(imgEventCover: UIImage(named: "FeaturedEventsBG2"), lblPerformerName: "Valentino Khan", lblVenueName: "Soundbar", lblEventDate: "Saturday, July 9",location: "586 N. Dearborn St.")
    ]
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.registerCell()
        // Do any additional setup after loading the view.
    }

}

extension All {
    private func registerCell(){
        self.collectionView.register(UINib(nibName: "EventCVC", bundle: nil), forCellWithReuseIdentifier: "EventCVC")
    }
}

extension All: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return self.arrayAllEvents.count
    }
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventCVC", for: indexPath) as! EventCVC
        let data = self.arrayAllEvents[indexPath.item]
        cell.setData(data: data)
        return cell
    }
}
extension All: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let width = collectionView.frame.width/2.07
        let size = CGSize(width: width, height: width * 1.43)
        return size
    }
}
