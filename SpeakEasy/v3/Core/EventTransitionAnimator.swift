import UIKit

final class EventTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {

    let imageView: UIImageView

    init(imageView: UIImageView) {
        self.imageView = imageView
    }

    func transitionDuration(
        using transitionContext: UIViewControllerContextTransitioning?
    ) -> TimeInterval {
        0.45
    }

    func animateTransition(
        using transitionContext: UIViewControllerContextTransitioning
    ) {

        guard
            let toVC = transitionContext.viewController(
                forKey: .to
            )
        else {
            transitionContext.completeTransition(false)
            return
        }

        let container = transitionContext.containerView

        let snapshot = UIImageView(
            image: imageView.image
        )

        snapshot.contentMode = .scaleAspectFill
        snapshot.clipsToBounds = true

        let startFrame = imageView.superview?.convert(
            imageView.frame,
            to: nil
        ) ?? .zero

        snapshot.frame = startFrame

        imageView.isHidden = true

        toVC.view.frame = transitionContext.finalFrame(
            for: toVC
        )

        toVC.view.alpha = 0

        container.addSubview(toVC.view)
        container.addSubview(snapshot)

        let finalFrame = CGRect(
            x: 0,
            y: 100,
            width: UIScreen.main.bounds.width,
            height: 320
        )

        UIView.animate(
            withDuration: 0.45,
            delay: 0,
            usingSpringWithDamping: 0.9,
            initialSpringVelocity: 0.4
        ) {

            snapshot.frame = finalFrame
            toVC.view.alpha = 1

        } completion: { _ in

            self.imageView.isHidden = false
            snapshot.removeFromSuperview()

            transitionContext.completeTransition(true)
        }
    }
}