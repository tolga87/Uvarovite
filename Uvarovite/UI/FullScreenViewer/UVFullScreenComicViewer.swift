import Foundation
import UIKit

protocol UVFullScreenComicViewerDelegate {
  func fullScreenViewer(_ viewer: UVFullScreenComicViewer, didScrollToPage page: Int)
}


class UVFullScreenComicViewer : UIViewController, UVFullScreenComicDelegate, UIScrollViewDelegate {
  var delegate: UVFullScreenComicViewerDelegate?
  var scrollView: UIScrollView
  var pages: [UVFullScreenComicViewerPage]
  let comicManager = UVComicManager.sharedInstance
  var currentPage = 0
  var explainUrl: URL?  // explain URL that is about to be displayed
  var explainComic: UVComic?  // comic that is about to be explained

  required init?(coder aDecoder: NSCoder) {
    self.scrollView = UIScrollView()
    self.scrollView.isPagingEnabled = true
    self.scrollView.bounces = true
    self.pages = []

    super.init(coder: aDecoder)
    self.scrollView.delegate = self
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
      let page = UVFullScreenComicViewerPage.instanceFromNib()
      page.delegate = self
      page.comic = self.comicManager.comicAt(i)
      pages.append(page)
      self.scrollView.addSubview(page)
    }
  }

  func fullScreenComicDidTapClose(_ page: UVFullScreenComicViewerPage) {
    self.dismiss(animated: true, completion: nil)
  }

  func fullScreenComicDidTapPrev(_ page: UVFullScreenComicViewerPage) {
    if self.currentPage > 0 {
      self.setPageOffset(self.currentPage - 1)
      // delegate methods will not be called when scrollView's contentOffset
      // is set programmatically without animation, so I call it manually here...
      self.scrollViewDidScroll(self.scrollView)
    }
  }

  func fullScreenComicDidTapNext(_ page: UVFullScreenComicViewerPage) {
    if self.currentPage < self.pages.count - 1 {
      self.setPageOffset(self.currentPage + 1)
      // ...and here.
      self.scrollViewDidScroll(self.scrollView)
    }
  }

  func fullScreenComic(_ comic: UVFullScreenComicViewerPage, didRequestUrl url: URL) {
    self.explainUrl = url
    self.explainComic = comic.comic
    self.performSegue(withIdentifier: "ShowWebViewer", sender: self)
  }

  override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    guard let webViewer = segue.destination as? UVFullScreenWebViewer, let url = self.explainUrl else {
      return
    }

    webViewer.comic = self.explainComic
    webViewer.url = url
    self.explainComic = nil
    self.explainUrl = nil
  }
}
