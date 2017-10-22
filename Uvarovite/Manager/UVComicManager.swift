import Foundation
import UIKit

struct UVComicJSONObject: Codable {
  var num: Int
  var day: String
  var month: String
  var year: String
  var title: String
  var safe_title: String
  var alt: String
  var img: String
  var link: String
  var news: String
  var transcript: String
}

typealias UVComicDownloadCallback = ((comic: UVComic?, error: ComicError?)) -> Void

enum ComicError: Error {
  case invalidJson
  case couldNotDownloadImage
  case invalidImageData
  case other(description: String?)
}

class UVComicManager {
  static let sharedInstance = UVComicManager()
  static let comicsDidUpdateNotification = Notification.Name("comicsDidUpdate")

  private(set) var currentComicId: Int?
  private var currentComic: UVComic?
  private var comicBuffer = [UVComic?]()

  private let comicPageSize = 10
  private var comicPage = [UVComic?]()
  private var numComicsInPage = 0

  init() {
    self.fetchCurrentComic()
  }

  func reset() {
    self.currentComicId = nil
    self.currentComic = nil
    self.comicBuffer = []

    self.fetchCurrentComic()
  }

  func numComics() -> Int {
    return self.comicBuffer.count
  }

  func comicAt(_ index: Int) -> UVComic {
    assert(index >= 0 && index < self.comicBuffer.count,
           "Invalid comic index: \(index). Number of comics: \(self.comicBuffer.count)")

    let comic = self.comicBuffer[index]!
    return comic
  }

  func saveComic(_ comic: UVComic) {
    let encodedData = NSKeyedArchiver.archivedData(withRootObject: comic)
    let key = String(comic.id)
    UserDefaults.standard.set(encodedData, forKey: key)

    // TODO: remove this before submitting to App Store
    UserDefaults.standard.synchronize()
  }

  func loadComic(_ id: Int) -> UVComic? {
    let key = String(id)
    if let encodedData = UserDefaults.standard.object(forKey: key) as? Data {
      let comic = NSKeyedUnarchiver.unarchiveObject(with: encodedData) as! UVComic
      return comic
    } else {
      return nil
    }
  }

  func fetchMoreComics() {
    self.fetchComicPage(pageCount: self.comicPageSize)
  }

  private func fetchCurrentComic() {
    self.fetchComic(comicIndex:0) { (comic: UVComic?, error: ComicError?) in
      if let comic = comic {
        self.currentComicId = comic.id
        self.fetchComicPage(pageCount: self.comicPageSize - 1)
      } else {
        // TODO: process error
      }
    }
  }

  private func fetchComicPage(pageCount: Int) {
    assert(self.currentComicId != nil, "Cannot fetch comic page: Current comic id unknown")

    self.comicPage = Array.init(repeating: nil, count: pageCount)
    self.numComicsInPage = 0

    let lastComicIndex = self.comicBuffer.count
    for comicIndex in lastComicIndex..<lastComicIndex + pageCount {
      self.fetchComic(comicIndex: comicIndex, completion: { (comic: UVComic?, error: Error?) in
        let pageIndex = comicIndex - lastComicIndex
        if let comic = comic {
          self.comicPage[pageIndex] = comic
        } else {
          let comicId = self.currentComicId! - comicIndex
          self.comicPage[pageIndex] = UVComic.placeholderComic(id: comicId)
        }

        self.numComicsInPage += 1

        if self.numComicsInPage == pageCount {
          self.comicBuffer.append(contentsOf: self.comicPage)
          self.comicPage = []
          self.numComicsInPage = 0

          NotificationCenter.default.post(name: UVComicManager.comicsDidUpdateNotification,
                                          object: self,
                                          userInfo: nil)
        } else if self.numComicsInPage > pageCount {
          assertionFailure("Inconsistency in comic buffer. Number of comics in page: \(self.numComicsInPage)")
        }
      })
    }
  }

  private func fetchComic(comicIndex: Int, completion: @escaping UVComicDownloadCallback) {
    var jsonUrlString = "https://xkcd.com/"
    var comicId = 0
    if comicIndex > 0 {
      assert(self.currentComicId != nil, "Cannot fetch comic #\(comicIndex): Current comic id unknown")
      comicId = self.currentComicId! - comicIndex
      jsonUrlString += "\(comicId)/"
    }
    jsonUrlString += "info.0.json"

    if let cachedComic = self.loadComic(comicId) {
      completion((cachedComic, nil))
      return
    }

    let jsonUrl = URL(string: jsonUrlString)!

    let comicDownloadTask = URLSession.shared.dataTask(with: jsonUrl) { (data, response, error) in
      if let data = data {
        let decoder = JSONDecoder()
        do {
          let jsonObject = try decoder.decode(UVComicJSONObject.self, from: data)

          guard let comic = UVComic(jsonObject: jsonObject), let imageUrl = comic.imageUrl else {
            completion((nil, .invalidJson))
            return
          }

          let imageDownloadTask = URLSession.shared.dataTask(with: imageUrl) { (data, response, error) in
            guard let data = data else {
              completion((nil, .couldNotDownloadImage))
              return
            }
            if let image = UIImage(data: data) {
              comic.image = image
            }

            self.saveComic(comic)
            DispatchQueue.main.async {
              let comicError = ComicError.other(description: error?.localizedDescription)
              completion((comic, comicError))
            }
          }
          imageDownloadTask.resume()
        }
        catch {
          let comicError = ComicError.other(description: error.localizedDescription)
          completion((nil, comicError))
        }
      }
    }
    comicDownloadTask.resume()
  }
}
