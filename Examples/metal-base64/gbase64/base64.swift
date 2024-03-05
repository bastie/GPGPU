/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */


/// 🏃🏼💨💨💨

import Foundation


/// The application entry point
@main
struct base64 {
  public static func main() {
#if DEBUG
    print (CommandLine.arguments[0])
    switch (CommandLine.arguments.count) {
    case 1:
      CommandLine.arguments.append("/Applications/Safari.app/Contents/MacOS/Safari")      
    default:
      break
    }
    
    let lang = Locale.current.language.languageCode ?? .german
    switch lang {
    case .german :
      print ("Sehr geehrte Damen, Herren und andere Geschlechter! 🇩🇪🇦🇹🇨🇭")
      gbase64.main()
      break
    default :
      print ("Moin! 🇩🇪🇦🇹🇨🇭")
      gbase64.main()
      break
    }
#else // !DEBUG
    gbase64.main()
#endif // DEBUG
  }
}

