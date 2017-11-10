import Foundation
import UIKit

extension UIColor {
  class var lightBlue: UIColor {
    return self.rgbColor(149, 167, 200)
  }

  class var darkBlue: UIColor {
    return self.rgbColor(110, 123, 145)
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
