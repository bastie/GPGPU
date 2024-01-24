/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib>
using namespace metal;

/// a função de fluxo de trabalho de GPU de exemplo
kernel void gpuFunçao (){}

/// nomeie a estrutura ``uint8_t`` como ``UInt8`` para ser um pouco mais parecida com o Swift
typedef uint8_t UInt8;

kernel void otherGPUFunçao (device UInt8* input1 [[ buffer(0) ]],
                            device UInt8* input2 [[ buffer(1) ]],
                            device UInt8* input3 [[ buffer(2) ]],
                            device int* output [[ buffer(3) ]],
                            uint index [[ thread_position_in_grid ]]) {}
