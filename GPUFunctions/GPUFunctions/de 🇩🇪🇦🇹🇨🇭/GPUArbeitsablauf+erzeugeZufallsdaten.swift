/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

import Foundation

extension GPUArbeitsablauf {
  /// Erzeugen von Zufallszahlen in der gewünschten Menge
  ///
  /// - Parameters:
  ///   - anzahl: Menge der gewünschten Zufallszahlen
  ///
  /// - Returns: Array mit Zufallszahlen, wobei keine dieser größer ist als 2147483646
  internal func erzeugeZufallsdaten (anzahl : Int) -> [Int] {
    var result = [Int].init(repeating: 0, count: anzahl)
    for index in 0..<result.count {
      result[index] = Int (arc4random_uniform((UInt32.max / 2)-1)) // Maximal 2147483646
    }
    return result
  }
}
