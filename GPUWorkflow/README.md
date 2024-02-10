# The GPU Workflow

| [👆](../README.md) | 🫵 [🇩🇪](README.de.md) [🇵🇹](README.pt.md) |
---

The GPU Workflow containts the following steps
1. Locate the `device` that represents the GPU
1. Let the program known the GPU library. By default it is the "default.metallib"
1. Create a reference to function aka "kernel" we want to use
1. From the `device` create the `command queue` for all single command
1. With the `command queue` create the buffer for the hardware-commands
1. The concrete hardware API commands would be translated from source with the `command encoder` - we use the **ComputeCommandEncoder**

We also have to provide a metal function (“kernel”) that we implement.

| Metal Objects | Task |
| --- | --- |
| `device` | connection to the GPU |
| `command queue` | task management for `command buffer` |
| `command buffer` | Buffer GPU hardware commands |
| `command encoder` | Translator for hardware GPU API calls, here the `compute command encoder` |
| `state` | Configuration |
| `code` | `shader` |
| `resources` | data, textures and more |
