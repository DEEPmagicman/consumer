//
//  TicketsOrdersVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 25/05/26.
//

import UIKit

final class TicketsOrdersVC: BaseOrdersGridVC {

    override var upcomingTitle: String { "Upcoming tickets" }
    override var pastTitle: String { "Past tickets" }
    override var emptyTitle: String { "No tickets found" }

    override func loadUpcoming(reset: Bool) {
        guard !UserDefault.shared.isGuest else { return }
        guard !isLoadingUpcoming else { return }

        isLoadingUpcoming = true

        if reset {
            upcomingSkip = 0
            upcomingHasMany = false
            upcomingItems.removeAll()
            reloadUI()
        }

        PaymentPresenter.getUpcomingTicket(skip: upcomingSkip) { [weak self] isSuccess, errMsg, bookings, hasMany in
            guard let self else { return }

            self.isLoadingUpcoming = false
            self.didLoadUpcoming = true

            if isSuccess {
                self.upcomingItems = reset ? bookings : self.upcomingItems + bookings
                self.upcomingHasMany = hasMany
                self.upcomingSkip = self.upcomingItems.count
            } else {
                if reset { self.upcomingItems.removeAll() }
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }

            self.reloadUI()
        }
    }

    override func loadPast(reset: Bool) {
        guard !UserDefault.shared.isGuest else { return }
        guard !isLoadingPast else { return }

        isLoadingPast = true

        if reset {
            pastSkip = 0
            pastHasMany = false
            pastItems.removeAll()
            reloadUI()
        }

        PaymentPresenter.getPastTicket(skip: pastSkip) { [weak self] isSuccess, errMsg, bookings, hasMany in
            guard let self else { return }

            self.isLoadingPast = false
            self.didLoadPast = true

            if isSuccess {
                self.pastItems = reset ? bookings : self.pastItems + bookings
                self.pastHasMany = hasMany
                self.pastSkip = self.pastItems.count
            } else {
                if reset { self.pastItems.removeAll() }
                Alert.showAlertSheet(
                    style: .alert,
                    title: errMsg ?? Constant.String.somethingWrong,
                    message: ""
                )
            }

            self.reloadUI()
        }
    }

    override func configure(_ cell: OrderCardCollectionCell, booking: Booking) {
        cell.configureTicket(booking)
    }

    override func didSelect(_ booking: Booking) {
        if booking.eventId != nil {
            Navigate.to.showQRCode(self, booking: booking, bookingId: booking.id, type: .singleTickedEvent)
        } else if booking.inviteLink != nil {
            Navigate.to.showQRCode(self, booking: booking, bookingId: booking.id, type: .appClip)
        } else {
            Navigate.to.scanQR(self, bookingId: booking.id, booking: booking, addOnsBookingId: "")
        }
    }
}
