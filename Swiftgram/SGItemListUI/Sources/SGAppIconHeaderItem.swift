import Foundation
import UIKit
import Display
import AsyncDisplayKit
import SwiftSignalKit
import TelegramPresentationData
import ItemListUI
import AppBundle

// MARK: Symonagram — app-icon hero row for the root settings screen
public class SGAppIconHeaderItem: ListViewItem, ItemListItem {
    let theme: PresentationTheme
    let iconName: String
    let title: String
    let version: String
    public let sectionId: ItemListSectionId

    public init(theme: PresentationTheme, iconName: String, title: String, version: String, sectionId: ItemListSectionId) {
        self.theme = theme
        self.iconName = iconName
        self.title = title
        self.version = version
        self.sectionId = sectionId
    }

    public func nodeConfiguredForParams(async: @escaping (@escaping () -> Void) -> Void, params: ListViewItemLayoutParams, synchronousLoads: Bool, previousItem: ListViewItem?, nextItem: ListViewItem?, completion: @escaping (ListViewItemNode, @escaping () -> (Signal<Void, NoError>?, (ListViewItemApply) -> Void)) -> Void) {
        async {
            let node = SGAppIconHeaderItemNode()
            let (layout, apply) = node.asyncLayout()(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))

            node.contentSize = layout.contentSize
            node.insets = layout.insets

            Queue.mainQueue().async {
                completion(node, {
                    return (nil, { _ in apply() })
                })
            }
        }
    }

    public func updateNode(async: @escaping (@escaping () -> Void) -> Void, node: @escaping () -> ListViewItemNode, params: ListViewItemLayoutParams, previousItem: ListViewItem?, nextItem: ListViewItem?, animation: ListViewItemUpdateAnimation, completion: @escaping (ListViewItemNodeLayout, @escaping (ListViewItemApply) -> Void) -> Void) {
        Queue.mainQueue().async {
            guard let nodeValue = node() as? SGAppIconHeaderItemNode else {
                assertionFailure()
                return
            }

            let makeLayout = nodeValue.asyncLayout()

            async {
                let (layout, apply) = makeLayout(self, params, itemListNeighbors(item: self, topItem: previousItem as? ItemListItem, bottomItem: nextItem as? ItemListItem))
                Queue.mainQueue().async {
                    completion(layout, { _ in
                        apply()
                    })
                }
            }
        }
    }
}

private let titleFont = Font.semibold(22.0)
private let versionFont = Font.regular(15.0)

class SGAppIconHeaderItemNode: ListViewItemNode {
    private let iconNode: ASImageNode
    private let titleNode: TextNode
    private let versionNode: TextNode

    private var item: SGAppIconHeaderItem?

    init() {
        self.iconNode = ASImageNode()
        self.iconNode.isUserInteractionEnabled = false
        self.iconNode.displaysAsynchronously = false
        self.iconNode.displayWithoutProcessing = true
        self.iconNode.contentMode = .scaleAspectFit

        self.titleNode = TextNode()
        self.titleNode.isUserInteractionEnabled = false
        self.titleNode.contentMode = .center
        self.titleNode.contentsScale = UIScreen.main.scale

        self.versionNode = TextNode()
        self.versionNode.isUserInteractionEnabled = false
        self.versionNode.contentMode = .center
        self.versionNode.contentsScale = UIScreen.main.scale

        super.init(layerBacked: false)

        self.addSubnode(self.iconNode)
        self.addSubnode(self.titleNode)
        self.addSubnode(self.versionNode)
    }

    func asyncLayout() -> (_ item: SGAppIconHeaderItem, _ params: ListViewItemLayoutParams, _ neighbors: ItemListNeighbors) -> (ListViewItemNodeLayout, () -> Void) {
        let makeTitleLayout = TextNode.asyncLayout(self.titleNode)
        let makeVersionLayout = TextNode.asyncLayout(self.versionNode)

        return { item, params, neighbors in
            let iconSize = CGSize(width: 90.0, height: 90.0)
            let topInset: CGFloat = 24.0
            let iconTitleSpacing: CGFloat = 12.0
            let titleVersionSpacing: CGFloat = 3.0
            let bottomInset: CGFloat = 20.0

            let icon = UIImage(bundleImageName: item.iconName)

            let constrainedWidth = params.width - params.leftInset - params.rightInset - 40.0

            let titleString = NSAttributedString(string: item.title, font: titleFont, textColor: item.theme.list.itemPrimaryTextColor)
            let (titleLayout, titleApply) = makeTitleLayout(TextNodeLayoutArguments(attributedString: titleString, backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: constrainedWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))

            let versionString = NSAttributedString(string: item.version, font: versionFont, textColor: item.theme.list.itemSecondaryTextColor)
            let (versionLayout, versionApply) = makeVersionLayout(TextNodeLayoutArguments(attributedString: versionString, backgroundColor: nil, maximumNumberOfLines: 1, truncationType: .end, constrainedSize: CGSize(width: constrainedWidth, height: CGFloat.greatestFiniteMagnitude), alignment: .center, cutout: nil, insets: UIEdgeInsets()))

            let contentHeight = topInset + iconSize.height + iconTitleSpacing + titleLayout.size.height + titleVersionSpacing + versionLayout.size.height + bottomInset
            let contentSize = CGSize(width: params.width, height: contentHeight)
            let insets = itemListNeighborsGroupedInsets(neighbors, params)

            let layout = ListViewItemNodeLayout(contentSize: contentSize, insets: insets)

            return (layout, { [weak self] in
                guard let strongSelf = self else {
                    return
                }
                strongSelf.item = item

                strongSelf.iconNode.image = icon
                strongSelf.iconNode.frame = CGRect(origin: CGPoint(x: floor((params.width - iconSize.width) / 2.0), y: topInset), size: iconSize)

                let _ = titleApply()
                let titleY = topInset + iconSize.height + iconTitleSpacing
                strongSelf.titleNode.frame = CGRect(origin: CGPoint(x: floor((params.width - titleLayout.size.width) / 2.0), y: titleY), size: titleLayout.size)

                let _ = versionApply()
                let versionY = titleY + titleLayout.size.height + titleVersionSpacing
                strongSelf.versionNode.frame = CGRect(origin: CGPoint(x: floor((params.width - versionLayout.size.width) / 2.0), y: versionY), size: versionLayout.size)
            })
        }
    }
}
