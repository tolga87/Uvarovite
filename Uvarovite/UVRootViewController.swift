import Foundation
import UIKit

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  @IBOutlet var comicTableView: UVComicTableView!

  var comicManager = UVComicManager.sharedInstance
  var dateFormatter: DateFormatter = DateFormatter()

  internal var debug_reloaded = [false, false, false]
  internal var debug_remaining = 3

  @IBAction func testTapped(sender: UIButton) {
    print("TEST")
    self.comicTableView.reloadData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.comicTableView.dataSource = self
    self.comicTableView.delegate = self

    self.dateFormatter.dateFormat = "yyyy-MM-dd"

    NotificationCenter.default.addObserver(forName: UVComicManager.managerReadyNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            print("Comic Manager Ready!")
                                            self.reloadDataWorkaround()
    }
  }

  override func viewDidAppear(_ animated: Bool) {
    super.viewDidAppear(animated)
    self.reloadDataWorkaround()
  }

  internal func reloadDataWorkaround() {
    // this looks really unnecessary, but after banging my head on
    // the wall for a very long time, I'm 99% convinced that this
    // layout issue is an Apple bug and applied this ugly workaround.
    self.comicTableView.reloadData()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if !self.comicManager.ready {
      return 0
    }
    return 100
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    cell.comicId = self.comicManager.currentComicId! - indexPath.row
    cell.titleLabel?.text = "Loading..."

    self.comicManager.fetchComic(comicId: cell.comicId,
                                 comicCallback:{ (comic: UVComic?, error: Error?) in
                                  if let comic = comic {
                                    if comic.id == cell.comicId {
                                      cell.titleLabel.text = comic.title
                                      var dateString = ""
                                      if let date = comic.date {
                                        dateString = self.dateFormatter.string(from: date)
                                      }
                                      cell.dateLabel.text = dateString
                                    }
                                  }
    },
                                 imageCallback:{ (comic: UVComic, error: Error?) in
                                  if comic.id == cell.comicId {
                                    print("Image downloaded for comic: \(cell.comicId)")
                                    cell.setComicImage(comic.image)

                                    if self.debug_remaining > 0 {

                                      let index = indexPath.row
                                      if index < self.debug_reloaded.count && !self.debug_reloaded[index] {
                                        print("Reloading...")
                                        self.comicTableView.reloadData()
                                        self.debug_reloaded[index] = true
                                        self.debug_remaining -= 1
                                      }
                                    }
                                  }
    })

    return cell
  }

  private func loadingCell() -> UITableViewCell {
    let indexPath = IndexPath(row: 0, section: 0)
    let cell = self.comicTableView!.dequeueReusableCell(withIdentifier: "ComicTableViewCell",
                                                        for: indexPath) as! UVComicTableViewCell
    cell.titleLabel?.text = "Loading..."
    cell.setComicImage(nil)
    return cell
  }
}
