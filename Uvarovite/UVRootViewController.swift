import Foundation
import UIKit

class UVRootViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
  var comicManager = UVComicManager.sharedInstance
  var someComic: UVComic?
  @IBOutlet var comicTableView: UVComicTableView!

  internal var debug_reloaded: Bool = false

  @IBAction func testTapped(sender: UIButton) {
    print("TEST")
    self.comicTableView.reloadData()
  }

  override func viewDidLoad() {
    super.viewDidLoad()
    self.comicTableView.dataSource = self
    self.comicTableView.delegate = self

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
    self.comicTableView.setNeedsLayout()
    self.comicTableView.layoutIfNeeded()
    self.comicTableView.reloadData()
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if !self.comicManager.ready {
      return 0
    }
    return 10
  }


  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    cell.comicId = self.comicManager.currentComicId! - indexPath.row
    cell.titleLabel?.text = "Comic #\(cell.comicId)"

    self.comicManager.fetchComic(comicId: cell.comicId,
                                 comicCallback:{ (comic: UVComic?, error: Error?) in
                                  if let comic = comic {
                                    if comic.id == cell.comicId {
                                      cell.titleLabel?.text = comic.title
                                    }
                                  }
    },
                                 imageCallback:{ (comic: UVComic, error: Error?) in
                                  if comic.id == cell.comicId {
                                    print("Image downloaded for comic: \(cell.comicId)")
                                    cell.setComicImage(comic.image)

                                    if !self.debug_reloaded && indexPath.row == 1 {
                                      self.debug_reloaded = true
                                      self.comicTableView.reloadData()
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
