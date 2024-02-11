# The GPGPU Function

|  [👈](../GPUWorkflow/README.md) [👆](../README.md) | 🫵 [🇺🇸](README.md) [🇵🇹](README.pt.md) |

---

The GPU function is written in the [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf) which is based on the C++14 standard. An elementary point is the data provision to the _compute kernel_ for our GPGPU programming.

Almost looking like a C++ function, some keywords are Metal specific. Our GPU function is tagged with the **kernel** keyword, making the _compute function_ public visible that runs on our GPU. The return value of a _compute function_ is necessarily **void**, because the exchange with the calling _**C**PU_ program takes place via the shared memory.

Information is given to the parameters using address space attributes. Immutable (_read-only_) data is marked with **constant**. However, parameters marked with **device** are both readable and writable.

And then there is **thread_position_in_grid**, which in this example gives us the index, similar to the running variable in a _for_ loop.
