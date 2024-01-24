/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib>
using namespace metal;

/// The sample GPU worklfow function
kernel void gpuFunction (){}

/// called ``uint8_t`` struct as ``UInt8`` to be a little more as Swift
typedef uint8_t UInt8;

kernel void otherGPUFunction (device UInt8* input1 [[ buffer(0) ]],
                              device UInt8* input2 [[ buffer(1) ]],
                              device UInt8* input3 [[ buffer(2) ]],
                              device int* output [[ buffer(3) ]],
                              uint index [[ thread_position_in_grid ]]) {}
