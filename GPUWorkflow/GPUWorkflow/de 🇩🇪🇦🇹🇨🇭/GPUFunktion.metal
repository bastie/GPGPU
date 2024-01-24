/*
 * SPDX-FileCopyrightText: 2023 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib>
using namespace metal;

/// Die Beispiel GPU Funktion für den Arbeitsablauf
kernel void gpuFunktion (){}

/// um ein bisschen mehr wie in Swift zu arbeiten, bezeichnen wir das ``uint8_t`` struct als ``UInt8``
typedef uint8_t UInt8;

kernel void weitereGPUFunktion (device UInt8* eingabe1 [[ buffer(0) ]],
                                device UInt8* eingabe2 [[ buffer(1) ]],
                                device UInt8* eingabe3 [[ buffer(2) ]],
                                device int* ausgabe [[ buffer(3) ]],
                                uint index [[ thread_position_in_grid ]]) {}
