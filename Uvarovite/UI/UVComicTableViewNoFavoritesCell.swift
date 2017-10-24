import Foundation
import UIKit

class UVComicTableViewNoFavoritesCell : UITableViewCell {
  @IBOutlet var infoLabel: UVLabel!

  override func awakeFromNib() {
    super.awakeFromNib()

    self.backgroundColor = UIColor.darkBlue
    self.infoLabel.edgeInsets = UIEdgeInsetsMake(4, 4, 4, 4)
    self.infoLabel.textColor = UIColor.white
  }
}
