# Die GPGPU Funktion

|  [👈](../GPUWorkflow/README.de.md) [👆](../README.de.md) | 🫵 [🇺🇸](README.md) [🇵🇹](README.pt.md) |

---

Die GPU Funktion wird in der [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf) welche auf dem C++14 Standard basiert geschrieben. Ein elementarer Punkt ist die Datenbereitstellung an den _compute kernel_ für unsere GPGPU Programmierung.

Fast wie eine C++ Funktion aussehend sind einige Schlüsselwörter Metal spezifisch. Unsere GPUFunktion wird mit dem Schlüsselwort **kernel** ausgezeichnet und ist damit eine öffentlich sichtbare _compute function_ die auf unserer GPU ausgeführt wird. Der Rückgabewert eine _compute function_ ist zwingend **void**, denn der Austausch mit dem aufrufenden _**C**PU_ Programm erfolgt über den gemeinsam genutzten Speicher.  

Den Parametern werden mit Adressraumattributen Informationen mitgegeben. Unveränderliche (_read-only_) Daten werden mit **constant** gekennzeichnet. Mit **device** gekennzeichnete Parameter sind hingegen sowohl lesbar als auch beschreibbar.

Und dann gibt es hier noch **thread_position_in_grid**, welche in diesem Beispiel vergleichbar mit der Laufvariablen in einer _for_-Schleife uns den index wiedergibt.
