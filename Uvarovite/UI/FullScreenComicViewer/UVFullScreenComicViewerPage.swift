import Foundation
import UIKit

protocol UVFullScreenComicDelegate {
  func fullScreenComicDidTapClose(_ page: UVFullScreenComicViewerPage)
  func fullScreenComicDidTapPrev(_ page: UVFullScreenComicViewerPage)
  func fullScreenComicDidTapNext(_ page: UVFullScreenComicViewerPage)
  func fullScreenComic(_ comic: UVFullScreenComicViewerPage, didRequestUrl url: URL)
}

// ##############################################################################################

class UVFullScreenComicViewerPage : UIView, UIScrollViewDelegate {
  var comic: UVComic? {
    didSet {
      self.imageView.image = comic?.image
      self.updateComicInfo()
      self.updateImageSize()
      self.updateFavoriteStatus()
    }
  }

  var delegate: UVFullScreenComicDelegate?
  let comicImageHorizontalPadding = CGFloat(5)

  @IBOutlet var headerView: UIView!
  @IBOutlet var titleLabel: UILabel!
  @IBOutlet var comicScrollView: UIScrollView!
  @IBOutlet var comicScrollViewContentView: UIView!

  @IBOutlet var imageView: UIImageView!
  @IBOutlet var imageViewWidthConstraint: NSLayoutConstraint!
  @IBOutlet var imageViewHeightConstraint: NSLayoutConstraint!

  var altTextLabel: UVLabel!

  @IBOutlet var footerView: UIView!
  @IBOutlet var prevButton: UIButton!
  @IBOutlet var favoriteButton: UIButton!
  @IBOutlet var altTextButton: UIButton!
  @IBOutlet var shareButton: UIButton!
  @IBOutlet var explainButton: UIButton!
  @IBOutlet var nextButton: UIButton!


  class func instanceFromNib() -> UVFullScreenComicViewerPage {
    let view = UINib(nibName: "UVFullScreenComicViewerPage", bundle: nil).instantiate(withOwner: nil, options: nil)[0] as! UVFullScreenComicViewerPage
    view.setupView()
    return view
  }

  func setupView() {
    self.imageView.contentMode = .scaleAspectFit
    self.footerView.backgroundColor = .darkBlue
    self.altTextLabel = UVComicPresenter.altTextLabel()
    self.altTextLabel.alpha = 0
    self.addSubview(self.altTextLabel)

    self.comicScrollView.delegate = self
    self.comicScrollView.minimumZoomScale = 1
    self.comicScrollView.maximumZoomScale = 2
    self.comicScrollView.bouncesZoom = true
    self.comicScrollView.showsHorizontalScrollIndicator = false
    self.comicScrollView.showsVerticalScrollIndicator = false
    NotificationCenter.default.addObserver(forName: UVFavoritesManager.favoritesUpdatedNotification,
                                           object: nil,
                                           queue: OperationQueue.main) { (notification: Notification) in
                                            self.updateFavoriteStatus()
    }
  }

  // MARK: - Buttons

  @IBAction func didTapPrev(sender: UIButton) {
    self.delegate?.fullScreenComicDidTapPrev(self)
  }

  @IBAction func didTapNext(sender: UIButton) {
    self.delegate?.fullScreenComicDidTapNext(self)
  }

