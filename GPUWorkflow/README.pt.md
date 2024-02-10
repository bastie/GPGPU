# O fluxo de trabalho da GPU

| [👆](../README.pt.md) | 🫵 [🇩🇪](README.de.md) [🇺🇸](README.md) | 

---

O fluxo de tarbalho da GPU contém as seguintes etapas
1. Localize o `dispositivo` (device) que representa a GPU
1. Deixe o programa conhecer a biblioteca GPU. Por padrão é o "default.metallib"
1. Crie uma referência para a função também conhecida como "kernel" que queremos usar
1. A partir do `dispositivo` crie a `fila de comando` para todos os comandos únicos
1. Com a `fila de comando` crie o buffer para os comandos de hardware
1. Os comandos concretos da API de hardware seriam traduzidos da fonte com o `command encoder` - usamos o **ComputeCommandEncoder**

Também temos que fornecer uma função Metal (“kernel”) que implementamos.

| objetos de Metal | tarefas |
| --- | --- |
| `device` | conexão com a GPU |
| `command queue` | gerenciamento de tarefas para `command buffer` |
| `command buffer` | Comandos de hardware da GPU de buffer |
| `command encoder` | Tradutor para chamadas de API de GPU de hardware, aqui o `compute command encoder` |
| `state` | configuração |
| `code` | `shader` |
| `resources` | dados, texturas e mais|
