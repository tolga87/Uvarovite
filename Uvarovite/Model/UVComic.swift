import Foundation
import UIKit

protocol UVComicSharing : NSObjectProtocol {
  func comicDidRequestShare(_ comic: UVComic)
}

class UVComic: NSObject, NSCoding {
  var id: Int
  var date: Date?
  var title: String?
  var altText: String?
  var imageUrl: URL?
  var image: UIImage?
  var webUrl: URL? {
    get {
      let urlString = "https://xkcd.com/\(self.id)/"
      return URL.init(string: urlString)
    }
  }
  weak var shareDelegate: UVComicSharing?

  static func placeholderComic(id: Int) -> UVComic {
    return UVComic(id: id)
  }

  init(id: Int) {
    self.id = id
  }

  convenience required init?(coder aDecoder: NSCoder) {
    let id = aDecoder.decodeInteger(forKey: "id")
    let date = aDecoder.decodeObject(forKey: "date") as! Date?
    let title = aDecoder.decodeObject(forKey: "title") as! String?
    let altText = aDecoder.decodeObject(forKey: "altText") as! String?
    let imageUrl = aDecoder.decodeObject(forKey: "imageUrl") as! URL?

    self.init(id: id, date: date, title: title, altText: altText, imageUrl: imageUrl)
    self.image = aDecoder.decodeObject(forKey: "image") as! UIImage?
  }

  convenience init?(id: Int, date: Date?, title: String?, altText: String?, imageUrl: URL?) {
    self.init(id: id)
    self.date = date
    self.title = title
    self.altText = altText
    self.imageUrl = imageUrl
  }

  convenience init?(jsonObject json: UVComicJSONObject) {
    var dateComponents = DateComponents()
    dateComponents.day = Int(json.day)
    dateComponents.month = Int(json.month)
    dateComponents.year = Int(json.year)
    guard let date = Calendar.current.date(from: dateComponents) else {
      return nil
    }

    guard let imageUrl = URL(string: json.img) else {
      return nil
    }

    self.init(id: json.num,
              date: date,
              title: json.title,
              altText: json.alt,
              imageUrl: imageUrl)
  }

  func encode(with aCoder: NSCoder) {
    aCoder.encode(self.id, forKey: "id")
    aCoder.encode(self.date, forKey: "date")
    aCoder.encode(self.title, forKey: "title")
    aCoder.encode(self.altText, forKey: "altText")
    aCoder.encode(self.imageUrl, forKey: "imageUrl")
    aCoder.encode(self.image, forKey: "image")
  }

  override var description: String {
    let imageDownloaded = (self.image != nil)
    var dateString = "<NIL>"
    if let date = self.date {
      let dateFormatter = DateFormatter()
      dateFormatter.dateFormat = "yyyy-MM-dd"
      dateString = dateFormatter.string(from: date)
    }

    return "\(type(of: self)): \(dateString) | img downloaded: \(imageDownloaded ? "YES" : "NO")"
  }
}
