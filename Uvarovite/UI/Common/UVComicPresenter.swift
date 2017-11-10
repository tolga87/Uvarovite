import Foundation
import UIKit

class UVComicPresenter {
  class func attributedStringWith(comicId: Int, title: String?, date: Date?) -> NSAttributedString {
    let attributedString = NSMutableAttributedString()

    let comicIdString = NSAttributedString.init(string: "#\(comicId)  ",
      attributes: [
        .font : UIFont.systemFont(ofSize: 14),
        .foregroundColor : UIColor.lightGray,
        ])
    attributedString.append(comicIdString)

    let titleString = NSAttributedString.init(string: title ?? "",
                                              attributes: [
                                                .font : UIFont.systemFont(ofSize: 20),
                                                .foregroundColor : UIColor.white,
                                                ])
    attributedString.append(titleString)

    let dateFormatter = DateFormatter()
    dateFormatter.dateFormat = "yyyy-MM-dd"

    if let date = date {
      let dateString = NSAttributedString.init(string: "\n\(dateFormatter.string(from: date))",
        attributes: [
          .font : UIFont.systemFont(ofSize: 14),
          .foregroundColor : UIColor.lightGray,
          ])
      attributedString.append(dateString)
    }

    return attributedString
  }

  class func attributedStringForExplainerTitle(comic: UVComic) -> NSAttributedString {
    var string = "Explain #\(comic.id)"
    if let comicTitle = comic.title {
      string += " - \"\(comicTitle)\""
    }

    let attrString = NSMutableAttributedString(string: string)
    let entireString = string as NSString
    let comicIdString = "#\(comic.id)"
    attrString.addAttributes([.font : UIFont.systemFont(ofSize: 14),
                              .foregroundColor : UIColor.lightGray,
                              ],
                             range: entireString.range(of: comicIdString))

    return attrString
  }

  class func altTextLabel() -> UVLabel {
    let label = UVLabel()
    label.numberOfLines = 0
    label.backgroundColor = .altTextBackgroundColor
    label.textColor = .white
    label.layer.cornerRadius = 4
    label.layer.masksToBounds = true
    label.edgeInsets = UIEdgeInsetsMake(2, 4, 2, 4)
    label.adjustsFontSizeToFitWidth = true
    label.minimumScaleFactor = 0.33
    return label
  }
}
