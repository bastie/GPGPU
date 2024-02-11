/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

import Foundation
import Metal

//@main
/// The GPU Workflow.
///
/// The GPU Workflow containts the following steps
/// 1. Locate the `device` that represents the GPU
/// 1. Let the program known the GPU library. By default it is the "default.metallib"
/// 1. Create a reference to function aka "kernel" we want to use
/// 1. From the `device` create the `command queue` for all single command
/// 1. With the `command queue` create the buffer for the hardware-commands
/// 1. The concrete hardware API commands would be translated from source with the `command encoder` - we use the **ComputeCommandEncoder**
///
/// | Metal Objects | Task |
/// | --- | --- |
/// | `device` | connection to the GPU |
/// | `command queue` | task management for `command buffer` |
/// | `command buffer` | Buffer GPU hardware commands |
/// | `command encoder` | Translator for hardware GPU API calls, here the `compute command encoder` |
/// | `state` | Configuration |
/// | `code` | `shader` |
/// | `resources` | data, textures and more |
struct GPUWorkflow {
  
  /// Start the application
  ///
  /// The *``main()`` entry point* is called by start our application and can be declared by a file named `main.swift` or with a annotated  *struct*. The annotation called `@main` need the  `static func main(){}`.
  ///
  /// - Warning: More than one *``main()`` entry points* creates compiler error.
  ///
  public static func main () {
    let workflow = GPUWorkflow()
    workflow.gpuCalculation(countToCalculate: 1_000_000)
  }

