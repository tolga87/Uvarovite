import Foundation
import UIKit

protocol UVFullScreenViewerDelegate {
  func fullScreenViewer(_ viewer: UVFullScreenViewer, didScrollToPage page: Int)
}


class UVFullScreenViewer : UIViewController, UVFullScreenComicDelegate, UIScrollViewDelegate {
  var delegate: UVFullScreenViewerDelegate?
  var scrollView: UIScrollView
  var pages: [UVFullScreenViewerPage]
  let comicManager = UVComicManager.sharedInstance
  var currentPage = 0

  init() {
    self.scrollView = UIScrollView()
    self.scrollView.isPagingEnabled = true
    self.scrollView.bounces = true
    self.pages = []

    super.init(nibName: nil, bundle: nil)
    self.scrollView.delegate = self
  }

  convenience init(currentPage: Int) {
    var page = currentPage
    let numPages = UVComicManager.sharedInstance.numComics()
    if currentPage < 0 || currentPage >= numPages {
      page = 0
    }

    self.init()
    self.currentPage = page
  }

  required convenience init?(coder aDecoder: NSCoder) {
    self.init()
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let offset = scrollView.contentOffset.x
    let page = Int(offset / scrollView.frame.width)
    if (page != currentPage) {
      currentPage = page
      self.delegate?.fullScreenViewer(self, didScrollToPage: currentPage)
    }
  }

  func setPageOffset(_ page: Int) {
    // this method does not check the boundaries
    let offsetX = CGFloat(page) * self.scrollView.frame.width
    let contentOffset = CGPoint(x: offsetX, y:0)
    self.scrollView.setContentOffset(contentOffset, animated: false)
  }

  override func viewWillLayoutSubviews() {
    self.scrollView.frame = self.view.bounds

    for i in 0 ..< self.pages.count {
      let page = self.pages[i]
      var frame = self.scrollView.bounds
      frame.origin.x = CGFloat(i) * frame.width
      frame.origin.y = CGFloat(0.0)
      page.frame = frame
    }

    let contentWidth = CGFloat(pages.count) * self.scrollView.frame.width
    let contentHeight = self.scrollView.frame.height
    self.scrollView.contentSize = .init(width: contentWidth, height: contentHeight)

    if self.currentPage != 0 {
      self.setPageOffset(self.currentPage)
    }
  }

  override func viewDidLoad() {
    super.viewDidLoad()

    self.view.addSubview(self.scrollView)

    let numComics = self.comicManager.numComics()
    for i in 0..<numComics {
      let page = UVFullScreenViewerPage.instanceFromNib()
      page.delegate = self
      page.comic = self.comicManager.comicAt(i)
      pages.append(page)
      self.scrollView.addSubview(page)
    }
  }

  func fullScreenComicDidTapClose(_ page: UVFullScreenViewerPage) {
    self.dismiss(animated: true, completion: nil)
  }

  func fullScreenComicDidTapPrev(_ page: UVFullScreenViewerPage) {
    if self.currentPage > 0 {
      self.setPageOffset(self.currentPage - 1)
      // delegate methods will not be called when scrollView's contentOffset
      // is set programmatically without animation, so I call it manually here...
      self.scrollViewDidScroll(self.scrollView)
    }
  }

  func fullScreenComicDidTapNext(_ page: UVFullScreenViewerPage) {
    if self.currentPage < self.pages.count - 1 {
      self.setPageOffset(self.currentPage + 1)
      // ...and here.
      self.scrollViewDidScroll(self.scrollView)
    }
  }
}