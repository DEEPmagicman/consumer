//
//  SavedGridVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class SavedGridVC: BaseSingleGridVC {

    private let orderService = OrderService()
    
    override var emptyTitle: String {
        "No saved items found"
    }

    override func loadData(reset: Bool) {
        guard !UserDefault.shared.isGuest else { return }
        guard !isLoading else { return }

        isLoading = true

        if reset {
            skip = 0
            hasMany = false
            items.removeAll()
            isInitialLoading = true
            reloadUI()
        }

        orderService.fetchPastTickets(skip: skip) { [weak self] isSuccess, errMsg, bookings, hasMany in
            guard let self else { return }

            self.isLoading = false
            self.isPaginating = false
            self.isInitialLoading = false

            if isSuccess {
                let oldCount = self.items.count

                self.items = reset ? bookings : self.items + bookings
                self.hasMany = hasMany
                self.skip = self.items.count

                if reset {
                    self.reloadUI()
                } else {
                    let newCount = self.items.count
                    let indexPaths = (oldCount..<newCount).map {
                        IndexPath(item: $0, section: 0)
                    }

                    self.insertItems(indexPaths)
                }
            } else {
                if reset { self.items.removeAll() }

                self.reloadUI()

                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }
        }
    }

    override func configure(_ cell: OrderCardCollectionCell, booking: Booking) {
        cell.configureEvent(booking)
    }

    override func didSelect(_ booking: Booking) {
        guard let _ = booking.event else { return }

//        Navigate.to.eventDetails(
//            self,
//            event: event
//        )
    }
}
