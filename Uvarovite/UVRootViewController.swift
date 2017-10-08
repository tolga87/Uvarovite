import Foundation
import UIKit

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var comicTableView: UVComicTableView!

  var comicManager = UVComicManager.sharedInstance
  var dateFormatter: DateFormatter = DateFormatter()

  @IBAction func testTapped(sender: UIButton) {
    self.comicManager.fetchMoreComics(10)
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.comicTableView.dataSource = self
    self.comicTableView.delegate = self

    self.dateFormatter.dateFormat = "yyyy-MM-dd"

    NotificationCenter.default.addObserver(forName: UVComicManager.comicsDidUpdateNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                              self.comicTableView.reloadData()

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
}
