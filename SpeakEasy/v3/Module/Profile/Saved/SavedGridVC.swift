//
//  SavedGridVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 28/05/26.
//

import UIKit

final class SavedGridVC: BaseSingleGridVC {

    private let eventService = EventService()
    
    override var emptyTitle: String {
        "No saved items found"
    }

    override var emptyStateStyle: V3EmptyStateStyle {
        .savedEvents
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

        eventService.fetchSavedEvents(skip: skip) { [weak self] isSuccess, errMsg, bookings, hasMany in
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
        guard let event = booking.event else { return }

        Navigate.eventDetailsVC(
            self,
            event: event
        ) { [weak self] updatedEvent, isSaved in
            self?.handleSaveStateChange(
                event: updatedEvent,
                isSaved: isSaved
            )
        }
    }

    private func handleSaveStateChange(
        event: Event,
        isSaved: Bool
    ) {
        guard !isSaved else {
            loadData(reset: true)
            return
        }

        guard let index = items.firstIndex(where: {
            $0.event?.id == event.id ||
            $0.event?.uniqueId == event.uniqueId
        }) else {
            loadData(reset: true)
            return
        }

        let shouldShowEmptyAfterDelete = items.count == 1
        items.remove(at: index)
        skip = items.count

        guard !shouldShowEmptyAfterDelete else {
            hasMany = false
            collectionView.reloadData()
            reloadUI()
            return
        }

        collectionView.performBatchUpdates {
            collectionView.deleteItems(
                at: [IndexPath(item: index, section: 0)]
            )
        } completion: { [weak self] _ in
            self?.reloadUI()
        }
    }
}
