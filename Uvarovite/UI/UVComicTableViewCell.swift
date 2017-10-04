import Foundation
import UIKit

class UVComicTableViewCell : UITableViewCell {
  @IBOutlet var titleLabel: UILabel?
  @IBOutlet var comicImageView: UIImageView?
  @IBOutlet var altTextLabel: UILabel?

  var imageSize: CGSize?

  internal var imageConstraint: NSLayoutConstraint? {
    didSet {
      if oldValue != nil {
        self.comicImageView?.removeConstraint(oldValue!)
      }
      if imageConstraint != nil {
        self.comicImageView?.addConstraint(imageConstraint!)
      }
    }
  }

  var comicId: Int = -1
  var comic: UVComic?

  override func prepareForReuse() {
    super.prepareForReuse()
    self.imageConstraint = nil
    self.comicImageView?.image = nil
  }

//  override func didMoveToSuperview() {
//    self.setNeedsLayout()
//    self.layoutIfNeeded()
//  }

  func setComicImage(_ image: UIImage?) {
    var heightWidthRatio: CGFloat = 0.5
    if let size = image?.size {
      if size.width > 0 {
        heightWidthRatio = size.height / size.width
      }
    }

    let constraint = NSLayoutConstraint(item: self.comicImageView!,
                                        attribute: NSLayoutAttribute.height,
                                        relatedBy: NSLayoutRelation.equal,
                                        toItem: self.comicImageView,
                                        attribute: NSLayoutAttribute.width,
                                        multiplier: heightWidthRatio,
                                        constant: 0.0)
    constraint.priority = UILayoutPriority.init(999)
    self.imageConstraint = constraint
    self.comicImageView?.image = image

    self.setNeedsLayout()
    self.layoutIfNeeded()
  }
}
