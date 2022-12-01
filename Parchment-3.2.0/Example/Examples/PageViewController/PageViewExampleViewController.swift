import Parchment
import UIKit

/// Parchment provides a custom `UIPageViewController` alternative
/// if you need better delegate methods called `PageViewController`.
class PageViewExampleViewController: UIViewController {
    let viewControllers: [UIViewController] = [
        ContentViewController(index: 0),
        ContentViewController(index: 1),
        ContentViewController(index: 2),
        ContentViewController(index: 3),
        ContentViewController(index: 4),
    ]

    override func viewDidLoad() {
        let pageViewController = PageViewController()
        pageViewController.dataSource = self
        pageViewController.delegate = self
        pageViewController.selectViewController(viewControllers[0], direction: .none)

        addChild(pageViewController)
        view.addSubview(pageViewController.view)
        view.constrainToEdges(pageViewController.view)
        pageViewController.didMove(toParent: self)
    }
}

extension PageViewExampleViewController: PageViewControllerDataSource {
    func pageViewController(
        _: PageViewController,
        viewControllerBeforeViewController viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController) else { return nil }
        if index > 0 {
            return viewControllers[index - 1]
        }
        return nil
    }

    func pageViewController(
        _: PageViewController,
        viewControllerAfterViewController viewController: UIViewController
    ) -> UIViewController? {
        guard let index = viewControllers.firstIndex(of: viewController) else { return nil }
        if index < viewControllers.count - 1 {
            return viewControllers[index + 1]
        }
        return nil
    }
}

extension PageViewExampleViewController: PageViewControllerDelegate {
    func pageViewController(_: PageViewController, willStartScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController) {
        print("willStartScrollingFrom: ",
              startingViewController.title ?? "",
              destinationViewController.title ?? "")
    }

    func pageViewController(_: PageViewController, isScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController?, progress: CGFloat) {
        print("isScrollingFrom: ",
              startingViewController.title ?? "",
              destinationViewController?.title ?? "",
              progress)
    }

    func pageViewController(_: PageViewController, didFinishScrollingFrom startingViewController: UIViewController, destinationViewController: UIViewController, transitionSuccessful: Bool) {
        print("didFinishScrollingFrom: ",
              startingViewController.title ?? "",
              destinationViewController.title ?? "",
              transitionSuccessful)
    }
}
