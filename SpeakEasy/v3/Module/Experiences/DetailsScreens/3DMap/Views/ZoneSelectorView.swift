//
//  ZoneSelectorView.swift
//  SpeakEasy-Consumer
//
//  Created by Paras on 30/06/26.
//

import UIKit

final class ZoneSelectorView: UIView {

    // MARK: - Types

    enum PageDirection { case none, next, prev }

    // MARK: - Callbacks

    var onSelectItem: ((String, Int) -> Void)?
    var onNextPage: (() -> Void)?
    var onPrevPage: (() -> Void)?

    var titleText: String = "SELECT ZONE" {
        didSet { titleLabel.text = titleText }
    }

    // MARK: - Public API

    func setItems(_ items: [String], selectedIndex: Int = 0, borderColor: String? = nil) {
        allItems = items
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
        selectedGlobalIndex = allItems.isEmpty ? 0 : min(max(0, selectedIndex), allItems.count - 1)
        windowStart = clampedWindowStart(for: selectedGlobalIndex)
        applyBorderColor(borderColor)
        renderVisible(slideDir: .none)
    }

    // MARK: - Private State

    private var allItems: [String] = []
    private var windowStart = 0
    private var selectedGlobalIndex = 0
    private let maxVisible = 3
    private var needsSelectionLayoutUpdate = false

    // MARK: - UI

    private let titleLabel = UILabel()
    private let pillContainer = UIView()
    private let innerStack = UIStackView()
    private let segmentsStack = UIStackView()
    private let leftButton = UIButton(type: .system)
    private let rightButton = UIButton(type: .system)
    private let selectionView = UIView()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        pillContainer.layer.cornerRadius = pillContainer.bounds.height / 2
        selectionView.layer.cornerRadius = selectionView.bounds.height / 2
        if needsSelectionLayoutUpdate {
            needsSelectionLayoutUpdate = false
            updateSelection(animated: false)
        }
    }
}

// MARK: - Setup

private extension ZoneSelectorView {

    func setup() {
        backgroundColor = .clear

        // Title
        titleLabel.text = titleText
        titleLabel.textColor = UIColor.white.withAlphaComponent(0.92)
        titleLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)

        // Pill container
        pillContainer.backgroundColor = UIColor.black.withAlphaComponent(0.4)
        pillContainer.layer.borderWidth = 1.5
        pillContainer.layer.borderColor = UIColor.white.cgColor
        pillContainer.clipsToBounds = true
        pillContainer.translatesAutoresizingMaskIntoConstraints = false
        addSubview(pillContainer)

        // Selection highlight
        selectionView.backgroundColor = UIColor(white: 0.20, alpha: 0.7)
        selectionView.isUserInteractionEnabled = false
        pillContainer.addSubview(selectionView)

        // Arrow buttons
        configureArrowButton(leftButton, systemName: "chevron.left")
        configureArrowButton(rightButton, systemName: "chevron.right")
        leftButton.addTarget(self, action: #selector(didTapLeft), for: .touchUpInside)
        rightButton.addTarget(self, action: #selector(didTapRight), for: .touchUpInside)

        // Segments stack
        segmentsStack.axis = .horizontal
        segmentsStack.alignment = .fill
        segmentsStack.distribution = .fillEqually
        segmentsStack.spacing = 0
        segmentsStack.translatesAutoresizingMaskIntoConstraints = false

        // Inner stack (arrows + segments)
        innerStack.axis = .horizontal
        innerStack.alignment = .center
        innerStack.spacing = 10
        innerStack.translatesAutoresizingMaskIntoConstraints = false
        innerStack.addArrangedSubview(leftButton)
        innerStack.addArrangedSubview(segmentsStack)
        innerStack.addArrangedSubview(rightButton)
        pillContainer.addSubview(innerStack)

        // Constraints
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),

            pillContainer.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 1),
            pillContainer.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 16),
            pillContainer.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -16),
            pillContainer.heightAnchor.constraint(equalToConstant: 38),
            pillContainer.bottomAnchor.constraint(equalTo: bottomAnchor),

            innerStack.leadingAnchor.constraint(equalTo: pillContainer.leadingAnchor, constant: 10),
            innerStack.trailingAnchor.constraint(equalTo: pillContainer.trailingAnchor, constant: -10),
            innerStack.topAnchor.constraint(equalTo: pillContainer.topAnchor, constant: 1),
            innerStack.bottomAnchor.constraint(equalTo: pillContainer.bottomAnchor, constant: -1),

            leftButton.widthAnchor.constraint(equalToConstant: 26),
            leftButton.heightAnchor.constraint(equalToConstant: 26),
            rightButton.widthAnchor.constraint(equalToConstant: 26),
            rightButton.heightAnchor.constraint(equalToConstant: 26)
        ])

        // Swipe gestures
        let swipeLeft = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeLeft.direction = .left
        pillContainer.addGestureRecognizer(swipeLeft)

        let swipeRight = UISwipeGestureRecognizer(target: self, action: #selector(handleSwipe(_:)))
        swipeRight.direction = .right
        pillContainer.addGestureRecognizer(swipeRight)

        // Initial render (empty state)
        updateArrowState()
    }

    func configureArrowButton(_ button: UIButton, systemName: String) {
        let config = UIImage.SymbolConfiguration(pointSize: 14, weight: .medium)
        let image = UIImage(systemName: systemName, withConfiguration: config)
        button.setImage(image, for: .normal)
        button.tintColor = UIColor.white.withAlphaComponent(0.9)
        button.backgroundColor = UIColor.black.withAlphaComponent(0.25)
        button.layer.cornerRadius = 13
        button.clipsToBounds = true
    }
}