  /// Calculation on GPU
  ///
  /// - Parameters:
  ///   - countToCalculate contains how many calulation
  private func gpuCalculation (countToCalculate : Int) {
    // Get the GPU
    let gpuDevice = self.lookingForGPU(andPrintInfo : false)
    // Load GPU function library
    let library = self.loadMetalLibrary(for: gpuDevice)
    // create the reference to the function to be called and alse create the command queue
    let callFunction = "gpuFunktion"
    if let kernel = library.makeFunction(name: callFunction), let commandQueue = gpuDevice.makeCommandQueue() {
      
      /// With using of descriptor error search in Metal code is easier, WWDC 20, Debug GPU-side errors in Metal
      let descriptor = MTLCommandBufferDescriptor()
      descriptor.errorOptions = .encoderExecutionStatus
      if let commandBuffer = commandQueue.makeCommandBuffer(descriptor: descriptor) {
        // Also the CommandBuffer can be used for error handling like this, Debug GPU-side errors in Metal
        commandBuffer.addCompletedHandler { (commandBuffer) in
          for log in commandBuffer.logs {
            let encoderLabel = log.encoderLabel ?? "missing label"
            print ("Fault encoder Name \(encoderLabel)")
            guard let location = log.debugLocation, let functionName = log.function?.name else {
              return
            }
            print ("error postion \(functionName):\(location.line):\(location.column)")
          }
        }
        // Now finally comes the ComputeCommandEncoder
        if let encoder = commandBuffer.makeComputeCommandEncoder() {
          let status = try! gpuDevice.makeComputePipelineState(function: kernel)
          encoder.setComputePipelineState(status)
          
          // MARK: new in GPUFunctions (Part 1 - input data)
          // Our kernel function is declared as:
          /*
           kernel void gpuFunction (
           constant int* input1 [[ buffer(0)]],        // read-only input data
           constant int* input2 [[ buffer(1)]],        // read-only input data
            device  int* output [[buffer(2)]],         // return value
           uint index    [[ thread_position_in_grid ]] // threadnumber
           )*/
          // At this point we need to provide the input data. The return values comes later and the threadnumbers are for free.
          let input1 : [Int] = createRandomData(count: countToCalculate) // int array input1
          let input2 : [Int] = createRandomData(count: countToCalculate) // int array input2
          
          let input1AsBuffer = gpuDevice.makeBuffer(bytes: input1, length: MemoryLayout<Int>.size * countToCalculate, options: .storageModeShared)
          let input2AsBuffer = gpuDevice.makeBuffer(bytes: input2, length: MemoryLayout<Int>.size * countToCalculate, options: .storageModeShared)
          
          let outputAsBuffer = gpuDevice.makeBuffer(length: MemoryLayout<Int>.size * countToCalculate, options: .storageModeShared) // We know the number of results
          
          // Now we register the parameter for the computation function
          encoder.setBuffer(input1AsBuffer, offset: 0, index: 0)
          encoder.setBuffer(input2AsBuffer, offset: 0, index: 1)
          encoder.setBuffer(outputAsBuffer, offset: 0, index: 2)
          // EOM

          // We have to call the count of our working. Maximum is the count of threads our GPU and also limited by maximum threads per threadgroup. For example: In result of maximum of 1024 this could be 2*8*64 or 1024*1*1
          let width = status.maxTotalThreadsPerThreadgroup
          let threadsPerGrid : MTLSize = MTLSizeMake(width,1, 1)
          let threadsPerThreadgroup = MTLSizeMake(width, 1, 1)
          encoder.dispatchThreadgroups(threadsPerGrid, threadsPerThreadgroup: threadsPerThreadgroup)
          
          // Before it runs we call at first that no more commands we have with (``endEncoding``). Later start the computing with (``commit``)
          encoder.endEncoding()
          commandBuffer.commit()
          // We want to wait until the end of computing
          commandBuffer.waitUntilCompleted()
          
          // MARK: new in GPUFunctions (Part 2 - return values)
          // We can work with the result values moving up to the abstract level, starting with the raw pointer through the type-specific pointer to the Swift array type.
          
          /// Variant 1 working with ``UnsafeMutableRawPointer``. We can get the result trypesafe with ``load(as:<T>)`` . But to go to next element we need self to calculate the byte count to skip. On the other hand move than one type can loaded from the storage.
          var rawPointer = outputAsBuffer?.contents()
          
          /// Variant 2 working with typesafe ``UnsafeMutablePoint<T>`` . The concrete value are over ``pointee`` provided, a pointer on the element but only in type ``Any``. Instead of variant 1 we can count up comfortably.
          var resultBufferPointer = rawPointer!.bindMemory(to: Int.self, capacity: MemoryLayout<Int>.size * countToCalculate)
          
          /// Variant 3 is to provide our lovely Swift typ ``[Int]``.
          let intBuffer = UnsafeBufferPointer (start: resultBufferPointer, count: countToCalculate)
          let returnValue = Array(intBuffer)
          
          var index = 0
          for result in returnValue {
            /// With variant 1 we need to calculate the size to move the pointer after we get the value with ``MemoryLayout<Int>.size``.
            print ("raw pointer: \(rawPointer!.load(as: Int.self)) = \(input1[index]) + \(input2[index])")
            rawPointer = rawPointer?.advanced(by: 1 * MemoryLayout<Int>.size)
            
            /// With variant 2 first we need to create an ``Int`` type where the pointer is located. Instead of calculate the memory size we can our pointer move advanced by 1.
            print ("pointee    : \(Int(resultBufferPointer.pointee) as Any) = \(input1[index]) + \(input2[index])")
            resultBufferPointer = resultBufferPointer.advanced(by: 1)
            
            /// With variant 3 no more pointer arithmetic is needed.
            print("array      : \(result) = \(input1[index]) + \(input2[index])")
            
            print(String(repeating: "-", count: 50))
            index += 1 // only needed in result of input data is printed
          }
          // EOM
          
          // some error handling, WWDC 20, Debug GPU-side errors in Metal
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
        print ("Library\n================================")
        print ("Name: \(library.installName ?? "default.metallib")")
        print ("Functions: \(library.functionNames)")
        print()
      }
      return library
    }
    else {
      fatalError("Library not found")
    }
  }
  
  private func lookingForGPU (andPrintInfo printInfo : Bool = true) -> MTLDevice {
    // in interactive context we can use MTLCreateSystemDefaultDevice, here we need an MTLCopyAllDevices variant
    let allDevices = MTLCopyAllDevices() // we do not react to changes with observer
    
    // It doesn't work without a GPU
    guard !allDevices.isEmpty else {
      fatalError("No GPU found.")
    }
    
    var device = allDevices [0]
    // In this example, the permanently installed GPU should be used if possible
    if device.isRemovable {
      for next in allDevices {
        if device.isRemovable && !next.isRemovable {
          device = next
        }
      }
    }
    
    // we provide some information about the GPU used if desired
    if printInfo {
      let formatter = NumberFormatter()
      formatter.numberStyle = .decimal
      formatter.locale = Locale.current
      
      print ("GPU Name: \(device.name)")
      print ("RAM using together with CPU: \(device.hasUnifiedMemory)")
      print ("Monitor found: \(!device.isHeadless)")
      print ("GPU removable (eGPU): \(device.isRemovable)")
      print ("Low power mode: \(device.isLowPower)")
      print ("RAM size without performance problems: \(String(describing: formatter.string(for: device.recommendedMaxWorkingSetSize)!)) bytes")
      print ("Maximum thread per group: \(device.maxThreadsPerThreadgroup)")
      print()
    }
    
    return device
  }
}

