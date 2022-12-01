import Parchment
import UIKit

struct IconItem: PagingItem, Hashable {
    let icon: String
    let index: Int
    let image: UIImage?

    init(icon: String, index: Int) {
        self.icon = icon
        self.index = index
        image = UIImage(named: icon)
    }

    /// By default, isBefore is implemented when the PagingItem conforms
    /// to Comparable, but in this case we want a custom implementation
    /// where we also compare IconItem with PagingIndexItem. This
    /// ensures that we animate the page transition in the correct
    /// direction when selecting items.
    func isBefore(item: PagingItem) -> Bool {
        if let item = item as? PagingIndexItem {
            return index < item.index
        } else if let item = item as? Self {
            return index < item.index
        } else {
            return false
        }
    }
}

class IconsViewController: UIViewController {
    // Let's start by creating an array of icon names that
    // we will use to generate some view controllers.
    fileprivate let icons = [
        "compass",
        "cloud",
        "bonnet",
        "axe",
        "earth",
        "knife",
        "leave",
        "light",
        "map",
        "moon",
        "mushroom",
        "shoes",
        "snow",
        "star",
        "sun",
        "tipi",
        "tree",
        "water",
        "wind",
        "wood",
    ]

    override func viewDidLoad() {
        super.viewDidLoad()

        let pagingViewController = PagingViewController()
        pagingViewController.register(IconPagingCell.self, for: IconItem.self)
        pagingViewController.menuItemSize = .fixed(width: 60, height: 60)
        pagingViewController.dataSource = self
        pagingViewController.select(pagingItem: IconItem(icon: icons[0], index: 0))

        // Add the paging view controller as a child view controller
        // and contrain it to all edges.
        addChild(pagingViewController)
        view.addSubview(pagingViewController.view)
        view.constrainToEdges(pagingViewController.view)
        pagingViewController.didMove(toParent: self)
    }
}

extension IconsViewController: PagingViewControllerDataSource {
    func pagingViewController(_: PagingViewController, viewControllerAt index: Int) -> UIViewController {
        return IconViewController(title: icons[index].capitalized)
    }

    func pagingViewController(_: PagingViewController, pagingItemAt index: Int) -> PagingItem {
        return IconItem(icon: icons[index], index: index)
    }

    func numberOfViewControllers(in _: PagingViewController) -> Int {
        return icons.count
    }
}
