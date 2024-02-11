/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

import Foundation
import Metal

//@main
/// Der GPU Arbeitsablauf.
///
/// Der GPU Arbeitsablauf gestaltet sich zunächst durch die Schrite
/// 1. Das `device`, sprich die GPU ermitteln
/// 1. Die GPU Bibliothek bekannt machen, standardmäßig ist dies die "default.metallib"
/// 1. Die zu verwendene Funktion "kernel" referenzieren
/// 1. Mit dem `device` die Aufgabenverwaltung `command queue` für die Anweisungen bereitstellen
/// 1. Mit der `command queue` den Puffer für die Hardwareanweisungen zur Verfügung stellen
/// 1. Die Hardwareanweisungen mit dem `command encoder` in die konkreten API Aufrufe übersetzen - für uns natürlich der **ComputeCommandEncoder**
///
/// |  Metal Objekte | Aufgabe |
/// | --- | --- |
/// | `device` | Zugriff auf die GPU |
/// | `command queue` | Aufgabenverwaltung von `command buffer` Anweisungen |
/// | `command buffer` | Puffer GPU Hardwareanweisungen |
/// | `command encoder` | Übersetzung der API Aufrufe in die GPU Hardwareanweisungen, speziell der `compute command encoder` |
/// | `state` | Konfiguration |
/// | `code` | Die `shader` |
/// | `resources` | Datenpuffer, Texturen etc. |
struct GPUArbeitsablauf {
  
  /// Start der Anwendung
  ///
  /// Der *``main()`` entry point* wird beim Start der Anwendung aufgerufen. Dieser kann durch eine Datei `main.swift` definiert werden oder durch einen Typ *struct* mit dem Auszeichner `@main` und der zugehörigen Funktion `static func main(){}`.
  ///
  /// - Warning: Die Definition von mehreren *``main()`` entry points* führt zu einem Kompilerfehler.
  ///
  public static func main () {
    let arbeitsablauf = GPUArbeitsablauf()
    arbeitsablauf.gpuBerechnung(berechnungsanzahl: 1_000_000)
  }
  
