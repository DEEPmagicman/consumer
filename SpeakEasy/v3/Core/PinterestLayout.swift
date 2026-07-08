import UIKit

protocol PinterestLayoutDelegate: AnyObject {

    func collectionView(
        _ collectionView: UICollectionView,
        heightForItemAt indexPath: IndexPath,
        with width: CGFloat
    ) -> CGFloat

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat
}

extension PinterestLayoutDelegate {

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForHeaderIn section: Int
    ) -> CGFloat {
        return 48
    }

    func collectionView(
        _ collectionView: UICollectionView,
        referenceHeightForFooterIn section: Int
    ) -> CGFloat {
        return 0
    }
}

final class PinterestLayout: UICollectionViewLayout {

    weak var delegate: PinterestLayoutDelegate?

    var numberOfColumns: Int = 2

    var sectionInsets = UIEdgeInsets(
        top: 0,
        left: 24,
        bottom: 34,
        right: 24
    )

    var interItemSpacing: CGFloat = 10
    var lineSpacing: CGFloat = 22
    var showsHeaders = false
    var headerToItemsSpacing: CGFloat = 8
    var headerElementKind = UICollectionView.elementKindSectionHeader
    var footerElementKind = UICollectionView.elementKindSectionFooter

    private var allAttributes: [UICollectionViewLayoutAttributes] = []
    private var visibleAttributes: [UICollectionViewLayoutAttributes] = []
    private var cellAttributes: [IndexPath: UICollectionViewLayoutAttributes] = [:]
    private var supplementaryAttributes: [String: UICollectionViewLayoutAttributes] = [:]
    private var contentHeight: CGFloat = 0
    private var preparedWidth: CGFloat = 0
    private var preparedItemCounts: [Int] = []
    private var preparedHeaderHeights: [CGFloat] = []
    private var preparedFooterHeights: [CGFloat] = []
    private var maxAttributeHeight: CGFloat = 0

    private var contentWidth: CGFloat {
        guard let collectionView = collectionView else { return 0 }
        let insets = collectionView.adjustedContentInset
        return collectionView.bounds.width - insets.left - insets.right
    }

    override var collectionViewContentSize: CGSize {
        CGSize(width: contentWidth, height: contentHeight)
    }

    override func prepare() {
        super.prepare()

        guard let collectionView = collectionView else { return }

        let currentWidth = contentWidth
        let sectionCount = collectionView.numberOfSections
        let itemCounts = (0..<sectionCount).map {
            collectionView.numberOfItems(inSection: $0)
        }
        let headerHeights = (0..<sectionCount).map {
            showsHeaders
                ? (delegate?.collectionView(collectionView, referenceHeightForHeaderIn: $0) ?? 48)
                : 0
        }
        let footerHeights = (0..<sectionCount).map {
            delegate?.collectionView(collectionView, referenceHeightForFooterIn: $0) ?? 0
        }

        guard allAttributes.isEmpty
                || abs(preparedWidth - currentWidth) > 0.5
                || preparedItemCounts != itemCounts
                || preparedHeaderHeights != headerHeights
                || preparedFooterHeights != footerHeights else {
            return
        }

        rebuildLayout(
            collectionView: collectionView,
            width: currentWidth,
            itemCounts: itemCounts,
            headerHeights: headerHeights,
            footerHeights: footerHeights
        )
    }

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {
        guard !visibleAttributes.isEmpty else { return [] }

        let startIndex = lowerBoundForMinY(rect.minY - maxAttributeHeight)
        var scanIndex = startIndex

        while scanIndex > 0,
              visibleAttributes[scanIndex - 1].frame.maxY >= rect.minY {
            scanIndex -= 1
        }

        var result: [UICollectionViewLayoutAttributes] = []
        result.reserveCapacity(16)

        while scanIndex < visibleAttributes.count {
            let attributes = visibleAttributes[scanIndex]
            if attributes.frame.minY > rect.maxY {
                break
            }

            if attributes.frame.intersects(rect) {
                result.append(attributes)
            }

            scanIndex += 1
        }

        return result
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        cellAttributes[indexPath]
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {
        supplementaryAttributes[supplementaryKey(kind: elementKind, indexPath: indexPath)]
    }

    override func shouldInvalidateLayout(
        forBoundsChange newBounds: CGRect
    ) -> Bool {
        guard let collectionView = collectionView else { return false }
        return abs(collectionView.bounds.width - newBounds.width) > 0.5
    }

    override func invalidateLayout() {
        super.invalidateLayout()
        clearCache()
    }

    override func invalidateLayout(
        with context: UICollectionViewLayoutInvalidationContext
    ) {
        super.invalidateLayout(with: context)
        clearCache()
    }

    func invalidateFooter() {
        guard let collectionView = collectionView else { return }

        let context = UICollectionViewLayoutInvalidationContext()
        let indexPaths = (0..<collectionView.numberOfSections).map {
            IndexPath(item: 0, section: $0)
        }

        context.invalidateSupplementaryElements(
            ofKind: footerElementKind,
            at: indexPaths
        )
        invalidateLayout(with: context)
    }
}

private extension PinterestLayout {

