//
//  InviteLinkVC.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 20/06/23.
//

import UIKit
import MapKit

final class InviteLinkVC: UIViewController {
    
    @IBOutlet weak var mainImg: UIImageView!
    @IBOutlet weak var venueTitleLbl: UILabel!
    @IBOutlet weak var titleLbl: UILabel!
    @IBOutlet weak var locationLbl: UILabel!
    @IBOutlet weak var timingLbl: UILabel!
    @IBOutlet weak var continueBtn: UIButton!
    @IBOutlet weak var venueNameLbl: UILabel!
    @IBOutlet weak var mapView: MKMapView!
    @IBOutlet weak var headerTitleLbl: UILabel!
    @IBOutlet weak var scrollView: UIScrollView!
    @IBOutlet weak var headerView: UIView!
    @IBOutlet weak var shareBtn: UIButton!
    @IBOutlet weak var dateLbl: UILabel!
    @IBOutlet weak var dressCodeView: UIView!
    @IBOutlet weak var dressCodeLbl: UILabel!
    @IBOutlet weak var detailLbl: UILabel!
    @IBOutlet weak var policyLbl: UILabel!
    @IBOutlet weak var scrollViewBottomConstraint: NSLayoutConstraint!
    @IBOutlet weak var zeroCaseView: UIView!
    @IBOutlet weak var continueBtnBGView: UIView!
    @IBOutlet weak var venueDetailsView: UIView!
    @IBOutlet weak var organizerView: UIView!
    @IBOutlet weak var organizerAddress: UILabel!
    @IBOutlet weak var locationImg: UIImageView!
    @IBOutlet weak var organizerAddressView: UIView!
    @IBOutlet weak var organizerName: UILabel!
    @IBOutlet weak var organizerImage: UIImageView!
    @IBOutlet weak var descriptionView: UIView!
    @IBOutlet weak var descriptionText: UILabel!
    
    var inviteId = ""
    private var inviteObj: Invite?

