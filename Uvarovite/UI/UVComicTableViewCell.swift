import Foundation
import UIKit

class UVComicTableViewCell : UITableViewCell {
  @IBOutlet var infoLabel: UILabel!
  @IBOutlet var favoriteButton: UIButton?
  @IBOutlet var comicImageView: UIImageView!
  @IBOutlet var footerView: UIView!
  @IBOutlet var altTextLabel: UVLabel!
  @IBOutlet var shareButtonSpinner: UIActivityIndicatorView!

  private var dateFormatter: DateFormatter = DateFormatter()

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

    self.dateFormatter.dateFormat = "yyyy-MM-dd"

    NotificationCenter.default.addObserver(forName: UVRootViewController.activityViewControllerDidShowNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.shareButtonSpinner.stopAnimating()
    }
  }

  override func prepareForReuse() {
    super.prepareForReuse()

    self.infoLabel.attributedText = nil
    self.altTextLabel.alpha = 0
    self.altTextLabel.text = nil
    self.imageConstraint = nil
    self.comicImageView?.image = nil
  }

  @IBAction func didTapFavoriteButton(sender: UIButton) {
    print("Comic \(self.comic!.id) will be marked as favorite")
  }

  func updateWithComic(comic: UVComic) {
    self.comic = comic

    func getAttributedStringWith(comicId: Int, title: String, date: Date?) -> NSAttributedString {
      let attributedString = NSMutableAttributedString()

      let comicIdString = NSAttributedString.init(string: "#\(comicId)  ",
                                                  attributes: [
                                                    .font : UIFont.systemFont(ofSize: 14),
                                                    .foregroundColor : UIColor.lightGray,
                                                    ])
      attributedString.append(comicIdString)

      let titleString = NSAttributedString.init(string: title,
                                                attributes: [
                                                  .font : UIFont.systemFont(ofSize: 20),
                                                  .foregroundColor : UIColor.white,
                                                  ])
      attributedString.append(titleString)

      if let date = date {
        let dateString = NSAttributedString.init(string: "\n\(self.dateFormatter.string(from: date))",
          attributes: [
            .font : UIFont.systemFont(ofSize: 14),
            .foregroundColor : UIColor.lightGray,
            ])
        attributedString.append(dateString)
      }

      return attributedString
    }

    self.infoLabel.attributedText = getAttributedStringWith(comicId: comic.id,
                                                            title: comic.title ?? "",
                                                            date: comic.date)
    self.altTextLabel.text = comic.altText

    var image = comic.image
    if image == nil {
      image = UIImage.init(named: "image-na-icon")
    }
    self.setComicImage(image)
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
