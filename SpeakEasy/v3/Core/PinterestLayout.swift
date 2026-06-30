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

    // MARK: - Config

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
    
    var headerElementKind =
        UICollectionView.elementKindSectionHeader

    var footerElementKind =
        UICollectionView.elementKindSectionFooter
    
    // MARK: - Private

    private var cache:
        [UICollectionViewLayoutAttributes] = []

    private var contentHeight: CGFloat = 0

    private var contentWidth: CGFloat {

        guard let collectionView = collectionView else {
            return 0
        }

        let insets =
            collectionView.adjustedContentInset

        return collectionView.bounds.width -
        (insets.left + insets.right)
    }

    // MARK: - Content Size

    override var collectionViewContentSize: CGSize {

        CGSize(
            width: contentWidth,
            height: contentHeight
        )
    }

    // MARK: - Prepare
    override func prepare() {

        super.prepare()

        guard
            cache.isEmpty,
            let collectionView = collectionView
        else {
            return
        }

        let availableWidth =
            contentWidth -
            sectionInsets.left -
            sectionInsets.right

        let columnWidth =
            (
                availableWidth -
                (CGFloat(numberOfColumns - 1)
                 * interItemSpacing)
            ) / CGFloat(numberOfColumns)

        var xOffsets: [CGFloat] = []

        for column in 0..<numberOfColumns {

            let x =
                sectionInsets.left +
                CGFloat(column) *
                (
                    columnWidth +
                    interItemSpacing
                )

            xOffsets.append(x)
        }

        var yOffsets =
            Array(
                repeating: sectionInsets.top,
                count: numberOfColumns
            )

        // MARK: - Sections

        for section in 0..<collectionView.numberOfSections {
            
            // MARK: Header
            if showsHeaders {
                let headerHeight =
                delegate?.collectionView(
                    collectionView,
                    referenceHeightForHeaderIn: section
                ) ?? 48
                
                let currentTop =
                yOffsets.max() ?? 0
                
                let headerAttributes =
                UICollectionViewLayoutAttributes(
                    forSupplementaryViewOfKind:
                        headerElementKind,
                    with: IndexPath(
                        item: 0,
                        section: section
                    )
                )
                
                headerAttributes.frame = CGRect(
                    x: 0,
                    y: currentTop,
                    width: contentWidth,
                    height: headerHeight
                )
                
                cache.append(headerAttributes)
                
                // Reset columns below header
                yOffsets =
                Array(
                    repeating:
                        headerAttributes.frame.maxY + headerToItemsSpacing,
                    count: numberOfColumns
                )
            }

            // MARK: Items
            
            let itemCount =
                collectionView.numberOfItems(
                    inSection: section
                )

            for item in 0..<itemCount {

                let indexPath = IndexPath(
                    item: item,
                    section: section
                )

                // shortest column
                let shortestColumn =
                    yOffsets.enumerated().min {
                        $0.element < $1.element
                    }?.offset ?? 0

                // dynamic height
                let itemHeight =
                    delegate?.collectionView(
                        collectionView,
                        heightForItemAt: indexPath,
                        with: columnWidth
                    ) ?? 250

                let frame = CGRect(
                    x: xOffsets[shortestColumn],
                    y: yOffsets[shortestColumn],
                    width: columnWidth,
                    height: itemHeight
                )

                let attributes =
                    UICollectionViewLayoutAttributes(
                        forCellWith: indexPath
                    )

                attributes.frame = frame.integral

                cache.append(attributes)

                yOffsets[shortestColumn] =
                    frame.maxY + lineSpacing

                contentHeight =
                    max(
                        contentHeight,
                        frame.maxY
                    )
            }

            // spacing between sections
            let maxY =
                yOffsets.max() ?? 0

            // MARK: Footer

            let footerHeight: CGFloat =
                delegate?.collectionView(
                    collectionView,
                    referenceHeightForFooterIn: section
                ) ?? 0

            if footerHeight > 0 {

                let footerAttributes =
                    UICollectionViewLayoutAttributes(
                        forSupplementaryViewOfKind:
                            footerElementKind,
                        with: IndexPath(
                            item: 0,
                            section: section
                        )
                    )

                footerAttributes.frame = CGRect(
                    x: 0,
                    y: maxY,
                    width: contentWidth,
                    height: footerHeight
                )

                cache.append(footerAttributes)

                contentHeight =
                    footerAttributes.frame.maxY

                yOffsets = Array(
                    repeating:
                        footerAttributes.frame.maxY + 10,
                    count: numberOfColumns
                )

            } else {

                yOffsets = Array(
                    repeating: maxY + 10,
                    count: numberOfColumns
                )
            }
        }

        contentHeight += sectionInsets.bottom
    }

    // MARK: - Layout Attributes

    override func layoutAttributesForElements(
        in rect: CGRect
    ) -> [UICollectionViewLayoutAttributes]? {

        cache.filter {
            $0.frame.intersects(rect)
        }
    }

    override func layoutAttributesForItem(
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {

        cache.first {
            $0.indexPath == indexPath &&
            $0.representedElementCategory == .cell
        }
    }

    override func layoutAttributesForSupplementaryView(
        ofKind elementKind: String,
        at indexPath: IndexPath
    ) -> UICollectionViewLayoutAttributes? {

        cache.first {

            $0.indexPath == indexPath &&
            $0.representedElementKind == elementKind
        }
    }

    // MARK: - Invalidate

    override func invalidateLayout() {

        super.invalidateLayout()

        cache.removeAll()

        contentHeight = 0
    }
    
    func invalidateFooter() {

        guard
            let collectionView = collectionView
        else {
            return
        }

        let context =
            UICollectionViewLayoutInvalidationContext()

        let indexPaths =
            (0..<collectionView.numberOfSections).map {

                IndexPath(
                    item: 0,
                    section: $0
                )
            }

        context.invalidateSupplementaryElements(
            ofKind:
                UICollectionView.elementKindSectionFooter,
            at: indexPaths
        )

        invalidateLayout(
            with: context
        )
    }

}
