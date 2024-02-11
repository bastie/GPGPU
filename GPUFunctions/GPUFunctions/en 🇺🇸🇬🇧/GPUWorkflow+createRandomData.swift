/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

import Foundation

extension GPUWorkflow {
  /// Create specific count of  random numbers
  ///
  /// - Parameters:
  ///   - count: count of needed random numbers
  ///
  /// - Returns: with random numbers filled array. Max value of number is 2147483646.
  internal func createRandomData (count : Int) -> [Int] {
    var result = [Int].init(repeating: 0, count: count)
    for index in 0..<result.count {
      result[index] = Int (arc4random_uniform((UInt32.max / 2)-1)) // max 2147483646
    }
    return result
  }
}
