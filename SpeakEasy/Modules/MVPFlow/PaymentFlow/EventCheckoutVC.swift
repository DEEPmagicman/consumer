//
//  EventCheckoutVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 10/07/24.
//

import UIKit

final class EventCheckoutVC: UIViewController {
    
    @IBOutlet weak var bgImage: UIImageView!
    @IBOutlet weak var backBtn: UIButton!
    @IBOutlet weak var eventImage: UIImageView!
    @IBOutlet weak var questionTableView: UITableView!
    @IBOutlet weak var questionTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var ticketTableView: UITableView!
    @IBOutlet weak var ticketTableViewHeight: NSLayoutConstraint!
    @IBOutlet weak var getTicketBtn: UIButton!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var venueNameLbl: UILabel!
    
    var event: Event?
    private var questionHeightObservation: NSKeyValueObservation?
    private var ticketListHeightObservation: NSKeyValueObservation?
    private var isEventQueAnsCollected = false
    private var bookingId = String()
    private var answers = [Any]()
    var eventQuestions = [Questions]()
    private var questionAnswers = [String: Any]()
    var selectedEventTicket: [EventTicket]?
    var venueDetails: ClipVenue?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        ticketTableView.delegate = self
        ticketTableView.dataSource = self
        questionTableView.delegate = self
        questionTableView.dataSource = self
        
