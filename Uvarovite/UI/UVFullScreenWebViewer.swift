import Foundation
import UIKit
import WebKit

class UVFullScreenWebViewer : UIViewController, WKUIDelegate {
  static let progressKeyPath = "estimatedProgress"
  @IBOutlet var headerView: UIView!
  @IBOutlet var progressIndicatorView: UIView!
  @IBOutlet var progressIndicatorWidthConstraint: NSLayoutConstraint!
  @IBOutlet var webView: WKWebView!

  var url: URL!

  var pageLoadProgress: Double {
    didSet {
      self.updateProgressBarWidth()

      if pageLoadProgress != 0 {
        self.setProgressBarHidden(false, animated: false)
      }

      if self.isViewLoaded {
        UIView.animate(withDuration: 0.1, animations: {
          self.view.layoutIfNeeded()
        }, completion: { (finished: Bool) in
          if self.pageLoadProgress == 1 {
            self.setProgressBarHidden(true, animated: true)
          }
        })
      }
    }
  }

  required init?(coder aDecoder: NSCoder) {
    self.pageLoadProgress = 0
    super.init(coder: aDecoder)
  }

  @IBAction func didTapClose(sender: UIButton) {
    self.presentingViewController?.dismiss(animated: true, completion: nil)
  }

  func setProgressBarHidden(_ hidden: Bool, animated: Bool) {
    let block = {
      self.progressIndicatorView.alpha = (hidden ? 0 : 1)
    }

    if animated {
      UIView.animate(withDuration: 0.1, animations: block, completion: nil)
    } else {
      block()
    }
  }

  deinit {
    self.webView?.removeObserver(self, forKeyPath: type(of: self).progressKeyPath)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.view.backgroundColor = .purple

    self.webView.uiDelegate = self
    let request = URLRequest(url: self.url)
    self.webView.load(request)

    self.webView.addObserver(self, forKeyPath: type(of: self).progressKeyPath, options: .new, context: nil)
  }

  override func observeValue(forKeyPath keyPath: String?,
                             of object: Any?,
                             change: [NSKeyValueChangeKey : Any]?,
                             context: UnsafeMutableRawPointer?) {
    guard let keyPath = keyPath, let change = change, keyPath == type(of: self).progressKeyPath else {
      return
    }

    if let progress = change[NSKeyValueChangeKey.newKey] as? Double {
      self.pageLoadProgress = progress
    }
  }

  func updateProgressBarWidth() {
    func clamp(_ value: Double, _ minValue: Double, _ maxValue: Double) -> Double {
      return min(max(minValue, value), maxValue)
    }

    let progressIndicatorWidth = CGFloat(clamp(self.pageLoadProgress, 0.0, 1.0)) * self.headerView.frame.width
    self.progressIndicatorWidthConstraint.constant = progressIndicatorWidth
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    self.updateProgressBarWidth()
  }

}
