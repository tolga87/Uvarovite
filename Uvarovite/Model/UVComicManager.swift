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
typealias UVComicImageDownloadCallback = ((comic: UVComic, error: ComicError?)) -> Void

enum ComicError: Error {
  case invalidJson
  case couldNotDownloadImage
  case invalidImageData
  case other(description: String?)
}

class UVComicManager {
  static let sharedInstance = UVComicManager()
//  static let managerReadyNotification = Notification.Name("ManagerReadyNotification")
  static let comicsDidUpdateNotification = Notification.Name("comicsDidUpdate")

//  private(set) var ready = false
  private(set) var currentComicId: Int?
  private var currentComic: UVComic?
  private var comicBuffer = [Int: UVComic]()
  private var comicIntervals = UVIntervalSet()

  init() {
    NotificationCenter.default.addObserver(forName: UVIntervalSet.intervalLengthChangedNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            NotificationCenter.default.post(name: UVComicManager.comicsDidUpdateNotification,
                                                                            object: self,
                                                                            userInfo: notification.userInfo)
    }

    self.fetchCurrentComic()
  }

  func numComics() -> Int {
    return self.comicIntervals.length
  }

  func comicAt(_ index: Int) -> UVComic {
    assert(index >= 0 && index < self.comicIntervals.length,
           "Invalid comic index: \(index). Number of comics: \(self.comicIntervals.length)")

    let comicId = self.currentComicId! - index
    let comic = self.comicBuffer[comicId]

    if comicId == 1900 {
      print("debug")
    }

    assert(comic != nil, "Could not find comic with id: \(comicId)")
    return comic!
  }

  private func fetchCurrentComic() {
    self.fetchComic(comicIndex:0, comicId: 0) { (comic: UVComic?, error: ComicError?) in
      if comic != nil {
        self.fetchMoreComics(9)
      } else {
        // TODO: process error
      }
    }
  }

  private func addComic(_ comic: UVComic, at index: Int) {
    if index == 0 {
      self.currentComic = comic
      self.currentComicId = comic.id
    }
    self.comicBuffer[comic.id] = comic
    self.comicIntervals.addItem(index)
  }

  func fetchMoreComics(_ additionalCount: Int) {
    let firstIndexToFetch = self.comicIntervals.length
    self.fetchComics(starting: firstIndexToFetch, count: additionalCount)
  }

  private func fetchComics(starting: Int, count: Int) {
    for comicIndex in starting..<starting + count {
      let comicId = self.currentComic!.id - comicIndex
      self.fetchComic(comicIndex: comicIndex, comicId: comicId) { (comic, error) in
        //
      }
    }
  }

  private func fetchComic(comicIndex: Int, comicId: Int, completion: @escaping UVComicDownloadCallback) {
    var jsonUrlString = "https://xkcd.com/"
    if comicId > 0 {
      jsonUrlString += "\(comicId)/"
    }
    jsonUrlString += "info.0.json"

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
            guard let image = UIImage(data: data) else {
              // TODO: use variable 'error'
              completion((nil, .invalidImageData))
              return
            }

            comic.image = image
            self.addComic(comic, at: comicIndex)
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