        questionTableView.register(UINib(nibName: "EventQuestionTVC", bundle: nil), forCellReuseIdentifier: "EventQuestionTVC")
        questionHeightObservation = questionTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.questionTableViewHeight.constant = self.questionTableView.contentSize.height
            self.questionTableView.layoutIfNeeded()
        }
        
        ticketTableView.register(UINib(nibName: "TicketDetailTVC", bundle: nil), forCellReuseIdentifier: "TicketDetailTVC")
        ticketListHeightObservation = ticketTableView.observe(\.contentSize, options: []) { [weak self] _, _ in
            guard let self = self else { return }
            self.ticketTableViewHeight.constant = self.ticketTableView.contentSize.height
            self.ticketTableView.layoutIfNeeded()
        }
        
        bgImage.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        geteventQuestion()
        getTicketBtn.alpha = 1
        getTicketBtn.isUserInteractionEnabled = true
        titleLbl.text = event?.title ?? "Untitle Event"
        venueNameLbl.text = (event?.customVenue != nil && venueDetails?.venueSettings?.isOrganizer == true) ? "\(event?.customVenue?.name ?? ""), \(event?.customVenue?.address ?? "")" : "\(venueDetails?.name ?? "")"
        dateLbl.text = event?.startDateTime.convertDateFormat(from: .yyyyMMddHHmmss, to: .EEEMMMD, useDayLightSavingTime: true, customTimeZone: event?.venue?.useTimezone ?? "")
        eventImage.sd_setImage(with: URL(string: (event?.flyer?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
    }
    
    @IBAction func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction func onClickGetTicket(_ sender: Any) {
        if !setAnswerData {
            Alert.showAlertSheet(style: .alert, title: "Please fill required answers", message: "")
        } else {
            createFreeBooking()
        }
    }
    
    private func geteventQuestion() {
        Loader.show()
        PaymentPresenter.getEventBookingQuestion(eventUniqueId: event?.uniqueId ?? "") { [weak self] isSuccess, errMsg, questions in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                self.eventQuestions = questions ?? []
                DispatchQueue.main.async {
                    self.questionTableView.reloadData()
                }
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    private func postQueAns() {
        var answers = [[String: Any]]()
        
        _ = questionAnswers.map ({ ans in
            answers.append(["eventQuestionId": ans.key,
                            "answer": ans.value])
        })
        
        Loader.show()
        PaymentPresenter.postEventBookingQueAns(eventUniqueId: event?.uniqueId ?? "", answers: answers, bookingId: bookingId) { [weak self] isSuccess, errMsg in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                Navigate.to.showQRCode(self, booking: nil, bookingId: bookingId, type: .singleTickedEvent)
            } else {
                if errMsg != nil {
                    Alert.showAlertSheet(style: .alert, title: errMsg, message: "")
                } else {
                    Alert.showAlertSheet(style: .alert, title: Constant.String.somethingWrong, message: "")
                }
            }
        }
    }
    
    private func createFreeBooking() {
        Loader.show()
        var tickets = [[String: Any]]()
        selectedEventTicket?.forEach {
            tickets.append(["ticketId": $0.id ?? 0,
                            "ticketQuantity": $0.selectedTicketCount ?? 0])
        }
        PaymentPresenter.createEventFreeBooking(eventId: event?.id ?? "", phone: UserDefault.shared.user?.phone ?? "", userId: UserDefault.shared.user?.id ?? "", tickets: tickets) { [weak self] isSuccess, errMsg, id, massage  in
            guard let self = self else {
                return
            }
            if isSuccess, let id = id {
                self.bookingId = id
                if eventQuestions.count == 0 {
                    Loader.hide()
                    Navigate.to.showQRCode(self, booking: nil, bookingId: self.bookingId, type: .singleTickedEvent)
                } else {
                    postQueAns()
                }
            } else {
                Loader.hide()
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
        
    }
    
    private var setAnswerData: Bool {
        var requiredIndex = [Int]()
        for (index, element) in eventQuestions.enumerated() {
            if !element.isOptional {
                requiredIndex.append(index)
            }
        }
        var requiredEmptyIndex = [Int]()
        for index in requiredIndex {
            if eventQuestions[index].questionType == "MULTI_SELECT" {
                let id = eventQuestions[index].id
                if questionAnswers[id] as? [String] ?? [] == [] { requiredEmptyIndex.append(index) }
            } else if eventQuestions[index].questionType == "SINGLE_SELECT" || eventQuestions[index].questionType == "TEXT" {
                let id = eventQuestions[index].id
                if questionAnswers[id] as? String ?? "" == "" { requiredEmptyIndex.append(index) }
            } else {
                let id = eventQuestions[index].id
                if questionAnswers[id] as? Bool ?? false == false { requiredEmptyIndex.append(index) }
            }
        }
        return requiredEmptyIndex.count == 0 ? true : false
    }
}

extension EventCheckoutVC: UITableViewDelegate, UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if tableView == questionTableView {
            return eventQuestions.count
        } else {
            return selectedEventTicket?.count ?? 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if tableView == questionTableView {
            let cell = tableView.dequeueReusableCell(withIdentifier: "EventQuestionTVC", for: indexPath) as! EventQuestionTVC
            let question = eventQuestions[indexPath.row]
            cell.questionNameLbl.text = "\(question.question) \(question.isOptional == false ? "*" : "")"
            cell.multiSelectView.isHidden = !(question.questionType == "SINGLE_SELECT" || question.questionType == "MULTI_SELECT")
            cell.checkBoxView.isHidden = !(question.questionType == "CHECKBOX")
            cell.textQuestionView.isHidden = !(question.questionType == "TEXT")
            cell.questionView.isHidden = question.questionType == "CHECKBOX"
            cell.checkBoxQuestionLbl.text = question.question
            var qns = [String]()
            question.eventQuestionHasOption?.forEach({ que in
                qns.append(que.option)
            })
            cell.options = qns
            cell.delegate = self
            cell.selectedIndex = indexPath.row
            cell.questionType = question.questionType
            return cell
        } else {
            let cell = tableView.dequeueReusableCell(withIdentifier: "TicketDetailTVC", for: indexPath) as! TicketDetailTVC
            cell.titleLbl.text = selectedEventTicket?[indexPath.row].tierName
            cell.subTitleLbl.text = selectedEventTicket?[indexPath.row].tierDescription
            cell.quantityLbl.text = "\(selectedEventTicket?[indexPath.row].selectedTicketCount ?? 0)x"
            return cell
        }
    }
}

extension EventCheckoutVC: DropDownDelegate {
    func textAns(ans: String, index: Int) {
        let id = eventQuestions[index].id
        questionAnswers[id] = ans
    }
    
    func boolAns(ans: Bool, index: Int) {
        let id = eventQuestions[index].id
        questionAnswers[id] = ans
    }
    
    func multipleAns(ans: [String], index: Int) {
        let id = eventQuestions[index].id
        questionAnswers[id] = ans
    }
}