// MARK: - Window Logic

private extension ZoneSelectorView {

    /// Visible slice of allItems based on current windowStart
    var visibleItems: [String] {
        let end = min(windowStart + maxVisible, allItems.count)
        guard end > windowStart else { return [] }
        return Array(allItems[windowStart..<end])
    }

    /// Local index (0–2) of selected item within visible window; -1 if not visible
    var selectedLocalIndex: Int {
        let local = selectedGlobalIndex - windowStart
        return (local >= 0 && local < visibleItems.count) ? local : -1
    }

    /// Best windowStart so the selected item is visible, clamped to valid range
    func clampedWindowStart(for globalIndex: Int) -> Int {
        guard !allItems.isEmpty else { return 0 }
        let maxStart = max(0, allItems.count - maxVisible)
        let ideal = globalIndex - (maxVisible / 2)
        return min(max(0, ideal), maxStart)
    }

    func applyBorderColor(_ hex: String?) {
        if let hex = hex, !hex.isEmpty {
            pillContainer.layer.borderColor = UIColor(hex: hex).cgColor
        } else {
            pillContainer.layer.borderColor = UIColor.white.cgColor
        }
    }
}

// MARK: - Render

private extension ZoneSelectorView {

    func renderVisible(slideDir: PageDirection) {
        updateArrowState()

        let update = { [weak self] in
            guard let self else { return }
            self.rebuildSegmentButtons()
            self.setNeedsLayout()
            self.layoutIfNeeded()
            self.needsSelectionLayoutUpdate = true
            self.updateSelection(animated: false)
        }

        if slideDir != .none {
            animatePageChange(direction: slideDir, update: update)
        } else {
            update()
        }
    }

