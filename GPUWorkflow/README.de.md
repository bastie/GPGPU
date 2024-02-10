# Der GPU Arbeitsablauf

| [👆](../README.de.md) | 🫵 [🇺🇸](README.md) [🇵🇹](README.pt.md) |
---

Der GPU Arbeitsablauf gestaltet sich zunächst durch die Schrite
1. Das `device`, sprich die GPU ermitteln
1. Die GPU Bibliothek bekannt machen, standardmäßig ist dies die "default.metallib"
1. Die zu verwendene Funktion "kernel" referenzieren
1. Mit dem `device` die Aufgabenverwaltung `command queue` für die Anweisungen bereitstellen
1. Mit der `command queue` den Puffer für die Hardwareanweisungen zur Verfügung stellen
1. Die Hardwareanweisungen mit dem `command encoder` in die konkreten API Aufrufe übersetzen - für uns natürlich der **ComputeCommandEncoder**

Weiterhin müssen wir eine Metal Funktion bereitstellen ("kernel") die wir implementieren.

| Metal Objekte | Aufgabe |
| --- | --- |
| `device` | Zugriff auf die GPU |
| `command queue` | Aufgabenverwaltung von `command buffer` Anweisungen |
| `command buffer` | Puffer GPU Hardwareanweisungen |
| `command encoder` | Übersetzung der API Aufrufe in die GPU Hardwareanweisungen, speziell der `compute command encoder` |
| `state` | Konfiguration |
| `code` | Die `shader` |
| `resources` | Datenpuffer, Texturen etc. |
