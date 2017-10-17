import Foundation
import StoreKit
import UIKit

enum UVComicTableViewLoadStatus {
  case initial
  case loading
  case loaded
}

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate, UVComicSharing {
  @IBOutlet var headerView: UIView!
  @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
  @IBOutlet var comicTableView: UVComicTableView!
  @IBOutlet var comicTableViewFooter: UIView!
  @IBOutlet var loadMoreLabel: UILabel!

  static let activityViewControllerDidShowNotification = Notification.Name("activityViewControllerDidShow")

  var headerMaxHeight: CGFloat = 0
  var comicManager = UVComicManager.sharedInstance
  var comicLoadStatus = UVComicTableViewLoadStatus.initial
  var dateFormatter: DateFormatter = DateFormatter()

  private var isDragging = false
  private var dragBeginOffset: CGFloat = 0
  private var headerHeightAtDragStart: CGFloat = 0
  private let dragToLoadMoreThreshold = 1.5

  override func viewDidLoad() {
    super.viewDidLoad()

    self.comicTableView.dataSource = self
    self.comicTableView.delegate = self
    self.dateFormatter.dateFormat = "yyyy-MM-dd"
    self.headerMaxHeight = self.headerView.frame.size.height

    NotificationCenter.default.addObserver(forName: UVComicManager.comicsDidUpdateNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.comicTableView.reloadData()
                                            self.comicLoadStatus = .loaded
                                            self.loadMoreLabel.text = ""
    }
  }

  @IBAction func didTapScrollToTop(sender: UIButton) {
    self.comicTableView.setContentOffset(CGPoint.zero, animated: true)
  }

  @IBAction func didTapSettings(sender: UIButton) {
    let menu = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
    menu.addAction(UIAlertAction(title: "Refresh Comics", style: .default, handler: { _ in
      // Refresh
      self.resetComics()
    }))
    menu.addAction(UIAlertAction(title: "Show release notes", style: .default, handler: { _ in
      // Show release notes
      let url = URL.init(string: "http://tolgaakin.com/?page_id=1229#xkcd")!
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }))
    menu.addAction(UIAlertAction(title: "Rate xkcd Lite on the App Store", style: .default, handler: { _ in
      // Rate
      SKStoreReviewController.requestReview()
    }))
    menu.addAction(UIAlertAction(title: "Dismiss", style: .cancel, handler: nil))

    // this is necessary for iPad.
    menu.popoverPresentationController?.sourceView = sender
    menu.popoverPresentationController?.sourceRect = sender.bounds

    self.present(menu, animated: true)
  }

  func resetComics() {
    self.comicManager.reset()
    self.comicTableView.reloadData()
    self.comicLoadStatus = .loading
    self.loadMoreLabel.text = "Loading..."
  }

  // MARK: - TableView / ScrollView

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.comicManager.numComics()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    let comic = self.comicManager.comicAt(indexPath.row)
    cell.comic = comic
    comic.shareDelegate = self
    cell.comicId = comic.id

    func getAttributedStringWith(title: String, date: Date?) -> NSAttributedString {
      let attributedString = NSMutableAttributedString()

      let titleString = NSAttributedString.init(string: title,
                                                attributes: [
                                                  .font : UIFont.systemFont(ofSize: 20),
                                                  .foregroundColor : UIColor.white,
                                                  ])
      attributedString.append(titleString)

      if let date = date {
        let dateString = NSAttributedString.init(string: "\n\(self.dateFormatter.string(from: date))",
          attributes: [
            .font : UIFont.systemFont(ofSize: 14),
            .foregroundColor : UIColor.lightGray,
            ])
        attributedString.append(dateString)
      }

      return attributedString
    }
    cell.infoLabel.attributedText = getAttributedStringWith(title: comic.title ?? "",
                                                            date: comic.date)
    cell.altTextLabel.text = comic.altText
    cell.setComicImage(comic.image)
    cell.comic = comic
    return cell
  }

  func calculateFooterRevealPercentage() -> Double {
    let bottomPoint = self.comicTableView.frame.size.height + self.comicTableView.contentOffset.y
    let footerHeight = self.comicTableViewFooter.frame.size.height
    return Double((bottomPoint - self.comicTableView.contentSize.height + footerHeight) / footerHeight)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
    let scrollOffset = self.comicTableView.contentOffset.y
    let dragAmount = scrollOffset - self.dragBeginOffset
    func clamp(_ value: CGFloat, _ minValue: CGFloat, _ maxValue: CGFloat) -> CGFloat {
      return min(maxValue, max(value, minValue))
    }

    let headerHeight = clamp(self.headerHeightAtDragStart - dragAmount, 0, self.headerMaxHeight)
    self.headerHeightConstraint.constant = headerHeight

    if self.comicLoadStatus != .loaded {
      return
    }

    let percentage = self.calculateFooterRevealPercentage()
    if percentage >= self.dragToLoadMoreThreshold && self.isDragging {
      self.loadMoreLabel.text = "Release to load more comics"
    } else {
      // \u{2191} is the up arrow symbol
      self.loadMoreLabel.text = "\u{2191}\u{2191}Drag up to load more comics\u{2191}\u{2191}"
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.isDragging = true
    self.dragBeginOffset = self.comicTableView.contentOffset.y
    self.headerHeightAtDragStart = self.headerView.frame.size.height
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    self.isDragging = false
    let percentage = self.calculateFooterRevealPercentage()
    if percentage >= self.dragToLoadMoreThreshold && self.comicLoadStatus == .loaded {
      self.comicLoadStatus = .loading
      self.loadMoreLabel.text = "Loading..."
      self.comicManager.fetchMoreComics(10)
    }
  }

  // MARK: - UVComicSharing

  // TODO: detect when we don't have access to Photo library and show a warning to the user.
  func comicDidRequestShare(_ comic: UVComic) {
    if comic.image == nil {
      // don't share comic if we don't have the image
      // TODO: show an error message if this happens.
      return
    }

    let sharingManager = UVSharingManager.sharedInstance
    let activityViewController = sharingManager.activityViewControllerFor(comic)

    self.present(activityViewController, animated: true) {
      NotificationCenter.default.post(name: UVRootViewController.activityViewControllerDidShowNotification,
                                      object: self,
                                      userInfo: nil)
    }
  }

}
