/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */


/// 🏃🏼💨💨💨

import Foundation

print (CommandLine.arguments[0])

private let lang = Locale.current.language.languageCode ?? .german
switch lang {
case .german :
  print ("Sehr geehrte Damen, Herren und andere Geschlechter! 🇩🇪🇦🇹🇨🇭")
  GPUArbeitsablauf.main()
  break
default :
  print ("Moin! 🇩🇪🇦🇹🇨🇭")
  GPUArbeitsablauf.main()
  break
}
