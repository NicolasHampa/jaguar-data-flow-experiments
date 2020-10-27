# jaguar-data-flow-experiments

## Informações gerais.
Repositório com cobertura de data flow das ferramentas Jaguar e Ba-Dua gerados para programas do Dataset do Defects4J

#### Organização dos diretórios.
  - **dataset**: Diretório com o conjunto de informações de critério data-flow dos programas do dataset do Defects4J. Os dados foram gerados à partir da execução das ferramentas Jaguar e Ba-Dua:      
  - **scripts**: Diretório com os scripts de comparação executados em cima do conjunto de dados presente no dataset. O objetivo dos scripts consiste em validar a consistência dos dados coletados à partir da execução das ferramentas citadas acima.
  - **reports**: Arquivos com resultados obtidos à partir da execução dos scripts de comparação.
  
#### Pré-requisitos para execução dos scripts.
  ```
  Java 1.8
  Python3
  Numpy
  Git >= 1.9
  SVN >= 1.8
  Perl >= 5.0.12
  Defects4J >= 2.0.0
  ```

#### Repositórios base.
  - https://github.com/rjust/defects4j
  - https://github.com/saeg/jaguar
  - https://github.com/saeg/ba-dua
