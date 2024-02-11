/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

import Foundation

extension GPUFluxoDeTrabalho {
  /// Cria números aleatórios na quantidade desejada
  ///
  /// - Parameters:
  ///   - contagem: Quantidade de números aleatórios desejados
  ///
  /// - Returns: Matriz de números aleatórios, nenhum maior que 2147483646
  internal func criaDadosAleatórios (contagem : Int) -> [Int] {
    var result = [Int].init(repeating: 0, count: contagem)
    for index in 0..<result.count {
      result[index] = Int (arc4random_uniform((UInt32.max / 2)-1)) // Maximal 2147483646
    }
    return result
  }
}

