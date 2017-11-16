import Foundation
import UIKit

class UVShareActivityItemSource : NSObject, UIActivityItemSource {
  var comic: UVComic

  init(comic: UVComic) {
    self.comic = comic
  }

  func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
    return ""
  }

  func activityViewController(_ activityViewController: UIActivityViewController,
                              itemForActivityType activityType: UIActivityType?) -> Any? {
    guard let activityType = activityType else {
      return nil
    }

    let appName = Bundle.main.infoDictionary![kCFBundleNameKey as String] as! String
    // xkcd Lite
    let sharedViaMessage = "Shared via \(appName) - http://tolgaakin.com"

    switch activityType {
      // these are the activity types that seem to play nice with body text.
      // others don't show the image if a text is also added.
    case UIActivityType.mail,
         UIActivityType.message,
         UIActivityType.postToTwitter:
      return sharedViaMessage

    case _ where activityType.rawValue.lowercased().range(of: "messenger") != nil:
      // "com.facebook.Messenger.ShareExtension"
      return nil

    case _ where activityType.rawValue.lowercased().range(of: "facebook") != nil:
      // "com.apple.UIKit.activity.PostToFacebook"
      return nil

    default:
      return sharedViaMessage
    }
  }

  func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivityType?) -> String {
    return "Check out this xkcd comic!"
  }

  func activityViewController(_ activityViewController: UIActivityViewController,
                              thumbnailImageForActivityType activityType: UIActivityType?,
                              suggestedSize size: CGSize) -> UIImage? {
    func resizeImage(_ image: UIImage, toSize newSize: CGSize) -> UIImage {
      // retrieved from https://stackoverflow.com/questions/2658738/the-simplest-way-to-resize-an-uiimage
      UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
      image.draw(in: CGRect(origin: CGPoint.zero, size: CGSize(width: newSize.width, height: newSize.height)))
      let newImage: UIImage = UIGraphicsGetImageFromCurrentImageContext()!
      UIGraphicsEndImageContext()
      return newImage
    }

    guard let image = self.comic.image else {
      return nil
    }

    return resizeImage(image, toSize: size)
  }
}

class UVSharingManager {
  static let sharedInstance = UVSharingManager()

  private func activityItemsFor(_ comic: UVComic) -> [Any] {
    let mailItemSource = UVShareActivityItemSource(comic: comic)
    return [ comic.image!, mailItemSource ]
  }

  func activityViewControllerFor(_ comic: UVComic) -> UIActivityViewController {
    let activityItems = self.activityItemsFor(comic)
    let activityVC = UIActivityViewController(activityItems: activityItems,
                                              applicationActivities: nil)
    let excludedActivities = [
      UIActivityType.airDrop,
      UIActivityType.addToReadingList,
      UIActivityType.assignToContact,
      UIActivityType.copyToPasteboard,
      UIActivityType.print,
      UIActivityType.postToFlickr,
      UIActivityType.postToWeibo,
      UIActivityType.postToTencentWeibo,
    ]
    activityVC.excludedActivityTypes = excludedActivities
    return activityVC
  }
}
