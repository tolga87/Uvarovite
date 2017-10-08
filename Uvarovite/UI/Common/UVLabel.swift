import Foundation
import UIKit

class UVLabel : UILabel {
  var edgeInsets: UIEdgeInsets? {
    didSet {
      self.invalidateIntrinsicContentSize()
    }
  }

  override func drawText(in rect: CGRect) {
    if let edgeInsets = self.edgeInsets {
      super.drawText(in: UIEdgeInsetsInsetRect(rect, edgeInsets))
    } else {
      super.drawText(in: rect)
    }
  }

  override var intrinsicContentSize: CGSize {
    get {
      var contentSize = super.intrinsicContentSize
      if let edgeInsets = self.edgeInsets {
        contentSize.width += (edgeInsets.left + edgeInsets.right)
        contentSize.height += (edgeInsets.top + edgeInsets.bottom)
      }
      return contentSize
    }
  }
}
