//
//  TableSeatingViewController.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 17/02/26.
//

import UIKit

class TableSeatingViewController: UIViewController {

    @IBOutlet weak var tableName: UILabel!
    @IBOutlet weak var tableDetailLbl: UILabel!
    @IBOutlet weak var tableDescriptionLbl: UILabel!
    @IBOutlet weak var guestAndTimeLbl: UILabel!
    @IBOutlet weak var maxiMumGuestLbl: UILabel!
    @IBOutlet weak var miniMumAmountLbl: UILabel!
    @IBOutlet weak var feesLbl: UILabel!
    @IBOutlet weak var increaseBtn: UIButton!
    @IBOutlet weak var decreaseBtn: UIButton!
    @IBOutlet weak var timeCollectionView: UICollectionView!
    @IBOutlet weak var timeCollectionViewHeight: NSLayoutConstraint!
    @IBOutlet weak var selectedTimeLbl: UILabel!
    @IBOutlet weak var timeCollectionViewParentView: UIView!
    @IBOutlet weak var inquireView: UIView!
    
    var seatingArea: SeatingArea?

    private var currentGuestCount: Int = 1
    private var timeSlots: [String] = []
    private var selectedIndex: Int = 0
    
    let infoTextAttributes: [NSAttributedString.Key: Any] = [
        .font: AppFont.font(weight: .regular, size: 12),
        .foregroundColor: UIColor(hex: "#D2D5DB")
    ]
    
    func makeIconAttachment(systemName: String) -> NSTextAttachment {
        let attachment = NSTextAttachment()
        attachment.image = UIImage(systemName: systemName)?
            .withTintColor(UIColor(hex: "#D2D5DB"), renderingMode: .alwaysOriginal)

        attachment.bounds = CGRect(x: 0, y: -2, width: 14, height: 14)
        return attachment
    }
    
