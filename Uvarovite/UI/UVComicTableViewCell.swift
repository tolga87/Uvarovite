import Foundation
import UIKit

class UVComicTableViewCell : UITableViewCell {
  @IBOutlet var infoLabel: UILabel!
  @IBOutlet var favoriteButton: UIButton?
  @IBOutlet var comicImageView: UIImageView!
  @IBOutlet var footerView: UIView!
  @IBOutlet var altTextLabel: UVLabel!
  @IBOutlet var shareButtonSpinner: UIActivityIndicatorView!

  var comic: UVComic?
  var imageSize: CGSize?

  static let animationDuration: TimeInterval = 0.75

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

  override func awakeFromNib() {
    super.awakeFromNib()
    self.footerView?.backgroundColor = UIColor.lightBlue
    self.altTextLabel.alpha = 0
    self.altTextLabel.layer.cornerRadius = 4
    self.altTextLabel.layer.masksToBounds = true

    self.altTextLabel.edgeInsets = UIEdgeInsetsMake(1, 4, 1, 4)
    self.altTextLabel.adjustsFontSizeToFitWidth = true
    self.altTextLabel.minimumScaleFactor = 0.33

    self.setFavorite(false)

    NotificationCenter.default.addObserver(forName: UVRootViewController.activityViewControllerDidShowNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.shareButtonSpinner.stopAnimating()
    }
    NotificationCenter.default.addObserver(forName: UVFavoritesManager.favoritesUpdatedNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.updateFavoriteStatus()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    self.infoLabel.attributedText = nil
    self.altTextLabel.alpha = 0
    self.altTextLabel.text = nil
    self.imageConstraint = nil
    self.comicImageView?.image = nil
    self.setFavorite(false)
  }

  @IBAction func didTapFavoriteButton(sender: UIButton) {
    guard let comicId = self.comic?.id else {
      return
    }

    let favoritesManager = UVFavoritesManager.sharedInstance
    let isFavorite = favoritesManager.isFavorite(id: comicId)
    if isFavorite {
      favoritesManager.unfavoriteComic(id: comicId)
    } else {
      favoritesManager.favoriteComic(id: comicId)
    }
  }

  private func updateFavoriteStatus() {
    if let comicId = self.comic?.id {
      let isFavorite = UVFavoritesManager.sharedInstance.isFavorite(id: comicId)
      self.setFavorite(isFavorite)
    }
  }

  private func setFavorite(_ isFavorite: Bool) {
    let starImageName = (isFavorite ? "star-filled-50" : "star-50")
    self.favoriteButton?.setImage(UIImage.init(named: starImageName),
                                  for: UIControlState.normal)
  }

  func updateWithComic(_ comic: UVComic) {
    self.comic = comic
    self.infoLabel.attributedText = UVComicPresenter.attributedStringWith(comicId: comic.id,
                                                                          title: comic.title,
                                                                          date: comic.date)
    self.altTextLabel.text = comic.altText

    var image = comic.image
    if image == nil {
      image = UIImage.init(named: "image-na-icon")
    }
    self.setComicImage(image)
    self.updateFavoriteStatus()
  }

  @IBAction func didTapShare(sender: UIButton) {
    if let comic = self.comic {
      self.shareButtonSpinner.startAnimating()
      comic.shareDelegate?.comicDidRequestShare(comic)
    }
  }

  @IBAction func didTapOpen(sender: UIButton) {
    if let url = self.comic?.webUrl {
      UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
  }

  @IBAction func didTapShowAltText(sender: UIButton) {
    self.showAltText()
  }

  func showAltText() {
    UIView.animate(withDuration: UVComicTableViewCell.animationDuration) {
      self.altTextLabel.alpha = 1
    }

    let delayTime = DispatchTime.now() + 10
    DispatchQueue.main.asyncAfter(deadline: delayTime) {
      self.hideAltText()
    }
  }

  private func hideAltText() {
    UIView.animate(withDuration: UVComicTableViewCell.animationDuration) {
      self.altTextLabel.alpha = 0
    }
  }

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
