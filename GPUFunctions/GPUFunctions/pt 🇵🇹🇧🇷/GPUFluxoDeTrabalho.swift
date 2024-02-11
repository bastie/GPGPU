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
    fluxoDeTrabalho.cálculoDeGPU(contagemDeCálculos: 1_000_000)
  }
   
  /// Cálculo na GPU
  ///
  /// - Parameters:
  ///   - countToCalculate contém quantos cálculos
  private func cálculoDeGPU (contagemDeCálculos : Int) {
    // Obtenha a GPU
    let gpuDispositivo = self.procurandoGPU(eImprimirInformações : false)
    // Carregar biblioteca de funções GPU
    let biblioteca = self.loadMetalLibrary(for: gpuDispositivo)
    // Faça referência à função a ser chamada e crie o commandQueue
    let callFunction = "gpuFunção"
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

          // MARK: novidades em GPUFunção (Parte 1 - dados de entrada)
          // Nossa função do kernel é declarada como:
          /*
           kernel void gpuFunction (
           constant int* input1 [[ buffer(0)]],        // dados de entrada somente leitura
           constant int* input2 [[ buffer(1)]],        // dados de entrada somente leitura
            device  int* output [[buffer(2)]],         // valor de retorno
           uint index    [[ thread_position_in_grid ]] // thread número
           )*/
          // Neste ponto, precisamos fornecer os dados de entrada. Os valores de retorno vêm depois e os números dos threads são gratuitos.
          let input1 : [Int] = criaDadosAleatórios(contagem: contagemDeCálculos) // int array input1
          let input2 : [Int] = criaDadosAleatórios(contagem: contagemDeCálculos) // int array input2
          
          let input1AsBuffer = gpuDispositivo.makeBuffer(bytes: input1, length: MemoryLayout<Int>.size * contagemDeCálculos, options: .storageModeShared)
          let input2AsBuffer = gpuDispositivo.makeBuffer(bytes: input2, length: MemoryLayout<Int>.size * contagemDeCálculos, options: .storageModeShared)
          
          let outputAsBuffer = gpuDispositivo.makeBuffer(length: MemoryLayout<Int>.size * contagemDeCálculos, options: .storageModeShared) // sabemos o número de resultados
          
          // Agora registramos o parâmetro para a função de computação
          encoder.setBuffer(input1AsBuffer, offset: 0, index: 0)
          encoder.setBuffer(input2AsBuffer, offset: 0, index: 1)
          encoder.setBuffer(outputAsBuffer, offset: 0, index: 2)
          // EOM

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
          
          // MARK: novo em GPUFunctions (Parte 2 - valores de retorno)
          // Podemos trabalhar com os valores dos resultados subindo para o nível abstrato, começando com o ponteiro bruto (raw pointer), passando pelo ponteiro específico do tipo até o tipo de array Swift.
          
          /// Variante 1 trabalhando com ``UnsafeMutableRawPointer``. Podemos obter o resultado trypesafe com ``load(as:<T>)`` . Mas para ir para o próximo elemento, precisamos calcular a contagem de bytes a serem ignorados. Por outro lado, mais de um tipo pode ser carregado no armazém.
          var rawPointer = outputAsBuffer?.contents()
          
          /// A variante 2 funciona com o tipo seguro``UnsafeMutablePoint<T>``. O valor específico é especificado via ``pointee``, um ponteiro para o elemento, mas apenas para o tipo “Any”. Em vez da variante 1, agora podemos contar confortavelmente.
          var resultBufferPointer = rawPointer!.bindMemory(to: Int.self, capacity: MemoryLayout<Int>.size * contagemDeCálculos)
          
          /// A variante 3 é fornecer nosso adorável tipo Swift ``[Int]``.
          let intBuffer = UnsafeBufferPointer (start: resultBufferPointer, count: contagemDeCálculos)
          let returnValue = Array(intBuffer)
          
          var index = 0
          for result in returnValue {
            /// Com a variante 1, precisamos calcular o tamanho para mover o ponteiro depois de obtermos o valor com ``MemoryLayout<Int>.size``.
            print ("raw pointer: \(rawPointer!.load(as: Int.self)) = \(input1[index]) + \(input2[index])")
            rawPointer = rawPointer?.advanced(by: 1 * MemoryLayout<Int>.size)
            
            /// Para a variante 2, primeiro temos que criar um tipo ``Int`` onde o ponteiro está localizado. Em vez de calcular o tamanho da memória, podemos avançar nosso ponteiro 1.
            print ("pointee    : \(Int(resultBufferPointer.pointee) as Any) = \(input1[index]) + \(input2[index])")
            resultBufferPointer = resultBufferPointer.advanced(by: 1)
            
            /// Com a variante 3, não é necessária mais aritmética de ponteiros.
            print("array      : \(result) = \(input1[index]) + \(input2[index])")
            
            print(String(repeating: "-", count: 50))
            index += 1 // necessário apenas porque os dados de entrada são impressos
          }
          // EOM
          
          
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