    private var collectionObserver: NSKeyValueObservation?

    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
        configureData()
        observeCollectionHeight()
    }
    
    private func setupCollectionView() {

        timeCollectionView.register(TimeTagCVC.self,
                                    forCellWithReuseIdentifier: TimeTagCVC.identifier)

        timeCollectionView.delegate = self
        timeCollectionView.dataSource = self
        timeCollectionView.isScrollEnabled = false

        if let layout = timeCollectionView.collectionViewLayout as? UICollectionViewFlowLayout {
            layout.scrollDirection = .vertical
            layout.minimumLineSpacing = 8
            layout.minimumInteritemSpacing = 8
        }
        
        if !timeSlots.isEmpty {
            selectedIndex = 0
            selectedTimeLbl.text = timeSlots[0]
          
        }
        updatePricing(for: 0)
    }
    
    
    func updatePricing(for index: Int) {
        
        guard let item = seatingArea else { return }

        if item.hidePricing == true {
            miniMumAmountLbl.text = ""
            feesLbl.text = ""
            return
        }
        
        

        if item.bookingType == .timeWise {
            
            if let slot = item.timeSlots?[index] {
                
                if let minimum = slot.minimum {
                    miniMumAmountLbl.text = "$\(minimum) min."
                } else {
                    miniMumAmountLbl.text = ""
                }

                if let deposit = slot.deposit {
                    feesLbl.text = "$\(String(format: "%.2f", deposit))"
                } else {
                    feesLbl.text = ""
                }
            }

        } else {
            
            if let minimum = item.minimum {
                miniMumAmountLbl.text = "$\(minimum) min."
            }

            if let deposit = item.depositWithFees {
                feesLbl.text = "$\(String(format: "%.2f", deposit))"
            } else if let deposit = item.deposit {
                feesLbl.text = "$\(String(format: "%.2f", deposit))"
            }
        }
    }
    
    private func observeCollectionHeight() {

        collectionObserver = timeCollectionView.observe(\.contentSize,
                                                          options: [.new]) { [weak self] collection, _ in
            guard let self = self else { return }
            self.timeCollectionViewHeight.constant = collection.contentSize.height
        }
    }

    private func configureData() {

        guard let item = seatingArea else { return }

        tableName.text = item.name
        tableDescriptionLbl.text = item.highlight?.isEmpty == false
            ? item.highlight
            : item.description

        currentGuestCount = item.defaultGuest ?? 1
        guestAndTimeLbl.text = "\(currentGuestCount)"
        maxiMumGuestLbl.text = "\(item.defaultGuest ?? 0)"
        updateGuestButtons()
        let minGuest = item.defaultGuest ?? 0
        let maxGuest = item.maxGuest ?? 0

        let guestsText: String = {
            if minGuest > 0 && maxGuest > 0 {
                return minGuest == maxGuest
                ? "\(minGuest) Guests"
                : "\(minGuest) to \(maxGuest) Guests"
            } else if maxGuest > 0 {
                return "\(maxGuest) Guests"
            } else {
                return "Guests"
            }
        }()
        
        if item.inquiryEnabled ?? false {
            self.inquireView.isHidden = true
        } else {
            self.inquireView.isHidden = false
        }
        
        if item.bookingType == .timeWise {
            timeCollectionViewParentView.isHidden = false
        if let slot = item.timeSlots?.first,
           let start = slot.startTime,
           let startDate = start.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false) {
            
            let startTime = startDate.string(format: .hmma, isUTC: false)
            
            var endTime = ""
            
            if let end = slot.endTime,
               let endDate = end.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false) {
                
                endTime = endDate.string(format: .hmma, isUTC: false)
            }
            
            let finalTime = endTime.isEmpty ? startTime : "\(startTime) - \(endTime)"
            
            guestAndTimeLbl.attributedText = buildGuestsTimeText(
                guests: guestsText,
                time: finalTime
            )
        } else {
            guestAndTimeLbl.attributedText = buildGuestsTimeText(
                guests: guestsText,
                time: ""
            )
            
        }
        tableDetailLbl.text = item.description
        
        if let slots = item.timeSlots {
            timeSlots = slots.compactMap { slot in
                guard let start = slot.startTime,
                      let startDate = start.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: false)
                else { return nil }

                let startTime = startDate.string(format: .hmma, isUTC: true)

                return startTime
            }
        }
        
        if !timeSlots.isEmpty {
            selectedIndex = 0
            selectedTimeLbl.text = timeSlots[0]
        }
            self.timeCollectionView.isHidden = false
            timeCollectionView.reloadData()
            timeCollectionView.collectionViewLayout.invalidateLayout()
            timeCollectionView.layoutIfNeeded()
        } else {
            timeCollectionViewParentView.isHidden = true
        }
    }
    
    
    func buildGuestsTimeText(
        guests: String,
        time: String
    ) -> NSAttributedString {

        let text = NSMutableAttributedString()
        text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "person.2")))
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
        text.append(NSAttributedString(string: guests, attributes: infoTextAttributes))
        text.append(NSAttributedString(string: "  ", attributes: infoTextAttributes))
        if !time.isEmpty {
            text.append(NSAttributedString(attachment: makeIconAttachment(systemName: "clock")))
        }
        text.append(NSAttributedString(string: " ", attributes: infoTextAttributes))
        text.append(NSAttributedString(string: time, attributes: infoTextAttributes))

        return text
    }

    private func updateGuestButtons() {

        guard let maxGuest = seatingArea?.maxGuest else { return }

        increaseBtn.isEnabled = currentGuestCount < maxGuest
        increaseBtn.alpha = increaseBtn.isEnabled ? 1 : 0.5

        decreaseBtn.isEnabled = currentGuestCount > 1
        decreaseBtn.alpha = decreaseBtn.isEnabled ? 1 : 0.5
    }

    // MARK: - Actions

    @IBAction func onClickIncreaseGuest(_ sender: Any) {
        guard let maxGuest = seatingArea?.maxGuest else { return }

        if currentGuestCount < maxGuest {
            currentGuestCount += 1
            maxiMumGuestLbl.text = "\(currentGuestCount)"
        }
        updateGuestButtons()
    }

    @IBAction func onClickDecreaseGuest(_ sender: Any) {
        if currentGuestCount > 1 {
            currentGuestCount -= 1
            maxiMumGuestLbl.text = "\(currentGuestCount)"
        }
        updateGuestButtons()
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        dismiss(animated: false)
    }

    @IBAction func onClickOutSide(_ sender: Any) {
        dismiss(animated: false)
    }
    
    @IBAction func onClickCheckOutBtn(_ sender: Any) {
        Navigate.to.tablePurchaseVC(self)
    }
}

extension TableSeatingViewController: UICollectionViewDelegate,
                                      UICollectionViewDataSource,
                                      UICollectionViewDelegateFlowLayout {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return timeSlots.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: TimeTagCVC.identifier,
            for: indexPath
        ) as! TimeTagCVC

        let text = timeSlots[indexPath.item]
        cell.configure(with: text, isSelected: indexPath.item == selectedIndex)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        
        selectedIndex = indexPath.item
        selectedTimeLbl.text = timeSlots[indexPath.item]
        updatePricing(for: indexPath.item)
        collectionView.reloadData()
    }

    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {

        let text = timeSlots[indexPath.item]
        let font = UIFont.systemFont(ofSize: 14, weight: .medium)
        let textWidth = text.size(withAttributes: [.font: font]).width

        let padding: CGFloat = 32
        let width = textWidth + padding

        return CGSize(width: width, height: 32)
    }
}



import UIKit

final class TimeTagCVC: UICollectionViewCell {
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = .black
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textAlignment = .center
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupUI()
    }

    private func setupUI() {

        backgroundColor = .white
        layer.cornerRadius = 8
        layer.masksToBounds = true
        

        contentView.addSubview(titleLabel)

        NSLayoutConstraint.activate([
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 10),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -10),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with text: String, isSelected: Bool) {
        
        titleLabel.text = text
        
        if isSelected {
            backgroundColor = UIColor(hex: "#7C3AED") // selected color
            titleLabel.textColor = .white
        } else {
            backgroundColor = .white
            titleLabel.textColor = .black
        }
    }
}
