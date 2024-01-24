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
/// |  Metal Objects | Task |
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
    
    // Get the GPU
    let gpuDevice = workflow.lookingForGPU(andPrintInfo : false)
    // Load GPU function library
    let library = workflow.loadMetalLibrary(for: gpuDevice)
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
          // In other scenario at this position data is prepared. In this example we need no data
          
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

