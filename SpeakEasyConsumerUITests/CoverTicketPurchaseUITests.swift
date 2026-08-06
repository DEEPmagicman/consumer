import XCTest

final class CoverTicketPurchaseUITests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launchArguments += ["-ui-testing"]

        addUIInterruptionMonitor(withDescription: "System permissions") { alert in
            let preferredButtons = ["Allow While Using App", "Allow Once", "Don’t Allow"]
            for title in preferredButtons where alert.buttons[title].exists {
                alert.buttons[title].tap()
                return true
            }
            return false
        }

        app.launch()
        app.tap() // Gives the interruption monitor a chance to handle a launch alert.
    }

    override func tearDownWithError() throws {
        app = nil
    }

    func testPurchaseLiveCoverWithNewCardShowsQRCode() throws {
        try openVenue(named: "Joy District", switchingTo: "Chicago")

        let buyCoverButton = app.descendants(matching: .any)["venue.buyLiveCover"]
        XCTAssertTrue(
            buyCoverButton.waitForExistence(timeout: 20),
            "The Buy Now action for live cover did not become available."
        )
        buyCoverButton.tap()

        let maleAdmissionIncrement = app.buttons.matching(
            NSPredicate(
                format: "identifier CONTAINS[c] %@ OR label CONTAINS[c] %@",
                "general.admission.-.male.increment",
                "Add General Admission - Male"
            )
        ).firstMatch
        try scrollToAndTap(maleAdmissionIncrement, failureMessage: "General Admission - Male was not available.")

        try tapCheckoutAction(named: "Continue to Checkout")
        try tapCheckoutAction(named: "Skip This & Continue to Checkout")
        try tapCheckoutAction(matchingPrefix: "Pay")

        try addNewStripeCard(
            number: "4242424242424242",
            expiration: "0927",
            cvc: "999"
        )

        guard let stripePayButton = waitForHittableButton(labelPrefix: "Pay", timeout: 15) else {
            XCTFail("Stripe's Pay button was not shown.")
            return
        }
        XCTAssertTrue(stripePayButton.isEnabled, "Stripe's Pay button was disabled after entering the card.")
        stripePayButton.tap()

        let qrCode = app.images["coverPurchase.qrCode"]
        XCTAssertTrue(
            qrCode.waitForExistence(timeout: 60),
            "A cover ticket QR code did not appear after payment completed."
        )
    }
}

private extension CoverTicketPurchaseUITests {
    func selectLocation(named city: String) throws {
        let locationButton = app.descendants(matching: .any)["discover.location.button"]
        XCTAssertTrue(locationButton.waitForExistence(timeout: 20), "The location selector was not shown.")
        for _ in 0..<6 where !locationButton.isHittable {
            app.swipeDown()
        }
        XCTAssertTrue(locationButton.isHittable, "The location selector could not be tapped.")
        locationButton.tap()

        let searchField = app.textFields["location.search"]
        if searchField.waitForExistence(timeout: 10) {
            searchField.tap()
            searchField.typeText(city)
        }

        let cityCell = app.descendants(matching: .any)["location.city.\(city.lowercased())"]
        XCTAssertTrue(cityCell.waitForExistence(timeout: 15), "\(city) was not returned by location search.")
        cityCell.tap()

        let applyButton = app.descendants(matching: .any)["location.apply"]
        XCTAssertTrue(applyButton.waitForExistence(timeout: 5), "The location Apply button was not shown.")
        applyButton.tap()

        XCTAssertTrue(
            app.staticTexts["Partners in \(city)"].waitForExistence(timeout: 30),
            "Discover did not refresh for \(city)."
        )
    }

    func openVenue(named venue: String, switchingTo city: String) throws {
        let currentVenueName = app.staticTexts["venue.current.name"]
        if currentVenueName.waitForExistence(timeout: 3)
            && currentVenueName.label.caseInsensitiveCompare(venue) == .orderedSame {
            return
        }

        if !isLocationSelected(city) {
            try selectLocation(named: city)
        }

        XCTAssertTrue(
            findAndOpenVenue(named: venue),
            "\(venue) was not found in the Partners section."
        )
    }

    func isLocationSelected(_ city: String) -> Bool {
        let locationButton = app.descendants(matching: .any)["discover.location.button"]
        guard locationButton.waitForExistence(timeout: 10),
              let selectedLocation = locationButton.value as? String else {
            return false
        }

        return selectedLocation.caseInsensitiveCompare(city) == .orderedSame
    }

