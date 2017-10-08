import Foundation
import UIKit

enum UVComicTableViewLoadStatus {
  case initial
  case loading
  case loaded
}

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var comicTableView: UVComicTableView!
  @IBOutlet var comicTableViewFooter: UIView!
  @IBOutlet var loadMoreLabel: UILabel!

  var comicManager = UVComicManager.sharedInstance
  var comicLoadStatus = UVComicTableViewLoadStatus.initial
  var dateFormatter: DateFormatter = DateFormatter()

  override func viewDidLoad() {
    super.viewDidLoad()
    self.comicTableView.dataSource = self
    self.comicTableView.delegate = self

    self.dateFormatter.dateFormat = "yyyy-MM-dd"

    NotificationCenter.default.addObserver(forName: UVComicManager.comicsDidUpdateNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.comicTableView.reloadData()
                                            self.comicLoadStatus = .loaded
                                            self.loadMoreLabel.text = ""
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    return self.comicManager.numComics()
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

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    let comic = self.comicManager.comicAt(indexPath.row)
    cell.comicId = comic.id
    cell.infoLabel.attributedText = self.getAttributedStringWith(title: comic.title ?? "",
                                                                 date: comic.date)
    cell.setComicImage(comic.image)
    return cell
  }

  func calculateFooterRevealPercentage() -> Double {
    let bottomPoint = self.comicTableView.frame.size.height + self.comicTableView.contentOffset.y
    let footerHeight = self.comicTableViewFooter.frame.size.height
    return Double((bottomPoint - self.comicTableView.contentSize.height + footerHeight) / footerHeight)
  }

  func scrollViewDidScroll(_ scrollView: UIScrollView) {
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

  func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
    let percentage = self.calculateFooterRevealPercentage()
    if percentage >= 1.0 && self.comicLoadStatus == .loaded {
      self.comicLoadStatus = .loading
      self.loadMoreLabel.text = "Loading..."
      self.comicManager.fetchMoreComics(10)
    }
  }
}
