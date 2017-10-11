import Foundation
import UIKit

enum UVComicTableViewLoadStatus {
  case initial
  case loading
  case loaded
}

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var headerView: UIView!
  @IBOutlet var headerHeightConstraint: NSLayoutConstraint!
  @IBOutlet var comicTableView: UVComicTableView!
  @IBOutlet var comicTableViewFooter: UIView!
  @IBOutlet var loadMoreLabel: UILabel!

  var headerMaxHeight: CGFloat = 0
  var comicManager = UVComicManager.sharedInstance
  var comicLoadStatus = UVComicTableViewLoadStatus.initial
  var dateFormatter: DateFormatter = DateFormatter()

  private var dragBeginOffset: CGFloat = 0
  private var headerHeightAtDragStart: CGFloat = 0

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
    print("Not implemented yet!")
  }

  private func getAttributedStringWith(title: String, date: Date?) -> NSAttributedString {
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

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.comicManager.numComics()
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    let comic = self.comicManager.comicAt(indexPath.row)
    cell.comicId = comic.id
    cell.infoLabel.attributedText = self.getAttributedStringWith(title: comic.title ?? "",
                                                                 date: comic.date)
    cell.altTextLabel.text = comic.altText
    cell.setComicImage(comic.image)
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
    if percentage > 1 {
      self.loadMoreLabel.text = String(format: "%.1f", percentage)
    } else {
      // \u{2191} is the up arrow symbol
      self.loadMoreLabel.text = "\u{2191}\u{2191}Drag up for more comics\u{2191}\u{2191}"
    }
  }

  func scrollViewWillBeginDragging(_ scrollView: UIScrollView) {
    self.dragBeginOffset = self.comicTableView.contentOffset.y
    self.headerHeightAtDragStart = self.headerView.frame.size.height
  }

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    let percentage = self.calculateFooterRevealPercentage()
    if percentage >= 1.0 && self.comicLoadStatus == .loaded {
      self.comicLoadStatus = .loading
      self.loadMoreLabel.text = "Loading..."
      self.comicManager.fetchMoreComics(10)
    }
  }
}
