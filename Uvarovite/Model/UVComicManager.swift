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

typealias UVComicDownloadCallback = ((comic: UVComic?, error: Error?)) -> Void
typealias UVComicImageDownloadCallback = ((comic: UVComic, error: Error?)) -> Void

class UVComicManager {
  static let sharedInstance = UVComicManager()
  static let managerReadyNotification = Notification.Name("ManagerReadyNotification")

  private(set) var ready = false
  private(set) var currentComicId: Int?
  private var currentComic: UVComic?
  private var comicBuffer = [Int: UVComic]()

  init() {
    self.fetchCurrentComic()
  }

  private func fetchCurrentComic() {
    self.fetchComic(comicId: 0, comicCallback: { (comic: UVComic?, error: Error?) in
      if let comic = comic {
        self.currentComic = comic
        self.currentComicId = self.currentComic!.id
      } else {
        // TODO: process error
      }
    }) { (comic: UVComic, error: Error?) in
      self.ready = true
      NotificationCenter.default.post(name: UVComicManager.managerReadyNotification, object: self)
    }
  }

  func fetchComic(comicId: Int, comicCallback: @escaping UVComicDownloadCallback, imageCallback: @escaping UVComicImageDownloadCallback) {
    if let comic = self.comicBuffer[comicId] {
      comicCallback((comic, nil))
      imageCallback((comic, nil))
      // TODO: handle case where we have comic, but not image (we should download image if necessary)
      return
    }

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
          let comic = UVComic(jsonObject: jsonObject)
          DispatchQueue.main.async {
            comicCallback((comic, error))
          }

          if let comic = comic, let imageUrl = comic.imageUrl {
            let imageDownloadTask = URLSession.shared.dataTask(with: imageUrl) { (data, response, error) in
              if let data = data {
                let image = UIImage(data: data)
                comic.image = image
              }
              self.comicBuffer[comic.id] = comic
              DispatchQueue.main.async {
                imageCallback((comic, error))
              }
            }
            imageDownloadTask.resume()
          }

        } catch {
          comicCallback((nil, error))
        }
      }
    }
    comicDownloadTask.resume()
  }
}