    func findAndOpenVenue(named venue: String) -> Bool {
        let venueCell = app.descendants(matching: .any)["discover.venue.\(venue.lowercased())"]
        let partnersSection = app.descendants(matching: .any)["discover.partners.section"]
        let partnersCollection = app.collectionViews["discover.partners.collection"]

        _ = venueCell.waitForExistence(timeout: 5)

        for _ in 0..<6 where !venueCell.isHittable {
            if partnersSection.exists && partnersSection.isHittable {
                break
            }
            app.swipeUp()
        }

        for _ in 0..<6 where !venueCell.isHittable {
            if partnersCollection.exists {
                partnersCollection.swipeLeft()
            } else {
                app.collectionViews.allElementsBoundByIndex.last?.swipeLeft()
            }
        }

        guard venueCell.exists && venueCell.isHittable else {
            return false
        }

        venueCell.tap()
        return true
    }

    func tapCheckoutAction(named title: String) throws {
        let button = app.buttons["checkout.action"]
        XCTAssertTrue(button.waitForExistence(timeout: 30), "\(title) was not shown.")
        XCTAssertEqual(button.label.lowercased(), title.lowercased())
        button.tap()
    }

    func tapCheckoutAction(matchingPrefix prefix: String) throws {
        let button = app.buttons["checkout.action"]
        XCTAssertTrue(button.waitForExistence(timeout: 30), "A \(prefix) checkout action was not shown.")
        XCTAssertTrue(button.label.lowercased().hasPrefix(prefix.lowercased()))
        button.tap()
    }

    func scrollToAndTap(_ element: XCUIElement, failureMessage: String) throws {
        for _ in 0..<6 where !element.isHittable {
            app.swipeUp()
        }
        XCTAssertTrue(element.exists && element.isHittable, failureMessage)
        element.tap()
    }

    func addNewStripeCard(number: String, expiration: String, cvc: String) throws {
        guard let addCardButton = waitForHittableButton(
            labels: ["Add new payment method", "Add new card", "Add payment method"],
            timeout: 20
        ) else {
            XCTFail("Stripe's Add new payment method action was not shown.")
            return
        }
        addCardButton.tap()

        guard let cardNumber = waitForStripeTextField(
            matchingAny: ["Card number", "Card Number"],
            timeout: 10
        ) else {
            XCTFail("Stripe's card number field was not shown.")
            return
        }
        cardNumber.tap()
        cardNumber.typeText(number)

        let expirationField = waitForStripeTextField(
            matchingAny: ["expiration date", "Expiration date", "MM / YY", "MM/YY"],
            timeout: 3
        )
        let cvcField = waitForStripeTextField(matchingAny: ["CVC", "Security code"], timeout: 3)

        if let expirationField, let cvcField {
            expirationField.tap()
            expirationField.typeText(expiration)
            cvcField.tap()
            cvcField.typeText(cvc)
        } else {
            // Some Stripe SDK versions expose the card widget as one combined field.
            cardNumber.typeText(expiration + cvc)
        }
    }

    func waitForHittableButton(labels: [String], timeout: TimeInterval) -> XCUIElement? {
        waitForElement(timeout: timeout) {
            for label in labels {
                let button = self.app.buttons[label]
                if button.exists && button.isHittable {
                    return button
                }
            }
            return nil
        }
    }

    func waitForHittableButton(labelPrefix: String, timeout: TimeInterval) -> XCUIElement? {
        waitForElement(timeout: timeout) {
            self.app.buttons.allElementsBoundByIndex.first {
                $0.isHittable && $0.label.lowercased().hasPrefix(labelPrefix.lowercased())
            }
        }
    }

    func waitForStripeTextField(matchingAny names: [String], timeout: TimeInterval) -> XCUIElement? {
        waitForElement(timeout: timeout) {
            for name in names {
                let textField = self.app.textFields[name]
                if textField.exists {
                    return textField
                }

                let secureTextField = self.app.secureTextFields[name]
                if secureTextField.exists {
                    return secureTextField
                }
            }
            return nil
        }
    }

    func waitForElement(
        timeout: TimeInterval,
        lookup: () -> XCUIElement?
    ) -> XCUIElement? {
        let deadline = Date().addingTimeInterval(timeout)

        repeat {
            if let element = lookup() {
                return element
            }
            RunLoop.current.run(until: Date().addingTimeInterval(0.25))
        } while Date() < deadline

        return lookup()
    }
}
