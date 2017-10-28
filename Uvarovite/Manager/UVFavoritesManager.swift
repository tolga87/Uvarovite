import Foundation

class UVFavoritesManager {
  static let sharedInstance = UVFavoritesManager()

  static let favoritesUpdatedNotification = NSNotification.Name("favoritesUpdated")
  private var favorites: [String : String]
  private let favoritesUserDefaultsKey = "favorites"

  init() {
    if let savedFavorites = UserDefaults.standard.dictionary(forKey: self.favoritesUserDefaultsKey) {
      self.favorites = savedFavorites as! [String : String]
    } else {
      self.favorites = [:]
    }
  }

  func allFavoriteComicIds() -> [Int] {
    let keysArray = Array(self.favorites.keys).sorted().reversed()
    return keysArray.map {
      Int($0)!
    }
  }

  func favoriteComic(id: Int) {
    if self.isFavorite(id: id) {
      return
    }

    let key = String(id)
    self.favorites[key] = key
    self.synchronizeDict()
    self.notifyUpdate()

    print("Favorited comic \(id)")
  }

  func unfavoriteComic(id: Int) {
    if !self.isFavorite(id: id) {
      return
    }

    let key = String(id)
    self.favorites.removeValue(forKey: key)
    self.synchronizeDict()
    self.notifyUpdate()

    print("Unfavorited comic \(id)")
  }

  func isFavorite(id: Int) -> Bool {
    let key = String(id)
    return (self.favorites[key] != nil)
  }

  private func synchronizeDict() {
    UserDefaults.standard.set(self.favorites, forKey: self.favoritesUserDefaultsKey)
    UserDefaults.standard.synchronize()
  }

  func notifyUpdate() {
    NotificationCenter.default.post(name: type(of: self).favoritesUpdatedNotification, object: self)
  }
}

