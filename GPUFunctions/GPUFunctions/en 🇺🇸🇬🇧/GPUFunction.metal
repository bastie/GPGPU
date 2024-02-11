/*
 * SPDX-FileCopyrightText: 2024 - Sebastian Ritter <bastie@users.noreply.github.com>
 * SPDX-License-Identifier: MIT
 */

#include <metal_stdlib> // not required in this example
using namespace metal;  // not required in this example

/** The sample GPU function for the workflow.
 *
 * This function is marked with ``kernel`` to declare these as _compute function_ and make it visible and callable.
 * The ``constant`` defined two read-only parameter.
 * On the otherside ``device`` make the parameter readable and writeable.
 * The ``index`` parameter is marked with ``thread_position_in_grid``. It is a littlebit like the for-loop index variable.
 *
 * All _compute function_ returns ``void``. Return values are stored in the shared memory.
 */
kernel void gpuFunction (constant int* input1 [[ buffer(0)]],     // read-only input data
                         constant int* input2 [[ buffer(1)]],     // read.only input data
                         device int* output   [[buffer(2)]],      // return value
                         uint index [[ thread_position_in_grid ]] // threadnumber
                         ){
  output[index] = input1[index] + input2[index];
}

