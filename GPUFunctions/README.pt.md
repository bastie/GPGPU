# A função GPGPU

| [👈](../GPUWorkflow/README.pt.md) [👆](../README.pt.md) | 🫵 [🇩🇪](README.de.md) [🇺🇸](README.md) | 

---

A função GPU está escrita na [Metal Shading Language](https://developer.apple.com/metal/Metal-Shading-Language-Specification.pdf), que é baseada no padrão C++14. Um ponto elementar é o fornecimento de dados ao kernel de computação para nossa programação GPGPU.

Quase parecendo uma função C++, algumas palavras-chave são específicas do Metal. Nossa função de GPU é marcada com a palavra-chave **kernel**, tornando-a uma _função de computação_ publicamente visível que é executada em nossa GPU. O valor de retorno de uma _função computacional_ é necessariamente **void**, porque a troca com o programa _**C**PU_ de chamada ocorre através da memória compartilhada.

As informações são fornecidas aos parâmetros usando atributos de espaço de endereço. Dados imutáveis ​​(_somente leitura_) são marcados com **constante**. No entanto, os parâmetros marcados com **dispositivo** são legíveis e graváveis.

E há **thread_position_in_grid**, que neste exemplo nos fornece o índice, semelhante à variável em execução em um loop _for_.
