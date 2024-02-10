/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib>
using namespace metal;

/// Die Beispiel GPU Funktion für den Arbeitsablauf
kernel void gpuFunktion (constant int* eingabe1 [[ buffer(0)]],   // Eingabedaten unveränderlich
                         constant int* eingabe2 [[ buffer(1)]],   // Eingabedaten unveränderlich
                           device int* ausgabe [[buffer(2)]],     // Ausgabedaten
                         uint index [[ thread_position_in_grid ]] // Threadnummer
                         ){
  ausgabe[index] = eingabe1[index] + eingabe2[index];
}

