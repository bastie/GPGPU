# GPGPU - Computação de Propósito Geral em Unidade de Processamento Gráfico com Metal

👉 [🇩🇪](README.de.md) [🇺🇸](README.md) 
---

## Você está no lugar certo de

* seus interesses estão na computação geral em GPU, não no processamento gráfico,
* seus interesses estão na Metal API da Apple Inc,
* seus interesses estão em GPGPU em produtos Apple.

Todos os outros, obrigado pela visita, tchau 👋

## GPGPU

Para os muitos ou poucos restantes...

### The procedure for implementation

Para realizar cálculos gerais na placa gráfica, além da tarefa específica de programação, o mesmo 👉[fluxo de trabalho de programação](./GPUWorkflow/):

1. Localize o `dispositivo` (device) que representa a GPU
1. Deixe o programa conhecer a biblioteca GPU. Por padrão é o "default.metallib"
1. Crie uma referência para a função também conhecida como "kernel" que queremos usar
1. A partir do `dispositivo` crie a `fila de comando` para todos os comandos únicos
1. Com a `fila de comando` crie o buffer para os comandos de hardware
1. Os comandos concretos da API de hardware seriam traduzidos da fonte com o `command encoder` - usamos o **ComputeCommandEncoder**

## referências

### GPGPU com Metal

* 🇺🇸 Objective-C [Performing Calculations on a GPU](https://developer.apple.com/documentation/metal/performing_calculations_on_a_gpu), Apple Inc.

### Metal

* 🇺🇸 WWDC14, session 603 [Working with Metal—Overview](https://devstreaming-cdn.apple.com/videos/wwdc/2014/603xx33n8igr5n1/603/603_working_with_metal_overview.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC14, session 604 [Working with Metal—Fundamentals](https://devstreaming-cdn.apple.com/videos/wwdc/2014/604xxg7crkljcr8/604/604_working_with_metal_fundamentals.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC14, session 605 [Working With Metal—Advanced](https://devstreaming-cdn.apple.com/videos/wwdc/2014/605xxygcz4pd0h6/605/605_working_with_metal_advanced.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC16, session 606 [Advanced Metal Shader Optimization](https://devstreaming-cdn.apple.com/videos/wwdc/2016/606oluchfgwakjbymy8/606/606_advanced_metal_shader_optimization.pdf), © 2016 Apple Inc.
* 🇺🇸 WWDC20 [Debug GPU-side errors in Metal](https://developer.apple.com/videos/play/wwdc2020/10616/), © 2020 Apple Inc.
