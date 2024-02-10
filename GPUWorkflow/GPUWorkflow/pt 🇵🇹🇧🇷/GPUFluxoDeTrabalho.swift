/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

import Foundation
import Metal

//@main
/// O fluxo de trabalho da GPU.
///
/// O fluxo de tarbalho da GPU contém as seguintes etapas
/// 1. Localize o `dispositivo` (device) que representa a GPU
/// 1. Deixe o programa conhecer a biblioteca GPU. Por padrão é o "default.metallib"
/// 1. Crie uma referência para a função também conhecida como "kernel" que queremos usar
/// 1. A partir do `dispositivo` crie a `fila de comando` para todos os comandos únicos
/// 1. Com a `fila de comando` crie o buffer para os comandos de hardware
/// 1. Os comandos concretos da API de hardware seriam traduzidos da fonte com o `command encoder` - usamos o **ComputeCommandEncoder**
///
/// | objetos de Metal | tarefas |
/// | --- | --- |
/// | `device` | conexão com a GPU |
/// | `command queue` | gerenciamento de tarefas para `command buffer` |
/// | `command buffer` | Comandos de hardware da GPU de buffer |
/// | `command encoder` | Tradutor para chamadas de API de GPU de hardware, aqui o `compute command encoder` |
/// | `state` | configuração |
/// | `code` | `shader` |
/// | `resources` | dados, texturas e mais|
struct GPUFluxoDeTrabalho {
  
  /// Inicie o aplicativo
  ///
  /// O ponto de entrada *``main()``* é chamado ao iniciar nossa aplicação e pode ser declarado por um arquivo chamado `main.swift` ou com uma *struct* anotada. A anotação chamada `@main` precisa da `func estática main(){}`.
  ///
  /// - Warning: Mais de um ponto de entrada *``main()``* cria erro no compilador.
  ///
  public static func main () {
    let fluxoDeTrabalho = GPUFluxoDeTrabalho()
    
    // Obtenha a GPU
    let gpuDispositivo = fluxoDeTrabalho.procurandoGPU(eImprimirInformações : false)
    // Carregar biblioteca de funções GPU
    let biblioteca = fluxoDeTrabalho.loadMetalLibrary(for: gpuDispositivo)
    // Faça referência à função a ser chamada e crie o commandQueue
    let callFunction = "gpuFunçao"
    if let kernel = biblioteca.makeFunction(name: callFunction), let commandQueue = gpuDispositivo.makeCommandQueue() {
      
      /// Com o uso da pesquisa de erros do descritor no código Metal é mais fácil, WWDC 20, Debug GPU-side errors in Metal
      let descriptor = MTLCommandBufferDescriptor()
      descriptor.errorOptions = .encoderExecutionStatus
      if let commandBuffer = commandQueue.makeCommandBuffer(descriptor: descriptor) {
        // Além disso, o CommandBuffer pode ser usado para tratamento de erros como este, Depurar erros do lado da GPU no Metal
        commandBuffer.addCompletedHandler { (commandBuffer) in
          for log in commandBuffer.logs {
            let encoderLabel = log.encoderLabel ?? "etiqueta faltando"
            print ("Fault encoder nome \(encoderLabel)")
            guard let location = log.debugLocation, let functionName = log.function?.name else {
              return
            }
            print ("posição de erro \(functionName):\(location.line):\(location.column)")
          }
        }
        // Agora finalmente vem o ComputeCommandEncoder
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
          let status = try! gpuDispositivo.makeComputePipelineState(function: kernel)
          encoder.setComputePipelineState(status)
          // Em outro cenário, nesta posição os dados são preparados. Neste exemplo não precisamos de dados
          
          // Temos que chamar a contagem do nosso trabalho. Máximo é a contagem de threads de nossa GPU e também limitado pelo máximo de threads por grupo de threads. Por exemplo: No resultado máximo de 1024, isso pode ser 2*8*64 ou 1024*1*1
          let width = status.maxTotalThreadsPerThreadgroup
          let threadsPerGrid : MTLSize = MTLSizeMake(width,1, 1)
          let threadsPerThreadgroup = MTLSizeMake(width, 1, 1)
          encoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
          
          // Antes de executar, chamamos primeiro que não há nenhum comando que tenhamos com (``endEncoding``). Mais tarde inicie a computação com (``commit``)
          encoder.endEncoding()
          commandBuffer.commit()
          // Queremos esperar até o fim da computação
          commandBuffer.waitUntilCompleted()
          
          // algum tratamento de erros, WWDC 20, Depurar erros do lado da GPU no Metal
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
      fatalError("Kernel \(callFunction) not found")
    }
    
  }
  
  private func loadMetalLibrary (for device : MTLDevice, with printInfo : Bool = true) -> MTLLibrary {
    if let library = device.makeDefaultLibrary() {
      if printInfo {
        print ("Biblioteca\n================================")
        print ("Nome: \(library.installName ?? "default.metallib")")
        print ("Funções: \(library.functionNames)")
        print()
      }
      return library
    }
    else {
      fatalError("Biblioteca não encontrada")
    }
  }
  
  private func procurandoGPU (eImprimirInformações imprimirInformações : Bool = true) -> MTLDevice {
    // no contexto interativo podemos usar MTLCreateSystemDefaultDevice, aqui precisamos de uma variante MTLCopyAllDevices
    let allDevices = MTLCopyAllDevices() // não reagimos às mudanças com a variante Observer
    
    // Não funciona sem uma GPU
    guard !allDevices.isEmpty else {
      fatalError("No GPU found.")
    }
    
    var device = allDevices [0]
    // Neste exemplo, a GPU instalada permanentemente deve ser usada, se possível
    if device.isRemovable {
      for next in allDevices {
        if device.isRemovable && !next.isRemovable {
          device = next
        }
      }
    }
    
    // fornecemos algumas informações sobre a GPU usada, se desejar
    if imprimirInformações {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.locale = Locale.current
      
      print ("GPU Nome: \(device.name)")
      print ("RAM usando junto com CPU: \(device.hasUnifiedMemory)")
      print ("Monitor encontrado: \(!device.isHeadless)")
      print ("GPU removível (eGPU): \(device.isRemovable)")
      print ("modo de economia de energia: \(device.isLowPower)")
      print ("Tamanho da RAM sem problemas de desempenho: \(String(describing: formatter.string(for: device.recommendedMaxWorkingSetSize)!)) bytes")
      print ("Máximo de threads por grupo: \(device.maxThreadsPerThreadgroup)")
      print()
    }
    
    return device
  }
}

