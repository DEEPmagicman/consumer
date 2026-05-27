//
//  GenderSelectionBottomSheetDelegate.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 13/05/26.
//

import UIKit

protocol GenderSelectionBottomSheetDelegate: AnyObject {
    func genderSelectionBottomSheet(_ vc: GenderSelectionBottomSheetVC, didSelect gender: String)
}

final class GenderSelectionBottomSheetVC: UIViewController {

    weak var delegate: GenderSelectionBottomSheetDelegate?

    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
    private let sheetView = UIView()
    private let titleLabel = UILabel()
    private let backBtn = AppIconButton()
    private let optionsCard = UIView()
    private let updateBtn = PrimaryButton()
    
    private let genders = ["Female", "Male", "Other"]
    private var selectedGender: String

    init(selectedGender: String) {
        self.selectedGender = selectedGender.capitalized
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }

    required init?(coder: NSCoder) {
        self.selectedGender = "Male"
        super.init(coder: coder)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        animateIn()
    }

    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        sheetView.applyScreenBgGradient(direction: .bottomToTop)
    }
    
    private func setupUI() {
        view.backgroundColor = AppColor.primaryColor.withAlphaComponent(0.15)
        
        blurView.alpha = 0
        blurView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(blurView)
        
        let outsideTap = UITapGestureRecognizer(target: self, action: #selector(onClickOutside))
        blurView.addGestureRecognizer(outsideTap)
        blurView.isUserInteractionEnabled = true

        sheetView.layer.cornerRadius = 28
        sheetView.layer.cornerCurve = .continuous
        sheetView.clipsToBounds = true
        sheetView.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(sheetView)
        
        backBtn.iconTypeValue = AppIconType.leftSideBack.rawValue
        backBtn.iconSize = 16
        backBtn.buttonSize = 40
        backBtn.iconTintColor = .white
        backBtn.addTarget(self, action: #selector(onClickBack), for: .touchUpInside)
        sheetView.addSubview(backBtn)
        backBtn.translatesAutoresizingMaskIntoConstraints = false

        titleLabel.text = "Select gender"
        titleLabel.textColor = AppColor.primaryWhiteColor
        titleLabel.font = Constant.Font.geistMedium(size: 20)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(titleLabel)
        
        updateBtn.configure(title: "Update", fontSize: 13, cornerRadius: 18)
        updateBtn.addTarget(
            self,
            action: #selector(onClickUpdate),
            for: .touchUpInside
        )
        sheetView.addSubview(updateBtn)
        
        optionsCard.backgroundColor = AuthTheme.fieldLightBackground
        optionsCard.layer.cornerRadius = 16
        optionsCard.layer.cornerCurve = .continuous
        optionsCard.clipsToBounds = true
        optionsCard.translatesAutoresizingMaskIntoConstraints = false
        sheetView.addSubview(optionsCard)

        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: view.topAnchor),
            blurView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            blurView.bottomAnchor.constraint(equalTo: view.bottomAnchor),

            sheetView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            sheetView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            sheetView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            sheetView.heightAnchor.constraint(equalToConstant: 390),

            backBtn.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            backBtn.topAnchor.constraint(equalTo: sheetView.topAnchor, constant: 16),

            titleLabel.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: sheetView.centerXAnchor),

            updateBtn.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -16),
            updateBtn.centerYAnchor.constraint(equalTo: backBtn.centerYAnchor),
            updateBtn.widthAnchor.constraint(equalToConstant: 78),
            updateBtn.heightAnchor.constraint(equalToConstant: 36),

            optionsCard.topAnchor.constraint(equalTo: backBtn.bottomAnchor, constant: 24),
            optionsCard.leadingAnchor.constraint(equalTo: sheetView.leadingAnchor, constant: 16),
            optionsCard.trailingAnchor.constraint(equalTo: sheetView.trailingAnchor, constant: -16),
            optionsCard.heightAnchor.constraint(equalToConstant: 194)
        ])

        buildOptions()
    }

    private func buildOptions() {
        optionsCard.subviews.forEach { $0.removeFromSuperview() }

        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        stack.translatesAutoresizingMaskIntoConstraints = false
        optionsCard.addSubview(stack)

        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: optionsCard.topAnchor),
            stack.leadingAnchor.constraint(equalTo: optionsCard.leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: optionsCard.trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: optionsCard.bottomAnchor)
        ])

        for (index, item) in genders.enumerated() {
            let row = makeGenderRow(title: item)
            row.tag = index
            stack.addArrangedSubview(row)

            if index < genders.count - 1 {
                let lineContainer = UIView()
                lineContainer.translatesAutoresizingMaskIntoConstraints = false
                lineContainer.heightAnchor.constraint(equalToConstant: 1).isActive = true

                let line = UIView()
                line.backgroundColor = AppColor.primaryWhiteColor.withAlphaComponent(0.12)
                line.translatesAutoresizingMaskIntoConstraints = false

                lineContainer.addSubview(line)

                NSLayoutConstraint.activate([
                    line.leadingAnchor.constraint(equalTo: lineContainer.leadingAnchor, constant: 20),
                    line.trailingAnchor.constraint(equalTo: lineContainer.trailingAnchor, constant: -20),
                    line.topAnchor.constraint(equalTo: lineContainer.topAnchor),
                    line.bottomAnchor.constraint(equalTo: lineContainer.bottomAnchor)
                ])

                stack.addArrangedSubview(lineContainer)
            }
        }
    }

    private func makeGenderRow(title: String) -> UIView {
        let row = UIControl()
        row.backgroundColor = .clear
        row.addTarget(self, action: #selector(onGenderTap(_:)), for: .touchUpInside)

        let label = UILabel()
        label.text = title
        label.textColor = AppColor.primaryWhiteColor
        label.font = Constant.Font.geistRegular(size: 18)
        label.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(label)

        let check = UIImageView()
        check.image = UIImage(systemName: "checkmark")
        check.tintColor = AppColor.primaryWhiteColor
        check.isHidden = selectedGender.lowercased() != title.lowercased()
        check.translatesAutoresizingMaskIntoConstraints = false
        row.addSubview(check)

        NSLayoutConstraint.activate([
            row.heightAnchor.constraint(equalToConstant: 64),

            label.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 20),
            label.centerYAnchor.constraint(equalTo: row.centerYAnchor),

            check.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -22),
            check.centerYAnchor.constraint(equalTo: row.centerYAnchor),
            check.widthAnchor.constraint(equalToConstant: 18),
            check.heightAnchor.constraint(equalToConstant: 18)
        ])

        return row
    }

    private func animateIn() {
        sheetView.transform = CGAffineTransform(translationX: 0, y: 390)

        UIView.animate(withDuration: 0.28, delay: 0, options: [.curveEaseOut]) {
            self.blurView.alpha = 1
            self.sheetView.transform = .identity
        }
    }

    private func dismissSheet(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.24, delay: 0, options: [.curveEaseIn]) {
            self.blurView.alpha = 0
            self.sheetView.transform = CGAffineTransform(translationX: 0, y: 390)
        } completion: { _ in
            self.dismiss(animated: false, completion: completion)
        }
    }

    @objc private func onGenderTap(_ sender: UIControl) {
        selectedGender = genders[sender.tag]
        buildOptions()
    }

    @objc private func onClickBack() {
        dismissSheet()
    }
    
    @objc private func onClickOutside() {
        dismissSheet()
    }

    @objc private func onClickUpdate() {
        dismissSheet { [weak self] in
            guard let self else { return }
            self.delegate?.genderSelectionBottomSheet(self, didSelect: self.selectedGender.uppercased())
        }
    }
}
