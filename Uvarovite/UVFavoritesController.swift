import Foundation
import UIKit

class UVFavoritesController : NSObject, UITableViewDataSource, UITableViewDelegate {
  private var favorites = UVFavoritesManager.sharedInstance.allFavoriteComicIds()

  weak var tableView: UITableView? {
    didSet {
      tableView?.dataSource = self
      tableView?.delegate = self
    }
  }

  override init() {
    super.init()
    NotificationCenter.default.addObserver(forName: UVFavoritesManager.favoritesUpdatedNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.reloadData()
    }
  }

  func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
    if self.favorites.isEmpty {
      return 1
    } else {
      return favorites.count
    }
  }

  func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
    if self.favorites.isEmpty {
      let emptyCell = tableView.dequeueReusableCell(withIdentifier: "FavoritesEmptyCell", for: indexPath)
      return emptyCell
    }

    let comicId = self.favorites[indexPath.row]
    var comic = UVComicManager.sharedInstance.loadComic(comicId)
    if comic == nil {
      comic = UVComic.placeholderComic(id: comicId)
    }

    let cell = tableView.dequeueReusableCell(withIdentifier: "ComicTableViewCell", for: indexPath) as! UVComicTableViewCell
    cell.updateWithComic(comic!)
    return cell
  }

  func reloadData() {
    self.favorites = UVFavoritesManager.sharedInstance.allFavoriteComicIds()
    self.tableView?.reloadData()
  }
}