    func rebuildSegmentButtons() {
        // Remove old buttons
        for btn in segmentsStack.arrangedSubviews {
            segmentsStack.removeArrangedSubview(btn)
            btn.removeFromSuperview()
        }

        let visible = visibleItems
        guard !visible.isEmpty else {
            selectionView.isHidden = true
            return
        }

        let totalWidth = pillContainer.bounds.width - 80 // 80 = space for both arrows + spacing
        let itemWidth = totalWidth / CGFloat(maxVisible)

        for (localIndex, title) in visible.enumerated() {
            let button = UIButton(type: .system)
            button.setTitle(title, for: .normal)
            button.setTitleColor(.white, for: .normal)
            button.titleLabel?.font = .systemFont(ofSize: 14, weight: .semibold)
            button.backgroundColor = .clear
            button.clipsToBounds = true
            button.tag = localIndex // tag = local index (0, 1, 2)
            button.widthAnchor.constraint(equalToConstant: itemWidth).isActive = true
            button.addTarget(self, action: #selector(didTapSegment(_:)), for: .touchUpInside)
            segmentsStack.addArrangedSubview(button)
        }

        selectionView.isHidden = false
    }

    func updateArrowState() {
        leftButton.isHidden = false
        rightButton.isHidden = false
        setArrow(leftButton, enabled: windowStart > 0)
        setArrow(rightButton, enabled: windowStart + maxVisible < allItems.count)
    }

    func setArrow(_ button: UIButton, enabled: Bool) {
        button.isEnabled = enabled
        UIView.animate(withDuration: 0.15) {
            button.alpha = enabled ? 1.0 : 0.35
        }
    }

    func updateSelection(animated: Bool) {
        let buttons = segmentsStack.arrangedSubviews.compactMap { $0 as? UIButton }
        let local = selectedLocalIndex

        guard !buttons.isEmpty, local >= 0, local < buttons.count else {
            selectionView.isHidden = true
            selectionView.alpha = 0
            return
        }

        guard buttons[local].bounds.width > 0 else {
            needsSelectionLayoutUpdate = true
            return
        }

        // Don't force isHidden/alpha here — let animatePageChange control visibility during slides
        selectionView.isHidden = false

        let selectedButton = buttons[local]
        let frameInPill = selectedButton.superview?.convert(selectedButton.frame, to: pillContainer) ?? .zero
        let targetFrame = frameInPill.insetBy(dx: -6, dy: 1)

        for (index, btn) in buttons.enumerated() {
            btn.alpha = (index == local) ? 1.0 : 0.75
        }

        let applyFrame = {
            self.selectionView.frame = targetFrame
            self.selectionView.layer.cornerRadius = targetFrame.height / 2
        }

        if animated {
            UIView.animate(
                withDuration: 0.25, delay: 0,
                usingSpringWithDamping: 0.88, initialSpringVelocity: 0.25,
                options: [.beginFromCurrentState, .curveEaseOut],
                animations: applyFrame
            )
        } else {
            applyFrame()
        }
    }
}

// MARK: - Actions

private extension ZoneSelectorView {

    @objc func didTapLeft() {
        guard windowStart > 0 else { return }
        AppHaptic.selectionChanged()
        windowStart -= 1
        renderVisible(slideDir: .prev)
        onPrevPage?()
    }

    @objc func didTapRight() {
        guard windowStart + maxVisible < allItems.count else { return }
        AppHaptic.selectionChanged()
        windowStart += 1
        renderVisible(slideDir: .next)
        onNextPage?()
    }

    @objc func didTapSegment(_ sender: UIButton) {
        let newGlobal = windowStart + sender.tag
        guard allItems.indices.contains(newGlobal) else { return }

        AppHaptic.selectionChanged()
        selectedGlobalIndex = newGlobal
        updateSelection(animated: true)
        emitSelection()

        // Tap bounce animation
        UIView.animate(withDuration: 0.12, animations: {
            sender.transform = CGAffineTransform(scaleX: 0.93, y: 0.93)
        }, completion: { _ in
            UIView.animate(withDuration: 0.15) { sender.transform = .identity }
        })
    }

    @objc func handleSwipe(_ gesture: UISwipeGestureRecognizer) {
        switch gesture.direction {
        case .left: didTapRight()
        case .right: didTapLeft()
        default: break
        }
    }

    func emitSelection() {
        guard allItems.indices.contains(selectedGlobalIndex) else { return }
        onSelectItem?(allItems[selectedGlobalIndex], selectedGlobalIndex)
    }
}

// MARK: - Page Transition Animation

private extension ZoneSelectorView {

    func animatePageChange(direction: PageDirection, update: @escaping () -> Void) {
        let offset: CGFloat = direction == .next ? -60 : 60

        selectionView.isHidden = true
        selectionView.alpha = 0

        UIView.animate(withDuration: 0.20, delay: 0, options: .curveEaseIn) {
            self.segmentsStack.transform = CGAffineTransform(translationX: offset, y: 0)
            self.segmentsStack.alpha = 0
        } completion: { _ in
            update()
            self.segmentsStack.transform = CGAffineTransform(translationX: -offset, y: 0)

            UIView.animate(
                withDuration: 0.35, delay: 0,
                usingSpringWithDamping: 0.85, initialSpringVelocity: 0.3,
                options: .curveEaseOut
            ) {
                self.segmentsStack.transform = .identity
                self.segmentsStack.alpha = 1
            } completion: { _ in
                self.needsSelectionLayoutUpdate = false
                self.updateSelection(animated: false)
                UIView.animate(withDuration: 0.15) {
                    self.selectionView.alpha = 1
                }
            }
        }
    }
}
