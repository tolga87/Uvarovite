import Foundation
import UIKit

protocol UVFullScreenComicDelegate {
  func fullScreenComicDidTapClose(_ page: UVFullScreenViewerPage)
}

class UVFullScreenViewerPage : UIView {
  var comic: UVComic? {
    didSet {
      self.imageView.image = comic?.image
      self.updateComicInfo()
      self.updateImageSize()
    }
  }

  var delegate: UVFullScreenComicDelegate?
  let comicImageHorizontalPadding = CGFloat(5)

  @IBOutlet var headerView: UIView!
  @IBOutlet var titleLabel: UILabel!

  @IBOutlet var footerView: UIView!
  @IBOutlet var imageView: UIImageView!
  @IBOutlet var imageViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!

  class func instanceFromNib() -> UVFullScreenViewerPage {
    let view = UINib(nibName: "UVFullScreenViewerPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UVFullScreenViewerPage
    view.imageView.contentMode = .scaleAspectFit
    return view
  }

  func updateComicInfo() {
    if let comic = self.comic {
      self.titleLabel.attributedText = UVComicPresenter.attributedStringWith(comicId: comic.id,
                                                                             title: comic.title,
                                                                             date: comic.date)
    } else {
      self.titleLabel.attributedText = nil
    }
  }

  func updateImageSize() {
    guard let comic = self.comic else {
      self.imageViewWidthConstraint.constant = 128
      self.imageViewHeightConstraint.constant = 240
      return
    }

    var imageWidth = comic.image != nil ? comic.image!.size.width : 0
    var imageHeight = comic.image != nil ? comic.image!.size.height : 0
    var scale = CGFloat(1)
    let maxWidth = self.frame.width - 2 * self.comicImageHorizontalPadding
    let maxHeight = self.frame.height - headerView.frame.height - footerView.frame.height

    if imageWidth <= maxWidth && imageHeight <= maxHeight {
      // image fits the area, no change to image size.
    } else if imageWidth > maxWidth && imageHeight <= maxHeight {
      // image too wide
      scale = maxWidth / imageWidth
    } else if imageWidth <= maxWidth && imageHeight > maxHeight {
      // image too tall
      scale = maxHeight / imageHeight
    } else {
      // image too wide and tall
      let scale1 = maxWidth / imageWidth
      let scale2 = maxHeight / imageHeight
      scale = min(scale1, scale2)
    }

    func scaleSize(_ size: CGSize?, _ scale: CGFloat) -> CGSize? {
      if let size = size {
        return CGSize(width: size.width * scale, height: size.height * scale)
      } else {
        return nil
      }
    }

    if let imageSize = scaleSize(comic.image?.size, scale) {
      self.imageViewWidthConstraint.constant = imageSize.width
      self.imageViewHeightConstraint.constant = imageSize.height
    } else {
      self.imageViewWidthConstraint.constant = 128
      self.imageViewHeightConstraint.constant = 240
    }
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    self.updateImageSize()
  }

  @IBAction func didTapClose(sender: UIButton) {
    self.delegate?.fullScreenComicDidTapClose(self)
  }
}