  @IBAction func didTapFavorite(sender: UIButton) {
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

  @IBAction func didTapShare(sender: UIButton) {
    if let comic = self.comic {
      comic.shareDelegate?.comicDidRequestShare(comic)
    }
  }

  @IBAction func didTapAltText(sender: UIButton) {
    self.setAltTextVisible(!self.isAltTextVisible())
  }

  @IBAction func didTapExplain(sender: UIButton) {
    guard let comicId = self.comic?.id else {
      return
    }

    let urlString = "http://www.explainxkcd.com/wiki/index.php/\(comicId)"
    let url = URL(string: urlString)!
    self.delegate?.fullScreenComic(self, didRequestUrl: url)
  }

  @IBAction func didTapClose(sender: UIButton) {
    self.delegate?.fullScreenComicDidTapClose(self)
  }

  // MARK: - Layout

  override func layoutSubviews() {
    super.layoutSubviews()
    self.updateImageSize()
    self.layoutAltTextLabel()
    self.layoutFooterButtons()

    self.comicScrollView.contentSize = self.comicScrollViewContentView.frame.size
  }

  func resetZoom() {
    self.comicScrollView.setZoomScale(1, animated: true)
  }

  // TODO: eliminate redundancy
  private func updateFavoriteStatus() {
    if let comicId = self.comic?.id {
      let isFavorite = UVFavoritesManager.sharedInstance.isFavorite(id: comicId)
      self.setFavorite(isFavorite)
    } else {
      self.setFavorite(false)
    }
  }

  private func setFavorite(_ isFavorite: Bool) {
    let starImageName = (isFavorite ? "star-filled-100" : "star-100")
    self.favoriteButton?.setImage(UIImage.init(named: starImageName),
                                  for: UIControlState.normal)
  }

  func isAltTextVisible() -> Bool {
    return self.altTextLabel.alpha == 1.0
  }

  func setAltTextVisible(_ visible: Bool) {
    UIView.animate(withDuration: 0.1) {
      self.altTextLabel.alpha = (visible ? 1 : 0)
    }
  }

  func updateComicInfo() {
    if let comic = self.comic {
      self.titleLabel.attributedText = UVComicPresenter.attributedStringWith(comicId: comic.id,
                                                                             title: comic.title,
                                                                             date: comic.date)
      self.altTextLabel.text = comic.altText
    } else {
      self.titleLabel.attributedText = nil
      self.altTextLabel.text = ""
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

  func layoutAltTextLabel() {
    let horizontalPadding = CGFloat(10)
    let verticalPadding = CGFloat(20)
    let height = CGFloat(80)
    let width = self.frame.width - CGFloat(2.0) * horizontalPadding
    let originX = horizontalPadding
    let originY = self.footerView.frame.minY - verticalPadding - height
    self.altTextLabel.frame = CGRect(x: originX, y: originY, width: width, height: height)
  }

  func layoutFooterButtons() {
    let horizontalPadding = CGFloat(20)
    let buttonWidth = CGFloat(30)
    let buttonHeight = CGFloat(30)
    let buttonY = (self.footerView.frame.height - buttonHeight) / 2.0

    var buttonFrame = CGRect(x: horizontalPadding, y: buttonY, width: buttonWidth, height: buttonHeight)
    self.prevButton.frame = buttonFrame

    buttonFrame.origin.x = self.footerView.frame.maxX - horizontalPadding - self.nextButton.frame.width
    self.nextButton.frame = buttonFrame

    let centerButtons = [self.favoriteButton, self.shareButton, self.altTextButton, self.explainButton]
    let centerButtonsWidth = CGFloat(centerButtons.count) * buttonWidth + CGFloat(centerButtons.count - 1) * horizontalPadding

    let centerButtonsPadding = (self.footerView.frame.width - centerButtonsWidth) / 2.0 - self.prevButton.frame.maxX
    var centerButtonX = self.prevButton.frame.maxX + centerButtonsPadding
    for case let centerButton? in centerButtons {
      var frame = centerButton.frame
      frame.origin.x = centerButtonX
      frame.origin.y = (self.footerView.frame.height - frame.height) / 2.0
      centerButton.frame = frame
      centerButtonX += (frame.width + horizontalPadding)
    }
  }

  // MARK: - UIScrollViewDelegate

  func viewForZooming(in scrollView: UIScrollView) -> UIView? {
    return self.imageView
  }

  // this makes sure the zoomed-in image is centered nicely within the scrollView.
  // taken from: https://stackoverflow.com/questions/1316451/center-content-of-uiscrollview-when-smaller
  func scrollViewDidZoom(_ scrollView: UIScrollView) {
    let offsetX: CGFloat = max((scrollView.bounds.width - scrollView.contentSize.width) / 2.0, 0.0)
    let offsetY: CGFloat = max((scrollView.bounds.height - scrollView.contentSize.height) / 2.0, 0.0)
    self.imageView.center = CGPoint(x: scrollView.contentSize.width / 2.0 + offsetX,
                                    y: scrollView.contentSize.height / 2.0 + offsetY)
  }
}