  /// Berechnung auf der GPU ausführen
  ///
  /// - Parameters:
  ///   - berechnungsanzahl Anzahl der Berechnungen
  private func gpuBerechnung (berechnungsanzahl : Int) {
    // Die GPU ermitteln
    let gpuDevice = self.lookingForGPU(andPrintInfo : false)
    // Die Bibliothek mit den GPU Funktionen laden
    let bibliothek = self.ladeMetalBibliothek(für: gpuDevice)
    // Die aufzurufende Funktion referenzieren und die "command queue" erstellen
    let aufzurufendeFunktion = "gpuFunktion"
    if let kernel = bibliothek.makeFunction(name: aufzurufendeFunktion), let commandQueue = gpuDevice.makeCommandQueue() {

      /// Durch Übergabe des descriptor können wir Fehler "besser" im Metal Code ausmachen, WWDC 20, Debug GPU-side errors in Metal
      let descriptor = MTLCommandBufferDescriptor()
      descriptor.errorOptions = .encoderExecutionStatus
      if let commandBuffer = commandQueue.makeCommandBuffer(descriptor: descriptor) {
        // Auch den CommandBuffer arbeiten wir für weitere Fehlerbearbeitung um, WWDC 20, Debug GPU-side errors in Metal
        commandBuffer.addCompletedHandler { (commandBuffer) in
          for log in commandBuffer.logs {
            let encoderLabel = log.encoderLabel ?? "Kein Label gesetzt"
            print ("Fault encoder Name \(encoderLabel)")
            guard let location = log.debugLocation, let functionName = log.function?.name else {
              return
            }
            print ("Fehlerpostion \(functionName):\(location.line):\(location.column)")
          }
        }
        // Jetzt endlich kommt der ComputeCommandEncoder
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
          let status = try! gpuDevice.makeComputePipelineState(function: kernel)
          encoder.setComputePipelineState(status)
          
          // MARK: neu in GPUFunktion (Teil 1 - Eingabedaten)
          // Unsere Kernelfunktion ist definiert als:
          /*
           kernel void gpuFunktion (
             constant int* eingabe1 [[ buffer(0)]],   // Eingabedaten unveränderlich
             constant int* eingabe2 [[ buffer(1)]],   // Eingabedaten unveränderlich
               device int* ausgabe  [[buffer(2)]],    // Ausgabedaten
                      uint index    [[ thread_position_in_grid ]] // Threadnummer
           )*/
          // Die Eingabedaten müssen wir jetzt bereitstellen (die Ausgabedaten kommen später und die Threadnummer gibt es umsonst)
          let eingabe1 : [Int] = erzeugeZufallsdaten(anzahl: berechnungsanzahl) // eingabe1 als int Array
          let eingabe2 : [Int] = erzeugeZufallsdaten(anzahl: berechnungsanzahl) // eingabe2 als int Array

          let eingabe1AlsPuffer = gpuDevice.makeBuffer(bytes: eingabe1, length: MemoryLayout<Int>.size * berechnungsanzahl, options: .storageModeShared)
          let eingabe2AlsPuffer = gpuDevice.makeBuffer(bytes: eingabe2, length: MemoryLayout<Int>.size * berechnungsanzahl, options: .storageModeShared)
          
          let ausgabeAlsPuffer = gpuDevice.makeBuffer(length: MemoryLayout<Int>.size * berechnungsanzahl, options: .storageModeShared) // wir kennen die Länge unseres Ergebnisses
          
          // Jetzt werden der Methode die Parameter zugewiesen
          encoder.setBuffer(eingabe1AlsPuffer, offset: 0, index: 0)
          encoder.setBuffer(eingabe2AlsPuffer, offset: 0, index: 1)
          encoder.setBuffer(ausgabeAlsPuffer, offset: 0, index: 2)
          // EOM
          
          // Wir müssen die Anzahl unserer Verarbeitungen angeben. Dies darf nicht mehr als die maximale Anzahl der Threads auf der GPU und auch nicht mehr als die maximale Anzahl der Threads pro Threadgroup sein. Bei 1024 könnte dies z.B. 2*8*64 sein oder auch 1024*1*1
          let breite = status.maxTotalThreadsPerThreadgroup
          let threadsProGrid : MTLSize = MTLSizeMake(breite,1, 1)
          let threadsProThreadgroup = MTLSizeMake(breite, 1, 1)
          encoder.dispatchThreadgroups(threadsProGrid, threadsPerThreadgroup: threadsProThreadgroup)
          
          // Für die Ausführung teilen wir zunächst mit, dass wir fertig sind (``endEncoding``) und das wir starten können (``commit``)
          encoder.endEncoding()
          commandBuffer.commit()
          // Wir warten auf das Ende der Berechnungen
          commandBuffer.waitUntilCompleted()
          
          // MARK: neu in GPUFunktion (Teil 2 - Ausgabedaten)
          
          /// Variante 1 ist über einen ``UnsafeMutableRawPointer`` zu arbeiten. Dabei können die Werte typsicher bereitgestellt werden über ``load(as:<T>)`` . Beim iterieren zum nächsten Element müssen wir jedoch die Byteanzahl genau angeben. Entsprechend auch mehrere unterschiedliche Typen nacheinander geladen werden.
          var rawPointer = ausgabeAlsPuffer?.contents()

          /// Variante 2 ist mit einen typsicheren ``UnsafeMutablePoint<T>`` zu arbeiten. Die Werte werden jetzt über einen ``pointee`` auf das jeweilige Element allerdings nur noch als ``Any`` bereitgestellt. Um zum nächsten Element zu gelangen können wir jetzt jedoch bequemer hochzählen.
          var resultBufferPointer = rawPointer!.bindMemory(to: Int.self, capacity: MemoryLayout<Int>.size * berechnungsanzahl)
          
          /// Variante 3 ist wieder ein Swift Typ, hier unser ``[Int]`` bereitzustellen.
          let intBuffer = UnsafeBufferPointer (start: resultBufferPointer, count: berechnungsanzahl)
          let ausgabe = Array(intBuffer)
          
          var index = 0
          for ergebnis in ausgabe {
            /// Bei der Variante 1 müssen wir nach dem bereitstellen des Typ ``Int`` auch den Zeiger um die Größe dessen mit ``MemoryLayout<Int>.size`` verschieben und um zum nächsten Element zu kommen genau ein mal.
            print ("raw pointer: \(rawPointer!.load(as: Int.self)) = \(eingabe1[index]) + \(eingabe2[index])")
            rawPointer = rawPointer?.advanced(by: 1 * MemoryLayout<Int>.size)
            
            /// Bei der Veriante 2 müssen wir den Wert an der Stelle des Zeiger zunächst als einen ``Int`` Type bereitstellen. Dafür entfällt das Berechnen wie weit unser Zeiger zu verschieben ist und wir können direkt diesen um ein Element vorschieben.
            print ("pointee    : \(Int(resultBufferPointer.pointee) as Any) = \(eingabe1[index]) + \(eingabe2[index])")
            resultBufferPointer = resultBufferPointer.advanced(by: 1)
            
            /// Mit der Variante 3 haben wir die Welt der Zeiger bereits verlassen und müssen uns keine Gedanken mehr über die Zeiger machen.
            print("array      : \(ergebnis) = \(eingabe1[index]) + \(eingabe2[index])")
            
            print(String(repeating: "-", count: 50))
            index += 1 // wird nur benötigt, da wir die Eingabedaten anzeigen lassen wollen
          }
          // EOM
          
          // etwas Fehlerbehandlung, WWDC 20, Debug GPU-side errors in Metal
          if let error = commandBuffer.error as? NSError{
            if let encoderInfo = error.userInfo[MTLCommandBufferEncoderInfoErrorKey] as? [MTLCommandBufferEncoderInfo] {
              for info in encoderInfo {
                print("\(info.label) \(info.debugSignposts.joined())")
                if info.errorState == .faulted {
                  print("\(info.label) fauled")
                }
              }
              print(error)
            }
          }
        }
      }
      
    }
    else {
      fatalError("Kernel \(aufzurufendeFunktion) nicht gefunden")
    }

  }
  
  private func ladeMetalBibliothek (für device : MTLDevice, with printInfo : Bool = true) -> MTLLibrary {
    if let library = device.makeDefaultLibrary() {
      if printInfo {
        print ("Bibliothek\n================================")
        print ("Name: \(library.installName ?? "default.metallib")")
        print ("Funktionen: \(library.functionNames)")
        print()
      }
      return library
    }
    else {
      fatalError("Bibliothek nicht gefunden")
    }
  }
  
  private func lookingForGPU (andPrintInfo printInfo : Bool = true) -> MTLDevice {
    // im interaktivem Kontext wir können MTLCreateSystemDefaultDevice benutzen, hier benötigen wir eine MTLCopyAllDevices-Variante
    let allDevices = MTLCopyAllDevices() // wir reagieren nicht mit Observer Variante auf Änderungen
    
    // Ohne GPU geht es nicht
    guard !allDevices.isEmpty else {
      fatalError("Keine GPU gefunden.")
    }
    
    var device = allDevices [0]
    // nach Möglichkeit soll die fest verbaute GPU Verwendung finden in diesem Beispiel
    if device.isRemovable {
      for next in allDevices {
        if device.isRemovable && !next.isRemovable {
          device = next
        }
      }
    }

    // wir geben einige Information über die genutze GPU aus, wenn dies gewollt ist
    if printInfo {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.locale = Locale.current
      
      print ("GPU Name: \(device.name)")
      print ("Gemeinsam mit CPU genutzerte Speicher: \(device.hasUnifiedMemory)")
      print ("Monitor angeschlossen: \(!device.isHeadless)")
      print ("GPU entfernbar (eGPU): \(device.isRemovable)")
      print ("Stromsparmodus: \(device.isLowPower)")
      print ("Speichergrenze ohne Performanceprobleme: \(String(describing: formatter.string(for: device.recommendedMaxWorkingSetSize)!)) Bytes")
      print ("Maximale Threadanzahl pro Gruppe: \(device.maxThreadsPerThreadgroup)")
      print()
    }

    return device
  }
}

