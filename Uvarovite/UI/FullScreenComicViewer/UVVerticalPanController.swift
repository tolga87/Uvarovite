import Foundation
import UIKit

protocol UVVerticalPanControllerDelegate {
  func verticalPanControllerDidBeginPanning(_ controller: UVVerticalPanController)
  func verticalPanControllerDidDismiss(_ controller: UVVerticalPanController)
  func verticalPanControllerDidBounceBack(_ controller: UVVerticalPanController)
}

class UVVerticalPanController {
  var delegate: UVVerticalPanControllerDelegate?
  var containerView: UIView!
  var imageView: UIImageView!
  var imageViewCopy: UIImageView!
  var overlayView: UIView?
  private(set) var panRecognizer: UIPanGestureRecognizer!
  var imageViewInitialFrame: CGRect?  // this is in the window's coordinate space

  var panDismissalThreshold: CGFloat = 100.0
  var animationDuration: TimeInterval = 0.5

  init(containerView: UIView, imageView: UIImageView) {
    self.containerView = containerView
    self.imageView = imageView
    self.imageViewCopy = self.copyOf(imageView: self.imageView)

    self.panRecognizer = UIPanGestureRecognizer(target: self,
                                                action: #selector(handleVerticalPan(recognizer:)))
    self.imageView.addGestureRecognizer(self.panRecognizer)
  }

  func copyOf(imageView: UIImageView) -> UIImageView {
    let copyView = UIImageView(frame: imageView.frame)
    copyView.image = imageView.image
    copyView.contentMode = imageView.contentMode
    return copyView
  }

  deinit {
    self.imageView.removeGestureRecognizer(self.panRecognizer)
  }

  @objc func handleVerticalPan(recognizer: UIPanGestureRecognizer) {
    switch self.panRecognizer.state {
    case .began:
      guard let _ = self.imageView?.window else {
        return
      }

      let velocity = recognizer.velocity(in: nil)
      let velocityDirectionThreshold: CGFloat = 5
      if abs(velocity.y) < abs(velocityDirectionThreshold * velocity.x) {
        // this pan is not "vertical" enough. cancel this gesture,
        // so that the horizontal scrolling can happen.
        recognizer.isEnabled = false
        recognizer.isEnabled = true
        return
      }

      self.delegate?.verticalPanControllerDidBeginPanning(self)

      self.overlayView = UIView(frame: self.containerView.bounds)
      self.overlayView!.addSubview(self.imageViewCopy)
      self.containerView.addSubview(self.overlayView!)

      self.imageViewInitialFrame = self.imageView.convert(self.imageView.bounds, to: nil)
      self.imageViewCopy.frame = self.overlayView!.convert(self.imageViewInitialFrame!, from: nil)
      self.imageView.isHidden = true

    case .changed:
      if self.overlayView == nil || self.imageViewInitialFrame == nil {
        return
      }

      let translation = self.panRecognizer.translation(in: self.overlayView)
      var imageFrame = self.overlayView!.convert(self.imageViewInitialFrame!, from: nil)
      imageFrame.origin.y += translation.y
      self.imageViewCopy.frame = imageFrame

    case .ended, .cancelled:
      guard let _ = self.overlayView else {
        return
      }

      let translation = self.panRecognizer.translation(in: self.overlayView)
      if abs(translation.y) < self.panDismissalThreshold {
        self.bounceBackImage()
      } else {
        // will dismiss
        self.panRecognizer.isEnabled = false
        self.delegate?.verticalPanControllerDidDismiss(self)
      }

    default:
      ()
    }
  }

  func bounceBackImage() {
    UIView.animate(withDuration: self.animationDuration,
                   animations: {
                    guard let initialFrame = self.imageViewInitialFrame, let overlayView = self.overlayView else {
                      return
                    }

                    self.imageViewCopy.frame = overlayView.convert(initialFrame, from: nil)
    }) { (finished: Bool) in
      self.imageView.isHidden = false
      self.overlayView?.removeFromSuperview()
      self.overlayView = nil
      self.delegate?.verticalPanControllerDidBounceBack(self)
    }
  }
}
