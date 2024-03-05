/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib> // in diesem Beispiel nicht zwingend
using namespace metal;  // in diesem Beispiel nicht zwingend



typedef struct {
  uint8_t uintArray[3];
} ThreeBytes;

typedef struct {
  uint8_t first : 8;
  uint8_t second : 8;
  uint8_t third : 8;
  uint8_t fourth : 8;
} FourBytes;

constant uint8_t base64Table[] = {
  'A','B','C','D','E','F','G','H','I','J','K','L','M','N','O','P','Q','R','S','T','U','V','W','X', 'Y','Z',
  'a','b','c','d','e','f','g','h','i','j','k','l','m','n','o','p','q','r','s','t','u','v','w','x','y','z',
  '0','1','2','3','4','5','6','7','8','9',
  '+','/'
};



kernel void base64 (constant ThreeBytes* eingabe [[buffer(0)]],   // Eingabedaten unveränderlich
                    device FourBytes* ausgabe  [[buffer(1)]], // Ausgabedaten
                    uint index [[ thread_position_in_grid ]] // Threadnummer
                   ){
  ausgabe[index].first = base64Table[eingabe[index].uintArray[0]>>2];
  ausgabe[index].second = base64Table[((eingabe[index].uintArray[0] & 0x03) << 4) | ((eingabe[index].uintArray[1] & 0xF0) >> 4)];
  ausgabe[index].third = base64Table[((eingabe[index].uintArray[1] & 0x0F) << 2) | ((eingabe[index].uintArray[2] & 0xC0) >> 6)];
  ausgabe[index].fourth = base64Table[eingabe[index].uintArray[2] & 0x3F];

}

