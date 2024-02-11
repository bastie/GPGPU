/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib> // in diesem Beispiel nicht zwingend
using namespace metal;  // in diesem Beispiel nicht zwingend

/** Die Beispiel GPU Funktion für den Arbeitsablauf
 *
 * Diese Funktion wird mit der Angabe von ``kernel`` als _compute function_ deklariert, welche somit sichtbar und aufrufbar ist.
 * Mit der Angabe von ``constant`` werden zwei Parameter als unveränderlich (_read-only_) ausgewiesen.
 * Auf den Parameter der mit ``device`` ausgezeichnet ist, kann sowohl lesend als auch schreiben zugegriffen werden.
 * Mit dem Parameter ``index`` wird über ``thread_position_in_grid`` der Array-Index, in etwa vergleichbar mit der Laufvariable in einer ``for``-Schleife definiert.
 *
 * Eine _compute function_ hat keinen Rückgabewert. Rückgaben erfolgen stets über den gemeinsam genutzten Speicher.
 */
kernel void gpuFunktion (constant int* eingabe1 [[ buffer(0)]],   // Eingabedaten unveränderlich
                         constant int* eingabe2 [[ buffer(1)]],   // Eingabedaten unveränderlich
                           device int* ausgabe  [[buffer(2)]],    // Ausgabedaten
                         uint index [[ thread_position_in_grid ]] // Threadnummer
                         ){
  ausgabe[index] = eingabe1[index] + eingabe2[index];
}

