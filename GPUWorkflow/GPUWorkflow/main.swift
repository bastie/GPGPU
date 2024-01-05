//
//  File.swift
//  GPUWorkflow
//
//  Created by Sebastian Ritter on 02.01.24.
//

/// 🏃🏼💨💨💨

import Foundation

print (CommandLine.arguments[0])

private let lang = Locale.current.language.languageCode ?? .german
switch lang {
case .portuguese:
  print ("Bom dia! 🇵🇹🇧🇷")
case .english :
  print ("Hello! 🇺🇸🇬🇧")
case .german :
  print ("Sehr geehrte Damen, Herren und andere Geschlechter! 🇩🇪🇦🇹🇨🇭")
  GPUArbeitsablauf.main()
  break
default :
  print ("Moin! 🇩🇪🇦🇹🇨🇭")
  break
}
