import Foundation
import UIKit

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var comicTableView: UVComicTableView!

  var comicManager = UVComicManager.sharedInstance
  var dateFormatter: DateFormatter = DateFormatter()

  @IBAction func testTapped(sender: UIButton) {
    print("TEST")
    self.comicManager.fetchMoreComics(10)
//    self.comicTableView.reloadData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.comicTableView.dataSource = self
    self.comicTableView.delegate = self

    self.dateFormatter.dateFormat = "yyyy-MM-dd"

    NotificationCenter.default.addObserver(forName: UVComicManager.comicsDidUpdateNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
//                                            if let userInfo = notification.userInfo {
//                                              let newRange = userInfo[UVIntervalSet.intervalLengthChangedNotificationRangeKey] as! ClosedRange<Int>
//                                              self.loadNewComics(range: newRange)
//                                            } else {
                                              self.comicTableView.reloadData()
//                                            }

    }
  }

//  func loadNewComics(range: ClosedRange<Int>) {
//    var indexPaths = [IndexPath]()
//    for row in range.lowerBound...range.upperBound {
//      indexPaths.append(IndexPath(row: row, section: 0))
//    }
//
//    self.comicTableView.insertRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
////    self.comicTableView.reloadRows(at: indexPaths, with: UITableViewRowAnimation.automatic)
//  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//    return 0
//    if !self.comicManager.ready {
//      return 0
//    }
//    return 100

    let numComics = self.comicManager.numComics()
    return numComics
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    let comic = self.comicManager.comicAt(indexPath.row)
    cell.comicId = comic.id
    cell.titleLabel.text = comic.title
    if let date = comic.date {
      cell.dateLabel.text = self.dateFormatter.string(from: date)
    }
    cell.setComicImage(comic.image)
    return cell
  }

//  private func loadingCell() -> UITableViewCell {
//    let indexPath = IndexPath(row: 0, section: 0)
//    let cell = self.comicTableView!.dequeueReusableCell(withIdentifier: "ComicTableViewCell",
//                                                        for: indexPath) as! UVComicTableViewCell
//    cell.titleLabel?.text = "Loading..."
//    cell.setComicImage(nil)
//    return cell
//  }
}
