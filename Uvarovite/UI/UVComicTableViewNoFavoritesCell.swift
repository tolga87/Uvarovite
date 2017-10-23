import Foundation
import UIKit

class UVComicTableViewNoFavoritesCell : UITableViewCell {
  @IBOutlet var infoLabel: UILabel!

  override func awakeFromNib() {
    super.awakeFromNib()

    self.backgroundColor = UIColor.darkBlue
    self.infoLabel.textColor = UIColor.black
  }
}
