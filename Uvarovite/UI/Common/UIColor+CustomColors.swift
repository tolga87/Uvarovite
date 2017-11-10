import Foundation
import UIKit

extension UIColor {
  class var lightBlue: UIColor {
    return UIColor(red: 149.0 / 255.0, green: 167.0 / 255.0, blue: 200.0 / 255.0, alpha: 1)
  }

  class var darkBlue: UIColor {
    return UIColor(red: 110.0 / 255.0, green: 123.0 / 255.0, blue: 145.0 / 255.0, alpha: 1)
  }

  class var altTextBackgroundColor: UIColor {
    // 224.0
    return UIColor(white: 0.2, alpha: 1)
  }

  class var webViewProgressIndicatorColor: UIColor {
    return self.rgbColor(51, 102, 255)
  }

  // Just a convenience method
  class func rgbColor(_ red: Int, _ green: Int, _ blue: Int) -> UIColor {
    return UIColor(red: CGFloat(red) / 255.0,
                   green: CGFloat(green) / 255.0,
                   blue: CGFloat(blue) / 255.0,
                   alpha: 1)
  }
}
