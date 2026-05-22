//
//  FiltersViewController.swift
//  SpeakEasy-Consumer
//
//  Created by Square Infosoft on 18/05/26.
//

import UIKit

class FiltersViewController: UIViewController {

    @IBOutlet weak var collectionView: UICollectionView!
    
    private let filters = ["Free entrance", "VIP", "Rooftops", "VIP Tables", "VIP Tables"]
    private var selectedIndexes: Set<Int> = [0] // First item selected by default

    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupCollectionView()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        self.view.applyScreenBgGradient(direction: .bottomToTop)
    }

    // MARK: - Setup
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.backgroundColor = .clear
        collectionView.contentInset = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

        // Register XIB-based DateSelectionCVC
        let nib = UINib(nibName: "DateSelectionCVC", bundle: nil)
        collectionView.register(nib, forCellWithReuseIdentifier: "DateSelectionCVC")

        // Left-aligned layout with auto-sizing
        let layout = LeftAlignedFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 12
        layout.estimatedItemSize = UICollectionViewFlowLayout.automaticSize
        collectionView.collectionViewLayout = layout
    }

    // MARK: - Actions
    @IBAction func closeTapped(_ sender: UIButton) {
        dismiss(animated: true)
    }

    @IBAction func resetTapped(_ sender: UIButton) {
        selectedIndexes.removeAll()
        collectionView.reloadData()
    }

    @IBAction func applyFiltersTapped(_ sender: UIButton) {
        let selected = selectedIndexes.map { filters[$0] }
        print("Applied filters: \(selected)")
        dismiss(animated: true)
    }
}

// MARK: - UICollectionViewDataSource
extension FiltersViewController: UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView,
                        numberOfItemsInSection section: Int) -> Int {
        return filters.count
    }

    func collectionView(_ collectionView: UICollectionView,
                        cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(
            withReuseIdentifier: "DateSelectionCVC",
            for: indexPath
        ) as! DateSelectionCVC

        cell.configure(
            with: filters[indexPath.item],
            isSelected: selectedIndexes.contains(indexPath.item),
            cellType: .filter
        )
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FiltersViewController: UICollectionViewDelegate {

    func collectionView(_ collectionView: UICollectionView,
                        didSelectItemAt indexPath: IndexPath) {
        if selectedIndexes.contains(indexPath.item) {
            selectedIndexes.remove(indexPath.item)
        } else {
            selectedIndexes.insert(indexPath.item)
        }
        // Reload only the tapped cell for smooth animation
        collectionView.reloadItems(at: [indexPath])
    }
}


final class LeftAlignedFlowLayout: UICollectionViewFlowLayout {

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {

        guard let attributes = super.layoutAttributesForElements(in: rect) else { return nil }

        // Deep-copy to avoid mutating cached attributes (required per Apple docs)
        let copied = attributes.map { $0.copy() as! UICollectionViewLayoutAttributes }

        var leftEdge: CGFloat = sectionInset.left
        var prevMaxY: CGFloat = -1

        for attr in copied where attr.representedElementCategory == .cell {
            // New row detected when Y changes
            if attr.frame.minY > prevMaxY {
                leftEdge = sectionInset.left
            }
            attr.frame.origin.x = leftEdge
            leftEdge += attr.frame.width + minimumInteritemSpacing
            prevMaxY = max(attr.frame.maxY, prevMaxY)
        }

        return copied
    }
}
