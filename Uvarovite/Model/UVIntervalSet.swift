
import Foundation

struct UVInterval {
  var start: Int
  var end: Int

  var length: Int {
    get {
      return self.end - self.start + 1
    }
  }

  init(_ start: Int, _ end: Int) {
    self.start = start
    self.end = end
  }
}

enum UVIntervalExtensionDirection {
  case left
  case right
}

class UVIntervalSet {
  static let intervalLengthChangedNotification = Notification.Name("intervalLengthChanged")
  static let intervalLengthChangedNotificationRangeKey = "range"

  private var startPoints = [Int: UVInterval]()
  private var endPoints = [Int: UVInterval]()

  var length: Int {
    get {
      if let interval = self.startPoints[0] {
        return interval.length
      } else {
        return 0
      }
    }
  }

  func addItem(_ index: Int) {
    let lengthBefore = self.length

    let leftInterval = self.endPoints[index - 1]
    let rightInterval = self.startPoints[index + 1]

    if let left = leftInterval, let right = rightInterval {
      let newStart = left.start
      let newEnd = right.end
      let newInterval = UVInterval(newStart, newEnd)
      self.removeInterval(left)
      self.removeInterval(right)
      self.addInterval(newInterval)
    } else if let left = leftInterval {
      self.extendInterval(left, to: .right)
    } else if let right = rightInterval {
      self.extendInterval(right, to: .left)
    } else {
      self.addInterval(UVInterval(index, index))
    }

    let lengthAfter = self.length

    if lengthAfter != lengthBefore {
      let newRange: ClosedRange = lengthBefore...(lengthAfter - 1)
      NotificationCenter.default.post(name: UVIntervalSet.intervalLengthChangedNotification,
                                      object: self,
                                      userInfo: [UVIntervalSet.intervalLengthChangedNotificationRangeKey : newRange])
    }
  }

  private func removeInterval(_ interval: UVInterval) {
    self.startPoints.removeValue(forKey: interval.start)
    self.endPoints.removeValue(forKey: interval.end)
  }

  private func addInterval(_ interval: UVInterval) {
    self.startPoints[interval.start] = interval
    self.endPoints[interval.end] = interval
  }

  private func extendInterval(_ interval: UVInterval, to direction: UVIntervalExtensionDirection) {
    switch direction {
    case .left:
      let newInterval = UVInterval(interval.start - 1, interval.end)
      self.startPoints[interval.start - 1] = newInterval
      self.endPoints[interval.end] = newInterval
      self.startPoints.removeValue(forKey: interval.start)
    case .right:
      let newInterval = UVInterval(interval.start, interval.end + 1)
      self.startPoints[interval.start] = newInterval
      self.endPoints[interval.end + 1] = newInterval
      self.endPoints.removeValue(forKey: interval.end)
  }
  }

  func printIntervals() {
    var desc = "\t\tComic intervals:"
    let sortedStartPoints = Array(self.startPoints.keys).sorted()
    for startPoint in sortedStartPoints {
      let interval = self.startPoints[startPoint]!
      desc += " [\(interval.start), \(interval.end)]"
    }
    print(desc)
  }


}



















//~TA

