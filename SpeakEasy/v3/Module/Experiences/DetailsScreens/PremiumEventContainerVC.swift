//
//  PremiumEventContainerVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 18/06/26.
//

private struct SeatingAreaConditions {

    let isFutureTicket: Bool
    let isSaleEnded: Bool
    let isSoldOut: Bool
    let isPaused: Bool
    let isEnabled: Bool

    var isVisible: Bool {
        isEnabled &&
        !isFutureTicket &&
        !isSaleEnded &&
        !isSoldOut &&
        !isPaused
    }
}

import UIKit

final class PremiumEventContainerVC: UIViewController {

    // MARK: Background

    private let bgImageView = UIImageView()

    private let blurView = VisualEffectView(
        effect: UIBlurEffect(style: .dark)
    )

    private let dimView = UIView()

    // MARK: Header

    private let headerView = PremiumEventHeaderView()

    // MARK: Segment

    private let segmentView = PremiumEventSegmentView()

    // MARK: Child Container

    private let containerView = UIView()

    // MARK: Child VCs

    private lazy var mapVC = PremiumMapVC()

    private lazy var listVC = PremiumReservationVC()

    private lazy var inquiryVC = PremiumInquiryVC()

    private var currentVC: UIViewController?

    private let tableService = TableService()

    private(set) var seatingAreas: [SeatingArea] = []

    private(set) var visibleSeatingAreas: [SeatingArea] = []

    private(set) var hiddenSeatingAreas: [SeatingArea] = []
        
    var event: Event?

    // MARK: Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()

        setupUI()

        configureHeader()

        fetchSeatingAreas()
        
        setupChildren()

        switchTo(.list, animated: false)
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
}

private extension PremiumEventContainerVC {

    func setupUI() {

        view.backgroundColor = AppColor.primaryBlackColor

        setupBackground()

        setupHeader()

        setupSegment()

        setupContainer()

        setupConstraints()
    }
}

private extension PremiumEventContainerVC {

    func setupBackground() {

        bgImageView.image = UIImage(resource: .premiumExpBg)
        bgImageView.contentMode = .scaleAspectFill
        bgImageView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(bgImageView)

        blurView.blurRadius = 14
        blurView.colorTint = AppColor.primaryBlackColor
        blurView.colorTintAlpha = 0.14
        blurView.alpha = 0.70
        blurView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(blurView)

        dimView.backgroundColor = AppColor.primaryBlackColor.withAlphaComponent(0.42)
        dimView.translatesAutoresizingMaskIntoConstraints = false

        view.addSubview(dimView)
    }
}

private extension PremiumEventContainerVC {

    func setupHeader() {

        headerView.translatesAutoresizingMaskIntoConstraints = false
        headerView.delegate = self

        view.addSubview(headerView)
    }
    
    func configureHeader() {
        
        headerView.configure(
            title: event?.title ?? "",
            venue: event?.venue?.name ?? ""
        )
    }
    
    private func fetchSeatingAreas() {

        guard let event else {
            return
        }

        tableService.fetchSeatingAreas(
            eventId: event.id ?? "",
            skip: 0
        ) { [weak self] success,
             error,
             list,
             _ in

            guard let self else {
                return
            }

            guard success else {

                Alert.showToast(
                    error ?? Constant.String.somethingWrong
                )

                return
            }

            let filtered = self.filterSeatingAreas(list)

            self.seatingAreas = list
            self.visibleSeatingAreas = filtered.visible
            self.hiddenSeatingAreas = filtered.filteredOut

            self.passDataToChildren()
        }
    }
    
    private func passDataToChildren() {

        mapVC.event = event
        mapVC.seatingAreas = visibleSeatingAreas

        listVC.event = event
        listVC.seatingAreas = visibleSeatingAreas

        inquiryVC.event = event
        inquiryVC.seatingAreas = hiddenSeatingAreas
    }
    
    private func filterSeatingAreas(
        _ list: [SeatingArea]
    ) -> (
        visible: [SeatingArea],
        filteredOut: [SeatingArea]
    ) {

        let timezone =
            event?.venue?.timezone ??
            event?.venue?.useTimezone ??
            TimeZone.current.identifier

        var visible: [SeatingArea] = []
        var filteredOut: [SeatingArea] = []

        list.forEach { item in

            let conditions = checkTicketConditions(
                item,
                timezone: timezone
            )

            if conditions.isVisible {
                visible.append(item)
            } else {
                filteredOut.append(item)
            }
        }

        return (
            visible,
            filteredOut
        )
    }
    
