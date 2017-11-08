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
}
