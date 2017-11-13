import Foundation
import UIKit

extension UIFont {
  class func xkcdFont(withSize: CGFloat) -> UIFont {
    return UIFont(name: "xkcd Script", size: withSize) ?? UIFont.systemFont(ofSize: withSize)
  }

}
