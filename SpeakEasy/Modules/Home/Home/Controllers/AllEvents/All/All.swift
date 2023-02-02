////DELETE AT LAST
////  All.swift
////  SpeakEasy-Consumer
////
////  Created by Admin on 15/09/2022.
////
//
//import UIKit
//import SDWebImage
//
//class All: BaseController {
//
//    @IBOutlet weak var collectionView: UICollectionView!
//    
////    var eventDelegate = EventPresenter()
////    var from = 0
////    var hasMore = false
////    var eventList = [Event]()
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
////        self.registerCell()
////        // Do any additional setup after loading the view.
////        self.fetchAllEvent()
//    }
//    
////    private func fetchAllEvent() {
////        self.eventDelegate.getEvents(from: self.from) { isSuccess, errMsg, eventList, hasMore in
////            if isSuccess {
////                for event in eventList {
////                    self.eventList.append(event)
////                }
////                if hasMore {
////                    self.from = self.eventList.count
////                    self.hasMore = hasMore
////                }
////                self.collectionView.reloadData()
////            } else {
////                if errMsg != nil {
////                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
////                } else {
////                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
////                }
////            }
////            Loader.hide()
////        }
////
////    }
//
//}
//
//extension All {
//    private func registerCell(){
//        self.collectionView.register(UINib(nibName: "EventCVC", bundle: nil), forCellWithReuseIdentifier: "EventCVC")
//    }
//}
//
//extension All: UICollectionViewDataSource {
//    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        if Constants.localizedCity == "Chicago" {
//            return Constants.arrayAllEventsChicago.count
//        }else {
////            return Constants.arrayAllEventsCleveland.count
//            return eventList.count
//        }
//    }
//    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
//        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "EventCVC", for: indexPath) as! EventCVC
//        if Constants.localizedCity == "Chicago" {
//            let data = Constants.arrayAllEventsChicago[indexPath.item]
//            cell.setData(data: data)
//            return cell
//        }else {
////            let data = Constants.arrayAllEventsCleveland[indexPath.item]
//            let data = eventList[indexPath.row]
//            let imgUrl = "https://speakeasy-storage.s3.amazonaws.com/\(data.flyer?.key ?? "")"
//            cell.imgEventCover.sd_setImage(with: URL( string: imgUrl), completed: nil)
//            cell.lblPerformerName.text = data.title
//            cell.lblVenueName.text = data.eventType
//            cell.lblEventDate.text = data.date
////            cell.setData(data: data)
//            return cell
//        }
//    }
//    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        if indexPath.row == eventList.count - 1 {
//            if self.hasMore {
//                self.fetchAllEvent()
//            }
//        }
//    }
//    
//    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
//        Navigate.to.eventDetail(self, eventId: eventList[indexPath.row].id )
//    }
//}
//extension All: UICollectionViewDelegateFlowLayout {
//    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
//        let width = collectionView.frame.width/2.07
//        let size = CGSize(width: width, height: width * 1.43)
//        return size
//    }
//}
