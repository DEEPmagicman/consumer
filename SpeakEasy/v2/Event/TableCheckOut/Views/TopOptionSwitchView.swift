import UIKit

final class TopOptionSwitchView: UIView {

    // MARK: - Public
    var options: [String] = [] {
        didSet { setupButtons() }
    }

    var onSelectionChange: ((Int) -> Void)?

    // MARK: - Private
    private var buttons: [UIButton] = []
    private var selectedIndex: Int = 0

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.spacing = 4
        return sv
    }()

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        commonInit()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        commonInit()
    }

    private func commonInit() {
        backgroundColor = UIColor(hex: "#151515")
        layer.cornerRadius = 13
        clipsToBounds = true

        addSubview(stackView)
        stackView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            stackView.topAnchor.constraint(equalTo: topAnchor, constant: 2),
            stackView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -2),
            stackView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 2),
            stackView.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -2),
            heightAnchor.constraint(equalToConstant: 26)
        ])
    }

    private func setupButtons() {
        stackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.removeAll()

        for (index, title) in options.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.titleLabel?.font = AppFont.font(.inter, weight: .semibold, size: 12)
            button.tag = index
            button.layer.cornerRadius = 11
            button.addTarget(self, action: #selector(onTap(_:)), for: .touchUpInside)
            button.setTitleColor(.white, for: .normal)
            buttons.append(button)
            stackView.addArrangedSubview(button)
        }

        updateSelection(index: selectedIndex)
    }

    @objc private func onTap(_ sender: UIButton) {
        updateSelection(index: sender.tag)
        onSelectionChange?(sender.tag)
    }

    private func updateSelection(index: Int) {
        selectedIndex = index

        for (ind, button) in buttons.enumerated() {
            if ind == index {
                button.backgroundColor = UIColor(hex: "#292929")
            } else {
                button.backgroundColor = .clear
            }
        }
    }
}