    override func viewDidLoad() {
        super.viewDidLoad()
        getInviteData()
        headerTitleLbl.isHidden = true
        headerView.backgroundColor = .clear
        scrollView.delegate = self
        let tap = UITapGestureRecognizer(target: self, action: #selector(openAppleMap))
        mapView.addGestureRecognizer(tap)
        mapView.isScrollEnabled = false
    }
    
    private func getInviteData() {
        Loader.show()
        InvitePresenter.getInvite(inviteId: inviteId) { [weak self] isSuccess, errMsg, invite in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess, let inviteObj = invite {
                self.inviteObj = inviteObj
                self.setupData()
                self.zeroCaseView(isHidden: true)
            } else {
                self.zeroCaseView(isHidden: false)
                self.updateContinueBtn()
            }
        }
    }
    
    private func setupData() {
        mainImg.sd_setImage(with: URL(string: (inviteObj?.venue.venueAttachment.first?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        organizerImage.sd_setImage(with: URL(string: (inviteObj?.venue.logo?.key ?? "").imageURL), placeholderImage: Constant.Icon.uploadImage)
        organizerName.text = inviteObj?.venue.name
        organizerAddress.text = inviteObj?.venue.website ?? "" != "" ? inviteObj?.venue.website : inviteObj?.venue.address
        descriptionText.text = inviteObj?.venue.description ?? "-"
        if inviteObj?.venue.venueSettings?.isOrganizer == true {
            dressCodeView.isHidden = true
            venueDetailsView.isHidden = true
            organizerView.isHidden = false
            descriptionView.isHidden = false
        }
        titleLbl.text = inviteObj?.name ?? "Untitle"
        headerTitleLbl.text = inviteObj?.name ?? "Untitle"
        venueTitleLbl.text = "\(inviteObj?.venue.name ?? ""), \(inviteObj?.venue.city ?? "")"
        venueNameLbl.text = "Venue - \(inviteObj?.venue.name ?? "")"
        detailLbl.text = inviteObj?.description.withEmptyPlaceHolder ?? Constant.String.dash
        policyLbl.text = String(format: Constant.String.venuePolicy, inviteObj?.venue.name ?? "venue")
        locationLbl.text = inviteObj?.venue.address
        dressCodeLbl.text = inviteObj?.venue.dressCode?.withEmptyPlaceHolder ?? Constant.String.dash
        updateLocationOnMap(to: CLLocationCoordinate2D(latitude: inviteObj?.venue.latitude ?? 0, longitude: inviteObj?.venue.longitude ?? 0), with: inviteObj?.venue.name)
        dateLbl.text = inviteObj?.guestList?.startTime.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .EEEMMMD)
        timingLbl.text = "\(Constant.String.dotDoorsOpenAt) \(inviteObj?.guestList?.startTime.convertDateFormat(from: .yyyyMMddTHHmmssSSSz, to: .hmm_a, customTimeZone: inviteObj?.venue.useTimezone ?? "") ?? "")"
        updateContinueBtn(show: true)
        if inviteObj?.venue.website ?? "" != "" {
            locationImg.image = UIImage(named: "ic-link")
            let tap = UITapGestureRecognizer(target: self, action: #selector(onClickWebSite))
            organizerAddressView.addGestureRecognizer(tap)
        }
    }
    
    @objc func onClickWebSite() {
        if let url = URL(string: inviteObj?.venue.website ?? "") {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
    }
    
    private func updateContinueBtn(show: Bool = false) {
        if show {
            continueBtn.isHidden = false
            continueBtn.isUserInteractionEnabled = true
            continueBtn.backgroundColor = continueBtn.backgroundColor?.withAlphaComponent(1)
            scrollViewBottomConstraint.constant = 90
        } else {
            continueBtn.isHidden = true
            scrollViewBottomConstraint.constant = 30
        }
    }
    
    private func zeroCaseView(isHidden: Bool) {
        zeroCaseView.isHidden = isHidden
        shareBtn.isHidden = !isHidden
    }
    
    @objc private func openAppleMap() {
        let coordinate = CLLocationCoordinate2DMake(inviteObj?.venue.latitude ?? 0, inviteObj?.venue.longitude ?? 0)
        let mapItem = MKMapItem(placemark: MKPlacemark(coordinate: coordinate, addressDictionary: nil))
        mapItem.name = inviteObj?.venue.name
        mapItem.openInMaps()
    }
    
    private func updateLocationOnMap(to coordinate: CLLocationCoordinate2D, with title: String?) {
        let point = MKPointAnnotation()
        point.title = title
        point.coordinate = coordinate
        point.accessibilityNavigationStyle = .separate
        mapView.removeAnnotations(mapView.annotations)
        mapView.addAnnotation(point)
        let viewRegion = MKCoordinateRegion(center: coordinate, latitudinalMeters: 200, longitudinalMeters: 200)
        mapView.setRegion(viewRegion, animated: true)
    }
    
    @IBAction private func onClickShare(_ sender: Any) {
        let msgText = String(format: APIBuilder.invitationURL, inviteId)
         Utility.main.shareSocialWith(text: msgText)
    }
    
    @IBAction private func onClickBack(_ sender: Any) {
        Navigate.to.back(self)
    }
    
    @IBAction private func onClickContinue(_ sender: Any) {
        if UserDefault.shared.isGuest == true {
            Navigate.to.loginMandatory(self, guestUserLastNavigation: (.inviteLink, inviteId))
            return
        }
        Loader.show()
        InvitePresenter.redeemInvite(inviteId: inviteId, venueTimeZone: inviteObj?.venue.timezone) { [weak self] isSuccess, errMsg, booking in
            Loader.hide()
            guard let self = self else { return }
            if isSuccess {
                Navigate.to.showQRCode(self, booking: booking, bookingId: booking?.id ?? "", type: .appClip)
            } else {
                Alert.showAlertSheet(style: .alert, title: errMsg ?? Constant.String.somethingWrong, message: "")
            }
        }
    }
}

extension InviteLinkVC: UIScrollViewDelegate {
    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        if scrollView.contentOffset.y > 245 {
            headerTitleLbl.isHidden = false
            headerView.backgroundColor = .black
        } else {
            headerTitleLbl.isHidden = true
            headerView.backgroundColor = .clear
        }
    }
}
