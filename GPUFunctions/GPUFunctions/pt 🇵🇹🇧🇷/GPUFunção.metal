/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib> // não é necessário neste exemplo
using namespace metal;  // não é necessário neste exemplo

/** a função de fluxo de trabalho de GPU de exemplo
 *
 * Esta função é marcada com ``kernel`` para declará-la como _função computacional_ e torná-la visível e chamável.
 * A ``constant`` definiu dois parâmetros somente leitura.
 * Por outro lado ``device`` torna o parâmetro legível e gravável.
 * O parâmetro ``index`` é marcado com ``thread_position_in_grid``. É um pouco como a variável de índice do loop for.
 *
 * Todas as _funções computacionais_ retornam ``void``. Os valores de retorno são armazenados na memória compartilhada.
 */
kernel void gpuFunção (constant int* input1 [[ buffer(0)]],     // dados de entrada somente leitura
                         constant int* input2 [[ buffer(1)]],     // dados de entrada somente leitura
                         device int* output   [[buffer(2)]],      // valor de retorno
                         uint index [[ thread_position_in_grid ]] // thread número
                         ){
  output[index] = input1[index] + input2[index];
}

