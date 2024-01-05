//
//  GPUFunktion.metal
//  GPUWorkflow
//
//  Created by Sebastian Ritter on 02.01.24.
//

#include <metal_stdlib>
using namespace metal;

/// Die Beispiel GPU Funktion für den Arbeitsablauf
kernel void gpuFunktion (){}

/// um ein bisschen mehr wie in Swift zu arbeiten, bezeichnen wir das ``uint8_t`` struct als ``UInt8``
typedef uint8_t UInt8;


kernel void weitereGPUFunktion (device UInt8* input1 [[ buffer(0) ]],
                                device UInt8* input2 [[ buffer(1) ]],
                                device UInt8* input3 [[ buffer(2) ]],
                                device int* output [[ buffer(3) ]],
                                uint index [[ thread_position_in_grid ]]) {}
