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

    var seatingArea: SeatingArea?

    private var currentGuestCount: Int = 1
    private var timeSlots: [String] = ["6:00 PM", " 7:00 PM" , "8:30 PM",
                                       "10:00 PM", " 7:00 PM"]
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
        maxiMumGuestLbl.text = "\(item.maxGuest ?? 0)"
        updateGuestButtons()

        // Extract Time Slots
//        if let slots = item.timeSlots {
//            timeSlots = slots.compactMap { slot in
//                guard let start = slot.startTime,
//                      let startDate = start.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: true)
//                else { return nil }
//
//                let startTime = startDate.string(format: .hmma, isUTC: false)
//
//                if let end = slot.endTime,
//                   let endDate = end.dateFormatter(formate: .yyyyMMddTHHmmssSSSz, isUTC: true) {
//                    let endTime = endDate.string(format: .hmma, isUTC: false)
//                    return "\(startTime) - \(endTime)"
//                }
//
//                return startTime
//            }
//        }

        timeCollectionView.reloadData()
        timeCollectionView.collectionViewLayout.invalidateLayout()
        timeCollectionView.layoutIfNeeded()
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
            guestAndTimeLbl.text = "\(currentGuestCount)"
        }
        updateGuestButtons()
    }

    @IBAction func onClickDecreaseGuest(_ sender: Any) {
        if currentGuestCount > 1 {
            currentGuestCount -= 1
            guestAndTimeLbl.text = "\(currentGuestCount)"
        }
        updateGuestButtons()
    }

    @IBAction func onClickCloseBtn(_ sender: Any) {
        dismiss(animated: false)
    }

    @IBAction func onClickOutSide(_ sender: Any) {
        dismiss(animated: false)
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

        cell.configure(with: timeSlots[indexPath.item])
        return cell
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
            titleLabel.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            titleLabel.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            titleLabel.centerYAnchor.constraint(equalTo: contentView.centerYAnchor)
        ])
    }

    func configure(with text: String) {
        titleLabel.text = text
    }
}
