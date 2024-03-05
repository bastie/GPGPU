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
///
///
///
internal struct gbase64 {
  
  /// Start der Anwendung
  ///
  /// Der *``main()`` entry point* wird beim Start der Anwendung aufgerufen. Dieser kann durch eine Datei `main.swift` definiert werden oder durch einen Typ *struct* mit dem Auszeichner `@main` und der zugehörigen Funktion `static func main(){}`.
  ///
  /// - Warning: Die Definition von mehreren *``main()`` entry points* führt zu einem Kompilerfehler.
  ///
  public static func main () {
    let arbeitsablauf = gbase64()
    let path = CommandLine.arguments[1]
    arbeitsablauf.base64(for: path)
  }
  
  /// Berechnung auf der GPU ausführen
  ///
  /// - Parameters:
  ///   - for path  Anzahl der Berechnungen
  private func base64 (`for` path : String) {
    let gpuDevice = self.lookingForGPU(andPrintInfo : false)
    let bibliothek = self.ladeMetalBibliothek(für: gpuDevice, with: false)
    // Die aufzurufende Funktion referenzieren und die "command queue" erstellen
    let aufzurufendeFunktion = "base64"
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
          
          // Unsere Kernelfunktion ist definiert als:
          /*
           kernel void gpuFunktion (
           constant uint8* eingabe1 [[ buffer(0)]],   // Eingabedaten unveränderlich
           device uint8* ausgabe  [[buffer(1)]],    // Ausgabedaten
           uint index    [[ thread_position_in_grid ]] // Threadnummer
           )*/

          do {
            let eingabe1 : [UInt8] = [UInt8](try Data(contentsOf: URL(filePath: path)))
            
            let eingabe1AlsPuffer = gpuDevice.makeBuffer(bytes: eingabe1, length: MemoryLayout<UInt8>.size * eingabe1.count, options: .storageModeShared)
            // Berechnet wird nun die Zielgröße unter Berücksichtigung eines ggf. notwendigen Padding.
            let ausgabeGroesse =  {
              switch (eingabe1.count % 3) {
              case 0: eingabe1.count / 3 * 4
              default :  Int(eingabe1.count / 3 + 1) * 4
              }
            }()
            let ausgabeAlsPuffer = gpuDevice.makeBuffer(length: MemoryLayout<UInt8>.size * ausgabeGroesse, options: .storageModeShared) // wir kennen die Länge unseres Ergebnisses
            
            // Jetzt werden der Methode die Parameter zugewiesen
            encoder.setBuffer(eingabe1AlsPuffer, offset: 0, index: 0)
            encoder.setBuffer(ausgabeAlsPuffer, offset: 0, index: 1)
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
            
            // Die Daten werden wieder Swiftly gemacht
            
            let rawPointer = ausgabeAlsPuffer?.contents()
            let resultBufferPointer = rawPointer!.bindMemory(to: UInt8.self, capacity: MemoryLayout<UInt8>.size * ausgabeGroesse)
            let uint8Buffer = UnsafeBufferPointer (start: resultBufferPointer, count: ausgabeGroesse)
            
            
            // Verzweigungen sollten innerhalb von Kernelfunktionen vermieden werden,
            // daher erfolgt das Padding nachgängig in Swift
            var ausgabe = Array(uint8Buffer)
            switch (eingabe1.count % 3) {
            case 1 :
              ausgabe[ausgabe.count-2] = 61
              fallthrough
            case 2 :
              ausgabe[ausgabe.count-1] = 61
            default:
              break
            }
            
            let result = Data(ausgabe)
            //let asString = String(data: result, encoding: .ascii)
#if DEBUG
            try result.write(to: URL(filePath: "/Users/Shared/Safari.b64"), options: .atomic)
#else
            try result.write(to: URL(filePath: "\(path).b64"), options: .atomic)
#endif
            
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
          catch {
            print ("Shit happens, keep calm")
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