    func rebuildLayout(
        collectionView: UICollectionView,
        width: CGFloat,
        itemCounts: [Int],
        headerHeights: [CGFloat],
        footerHeights: [CGFloat]
    ) {
        clearCache()

        preparedWidth = width
        preparedItemCounts = itemCounts
        preparedHeaderHeights = headerHeights
        preparedFooterHeights = footerHeights

        let columnCount = max(1, numberOfColumns)
        let availableWidth = width - sectionInsets.left - sectionInsets.right
        let columnWidth = (
            availableWidth - CGFloat(columnCount - 1) * interItemSpacing
        ) / CGFloat(columnCount)
        let xOffsets = (0..<columnCount).map { column in
            sectionInsets.left + CGFloat(column) * (columnWidth + interItemSpacing)
        }

        var yOffsets = Array(repeating: sectionInsets.top, count: columnCount)

        for section in 0..<collectionView.numberOfSections {
            if showsHeaders {
                let headerAttributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: headerElementKind,
                    with: IndexPath(item: 0, section: section)
                )
                headerAttributes.frame = CGRect(
                    x: 0,
                    y: yOffsets.max() ?? 0,
                    width: width,
                    height: headerHeights[section]
                )
                store(headerAttributes)

                yOffsets = Array(
                    repeating: headerAttributes.frame.maxY + headerToItemsSpacing,
                    count: columnCount
                )
            }

            for item in 0..<itemCounts[section] {
                let indexPath = IndexPath(item: item, section: section)
                let column = shortestColumn(in: yOffsets)
                let itemHeight = delegate?.collectionView(
                    collectionView,
                    heightForItemAt: indexPath,
                    with: columnWidth
                ) ?? 250

                let attributes = UICollectionViewLayoutAttributes(forCellWith: indexPath)
                attributes.frame = CGRect(
                    x: xOffsets[column],
                    y: yOffsets[column],
                    width: columnWidth,
                    height: itemHeight
                ).integral
                store(attributes)

                yOffsets[column] = attributes.frame.maxY + lineSpacing
                contentHeight = max(contentHeight, attributes.frame.maxY)
            }

            let maxY = yOffsets.max() ?? 0
            let footerHeight = footerHeights[section]

            if footerHeight > 0 {
                let footerAttributes = UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind: footerElementKind,
                    with: IndexPath(item: 0, section: section)
                )
                footerAttributes.frame = CGRect(
                    x: 0,
                    y: maxY,
                    width: width,
                    height: footerHeight
                )
                store(footerAttributes)
                contentHeight = footerAttributes.frame.maxY
                yOffsets = Array(
                    repeating: footerAttributes.frame.maxY + 10,
                    count: columnCount
                )
            } else {
                contentHeight = max(contentHeight, maxY)
                yOffsets = Array(repeating: maxY + 10, count: columnCount)
            }
        }

        contentHeight += sectionInsets.bottom
        visibleAttributes = allAttributes.sorted {
            if $0.frame.minY == $1.frame.minY {
                return $0.frame.minX < $1.frame.minX
            }

            return $0.frame.minY < $1.frame.minY
        }
    }

    func lowerBoundForMinY(_ minY: CGFloat) -> Int {
        var lower = 0
        var upper = visibleAttributes.count

        while lower < upper {
            let middle = (lower + upper) / 2
            if visibleAttributes[middle].frame.minY < minY {
                lower = middle + 1
            } else {
                upper = middle
            }
        }

        return lower
    }

    func shortestColumn(in yOffsets: [CGFloat]) -> Int {
        yOffsets.enumerated().min { $0.element < $1.element }?.offset ?? 0
    }

    func store(_ attributes: UICollectionViewLayoutAttributes) {
        allAttributes.append(attributes)
        maxAttributeHeight = max(maxAttributeHeight, attributes.frame.height)

        switch attributes.representedElementCategory {
        case .cell:
            cellAttributes[attributes.indexPath] = attributes
        case .supplementaryView:
            if let kind = attributes.representedElementKind {
                supplementaryAttributes[
                    supplementaryKey(kind: kind, indexPath: attributes.indexPath)
                ] = attributes
            }
        default:
            break
        }
    }

    func clearCache() {
        allAttributes.removeAll(keepingCapacity: true)
        visibleAttributes.removeAll(keepingCapacity: true)
        cellAttributes.removeAll(keepingCapacity: true)
        supplementaryAttributes.removeAll(keepingCapacity: true)
        contentHeight = 0
        maxAttributeHeight = 0
        preparedWidth = 0
        preparedItemCounts.removeAll(keepingCapacity: true)
        preparedHeaderHeights.removeAll(keepingCapacity: true)
        preparedFooterHeights.removeAll(keepingCapacity: true)
    }

    func supplementaryKey(kind: String, indexPath: IndexPath) -> String {
        "\(kind)-\(indexPath.section)-\(indexPath.item)"
    }
}