    private func checkTicketConditions(
        _ area: SeatingArea,
        timezone: String
    ) -> SeatingAreaConditions {

        let now = Date.venueNow(timezone: timezone)

        let beginSale = area.beginSale?.toVenueDate(timezone: timezone)
        let endSale = area.endSale?.toVenueDate(timezone: timezone)

        let isFutureTicket = beginSale.map { $0 > now } ?? false
        let isSaleEnded = endSale.map { $0 < now } ?? false

        let baseSoldOut =
            (area.issuedPublicInventory ?? 0) <=
            (area.soldPublicInventory ?? 0)

        let isSoldOut: Bool = {

            if area.bookingType == .timeWise {

                let slots = area.timeSlots ?? []

                return slots.isEmpty
                    ? baseSoldOut
                    : slots.allSatisfy {
                        ($0.issuedPublicInventory ?? 0) <=
                        ($0.soldPublicInventory ?? 0)
                    }
            }

            return baseSoldOut

        }()

        let status = area.status?.uppercased() ?? ""

        return SeatingAreaConditions(
            isFutureTicket: isFutureTicket,
            isSaleEnded: isSaleEnded,
            isSoldOut: isSoldOut,
            isPaused: status == "DISABLED",
            isEnabled: status == "ENABLED"
        )
    }
}

private extension PremiumEventContainerVC {

    func setupSegment() {

        segmentView.translatesAutoresizingMaskIntoConstraints = false
        segmentView.delegate = self

        view.addSubview(segmentView)
    }
}

private extension PremiumEventContainerVC {

    func setupContainer() {

        containerView.translatesAutoresizingMaskIntoConstraints = false
        containerView.backgroundColor = .clear

        view.addSubview(containerView)
    }
}

private extension PremiumEventContainerVC {

    func setupConstraints() {

        NSLayoutConstraint.activate([

            // Background

            bgImageView.topAnchor.constraint(equalTo: view.topAnchor),
            bgImageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            bgImageView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            bgImageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            dimView.topAnchor.constraint(equalTo: view.topAnchor),
            dimView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            dimView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            dimView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            // Header

            headerView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor),
            headerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            headerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),

            // Segment

            segmentView.topAnchor.constraint(equalTo: headerView.bottomAnchor, constant: 10),
            segmentView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16),
            segmentView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16),
            segmentView.heightAnchor.constraint(equalToConstant: 46),

            // Container

            containerView.topAnchor.constraint(equalTo: segmentView.bottomAnchor, constant: 10),
            containerView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            containerView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            containerView.bottomAnchor.constraint(equalTo: view.bottomAnchor)

        ])
    }
}

private extension PremiumEventContainerVC {

    func setupChildren() {

        add(child: mapVC)

        add(child: listVC)

        add(child: inquiryVC)

        mapVC.view.isHidden = true
        inquiryVC.view.isHidden = true
    }

    func add(child vc: UIViewController) {

        addChild(vc)

        vc.view.translatesAutoresizingMaskIntoConstraints = false
        vc.view.backgroundColor = .clear

        containerView.addSubview(vc.view)

        NSLayoutConstraint.activate([

            vc.view.topAnchor.constraint(equalTo: containerView.topAnchor),

            vc.view.leadingAnchor.constraint(equalTo: containerView.leadingAnchor),

            vc.view.trailingAnchor.constraint(equalTo: containerView.trailingAnchor),

            vc.view.bottomAnchor.constraint(equalTo: containerView.bottomAnchor)

        ])

        vc.didMove(toParent: self)
    }
}

extension PremiumEventContainerVC {

    enum Segment {

        case map

        case list

        case inquiry
    }
}

private extension PremiumEventContainerVC {

    func switchTo(
        _ segment: Segment,
        animated: Bool
    ) {

        mapVC.view.isHidden = segment != .map
        listVC.view.isHidden = segment != .list
        inquiryVC.view.isHidden = segment != .inquiry

        currentVC = {

            switch segment {

            case .map:
                return mapVC

            case .list:
                return listVC

            case .inquiry:
                return inquiryVC
            }

        }()

        guard animated else { return }

        currentVC?.view.alpha = 0

        UIView.animate(
            withDuration: 0.22,
            delay: 0,
            options: .curveEaseOut
        ) {

            self.currentVC?.view.alpha = 1

        }
    }
}

extension PremiumEventContainerVC: PremiumEventHeaderViewDelegate {

    func premiumEventHeaderDidTapBack(
        _ view: PremiumEventHeaderView
    ) {

        navigationController?.popViewController(animated: true)
    }
}

extension PremiumEventContainerVC: PremiumEventSegmentViewDelegate {

    func premiumSegmentView(
        _ view: PremiumEventSegmentView,
        didSelect segment: PremiumEventContainerVC.Segment
    ) {

        switchTo(
            segment,
            animated: true
        )
    }
}
