//
//  ImagePagerVC.swift
//  SpeakEasy-Consumer
//
//  Created by MAC on 25/03/26.
//

import Foundation
import UIKit

class ImagePagerVC: UIPageViewController {

    var imageURLs: [String] = []
    private var pages: [ImagePageVC] = []
    private(set) var currentIndex = 0
    private var isTransitioning = false

    override func viewDidLoad() {
        super.viewDidLoad()
        dataSource = self
        delegate = self
    }

    func setImages(_ urls: [String]) {
        imageURLs = urls
        buildPages()

        currentIndex = 0
        if let firstVC = pages.first {
            setViewControllers([firstVC], direction: .forward, animated: false)
        }
    }

    private func syncCurrentIndexFromVisible() {
        guard let visible = viewControllers?.first as? ImagePageVC,
              let idx = pages.firstIndex(where: { $0 === visible }) else { return }
        currentIndex = idx
    }

    private func buildPages() {
        pages = imageURLs.map { url in
            let vc = ImagePageVC()
            vc.imageURL = url
            return vc
        }

        currentIndex = 0
        guard let first = pages.first else { return }
        setViewControllers([first], direction: .forward, animated: false)
    }

    func moveNext() {
        guard pages.count > 1, !isTransitioning else { return }
        syncCurrentIndexFromVisible()

        let nextIndex = (currentIndex + 1) % pages.count
        isTransitioning = true
        setViewControllers([pages[nextIndex]], direction: .forward, animated: true) { [weak self] finished in
            guard let self else { return }
            self.isTransitioning = false
            if finished { self.currentIndex = nextIndex }
        }
    }

    func movePrevious() {
        guard pages.count > 1, !isTransitioning else { return }
        syncCurrentIndexFromVisible()

        let prevIndex = (currentIndex - 1 + pages.count) % pages.count
        isTransitioning = true
        setViewControllers([pages[prevIndex]], direction: .reverse, animated: true) { [weak self] finished in
            guard let self else { return }
            self.isTransitioning = false
            if finished { self.currentIndex = prevIndex }
        }
    }
}

extension ImagePagerVC: UIPageViewControllerDataSource, UIPageViewControllerDelegate {

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard pages.count > 1,
              let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(where: { $0 === vc }) else { return nil }

        let prev = (index - 1 + pages.count) % pages.count
        return pages[prev]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard pages.count > 1,
              let vc = viewController as? ImagePageVC,
              let index = pages.firstIndex(where: { $0 === vc }) else { return nil }

        let next = (index + 1) % pages.count
        return pages[next]
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            willTransitionTo pendingViewControllers: [UIViewController]) {
        isTransitioning = true
    }

    func pageViewController(_ pageViewController: UIPageViewController,
                            didFinishAnimating finished: Bool,
                            previousViewControllers: [UIViewController],
                            transitionCompleted completed: Bool) {

        isTransitioning = false

        guard completed,
              let visible = viewControllers?.first as? ImagePageVC,
              let idx = pages.firstIndex(where: { $0 === visible }) else { return }

        currentIndex = idx
    }
}
