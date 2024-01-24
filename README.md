# GPGPU - General Purpose Computation on Graphics Processing Unit with Metal

👉 [🇩🇪](README.de.md) [🇵🇹](README.pt.md)
--- 

## You´re in the right place of

* your interests are in the general computing on GPU not graphic processing,
* your interests are on Metal API from Apple Inc,
* your interests are on GPGPU on Apple products.

All others, thank for visit, bye 👋

## GPGPU

For the many or few remaining...

### The procedure for implementation

In order to carry out general calculations on the graphics card, apart from the specific programming task, the same 👉[programming workflow](./GPUWorkflow/):

1. Locate the `device` that represents the GPU
1. Let the program known the GPU library. By default it is the "default.metallib"
1. Create a reference to function aka "kernel" we want to use
1. From the `device` create the `command queue` for all single command
1. With the `command queue` create the buffer for the hardware-commands
1. The concrete hardware API commands would be translated from source with the `command encoder` - we use the **ComputeCommandEncoder**

## references

### GPGPU mit Metal

* 🇺🇸 Objectiv-C [Performing Calculations on a GPU](https://developer.apple.com/documentation/metal/performing_calculations_on_a_gpu), Apple Inc.

### Metal

* 🇺🇸 WWDC14, session 603 [Working with Metal—Overview](https://devstreaming-cdn.apple.com/videos/wwdc/2014/603xx33n8igr5n1/603/603_working_with_metal_overview.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC14, session 604 [Working with Metal—Fundamentals](https://devstreaming-cdn.apple.com/videos/wwdc/2014/604xxg7crkljcr8/604/604_working_with_metal_fundamentals.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC14, session 605 [Working With Metal—Advanced](https://devstreaming-cdn.apple.com/videos/wwdc/2014/605xxygcz4pd0h6/605/605_working_with_metal_advanced.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC16, session 606 [Advanced Metal Shader Optimization](https://devstreaming-cdn.apple.com/videos/wwdc/2016/606oluchfgwakjbymy8/606/606_advanced_metal_shader_optimization.pdf), © 2016 Apple Inc.
* 🇺🇸 WWDC20 [Debug GPU-side errors in Metal](https://developer.apple.com/videos/play/wwdc2020/10616/), © 2020 Apple Inc.
