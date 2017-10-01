import UIKit

class UVRootViewController: UIViewController {

  var comicManager = UVComicManager.sharedInstance
  var someComic: UVComic?

  override func viewDidLoad() {
    super.viewDidLoad()
  }

  @IBAction func testButtonDidTap(_ sender: UIButton) {
    print("Starting...")

    guard let currentComicId = comicManager.currentComicId else {
      print("Can't fetch comics; manager not ready")
      return
    }

    for i in 0..<10 {
      let comicId = currentComicId - i
      self.fetchComic(comicId)
    }
  }

  func fetchComic(_ comicId: Int) {
    self.comicManager.fetchComic(comicId: comicId, comicCallback: { (comic: UVComic?, error: Error?) in
      self.someComic = comic
      if let comic = comic {
        print("Comic fetched: \(comic)")
      } else {
        let errorMessage = error != nil ? String.init(describing: error) : "<UNKNOWN>"
        print("Could not fetch comic: \(errorMessage)")
      }
    }) { (comic: UVComic, error: Error?) in
      if comic.image != nil {
        print("Image fetched for comic: \(comic)")
      } else {
        let errorMessage = error != nil ? String.init(describing: error) : "<UNKNOWN>"
        print("Could not fetch image for comic: \(comic). Error: \(errorMessage)")
      }
    }
  }
}
