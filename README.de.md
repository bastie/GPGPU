# GPGPU - Allgemeine Berechnungen auf der Grafikkarte mit Metal

👉 [🇺🇸](README.md) [🇵🇹](README.pt.md)
---

GPGPU (🇺🇸 General Purpose Computation on Graphics Processing Unit)  

## Du bist am richtigen Ort, wenn

* dein Interesse die allgemeinen Berechnungen auf der GPU betrifft, nicht jedoch Grafikprogrammierung,
* dein Interesse der Metal API von Apple Inc gilt,
* dein Interesse die GPGPU auf Apple Produkten beinhaltet.

Allen Anderen sei Dank für den Besuch gesagt und Tschüss 👋

## GPGPU

Für die vielen oder wenigen Verbliebenen...

### Das Vorgehen zur Umsetzung

Um allgemeine Berechnungen auf der Grafikkarte durchzuführen ist von der konkreten Programmieraufgabe abgesehen grds. stets der gleicher 👉[Arbeitsablauf zu programmieren](./GPUWorkflow/):

1. Das `device`, sprich die GPU ermitteln
1. Die GPU Bibliothek bekannt machen, standardmäßig ist dies die "default.metallib"
1. Die zu verwendene Funktion "kernel" referenzieren
1. Mit dem `device` die Aufgabenverwaltung `command queue` für die Anweisungen bereitstellen
1. Mit der `command queue` den Puffer für die Hardwareanweisungen zur Verfügung stellen
1. Die Hardwareanweisungen mit dem `command encoder` in die konkreten API Aufrufe übersetzen - für uns natürlich der **ComputeCommandEncoder**


## Quellen

### GPGPU mit Metal

* 🇺🇸 Objective-C [Performing Calculations on a GPU](https://developer.apple.com/documentation/metal/performing_calculations_on_a_gpu), Apple Inc.

### Metal

* 🇺🇸 WWDC14, session 603 [Working with Metal—Overview](https://devstreaming-cdn.apple.com/videos/wwdc/2014/603xx33n8igr5n1/603/603_working_with_metal_overview.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC14, session 604 [Working with Metal—Fundamentals](https://devstreaming-cdn.apple.com/videos/wwdc/2014/604xxg7crkljcr8/604/604_working_with_metal_fundamentals.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC14, session 605 [Working With Metal—Advanced](https://devstreaming-cdn.apple.com/videos/wwdc/2014/605xxygcz4pd0h6/605/605_working_with_metal_advanced.pdf), © 2014 Apple Inc.
* 🇺🇸 WWDC16, session 606 [Advanced Metal Shader Optimization](https://devstreaming-cdn.apple.com/videos/wwdc/2016/606oluchfgwakjbymy8/606/606_advanced_metal_shader_optimization.pdf), © 2016 Apple Inc.
* 🇺🇸 WWDC20 [Debug GPU-side errors in Metal](https://developer.apple.com/videos/play/wwdc2020/10616/), © 2020 Apple Inc.
