//
//  BaseSearchSheetVC.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 03/06/26.
//

import UIKit

class BaseSearchSheetVC: UIViewController {

    let sheetView = UIView()
    let closeBtn = AppIconButton()
    let titleLabel = UILabel()

    override func viewDidLoad() {
        super.viewDidLoad()
        setupBase()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sheetView.applyScreenBgGradient(direction: .bottomToTop)
    }
    
    private func setupBase() {
        sheetView.layer.cornerRadius = 28
        sheetView.layer.cornerCurve = .continuous
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)

        closeBtn.iconTypeValue = AppIconType.close.rawValue
        closeBtn.iconSize = 14
        closeBtn.buttonSize = 40
        closeBtn.iconTintColor = .white
        closeBtn.addTarget(self, action: #selector(onClose), for: .touchUpInside)
        closeBtn.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(closeBtn)

        titleLabel.textColor = .white
        titleLabel.font = Constant.Font.geistMedium(size: 18)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(titleLabel)

        NSLayoutConstraint.activate([

            sheetView.topAnchor.constraint(equalTo: view.topAnchor),
            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            closeBtn.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 16),
            closeBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            closeBtn.widthAnchor.constraint(equalToConstant: 40),
            closeBtn.heightAnchor.constraint(equalToConstant: 40),

            titleLabel.centerYAnchor.constraint(equalTo: closeBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor)
        ])
    }

    @objc func onClose() {
        dismiss(animated: true)
    }
}
