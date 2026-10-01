# Resultados do Falco - 23/08/2026

## Metodo

Foram executados 20 eventos controlados no pod `juice-shop-86d6899c64-krcrk`
do namespace `devsecops-lab`: 10 execucoes de processo Node.js (C5) e 10
leituras de `/etc/passwd` (C6). Cada evento recebeu um marcador unico no
comando, permitindo correlacionar o disparo local com o campo `time` do alerta
Falco. Os dados individuais estao em `falco-resultados.csv`.

A latencia representa o intervalo entre o instante imediatamente anterior ao
`kubectl exec` e o timestamp do alerta. Portanto, e uma estimativa de ponta a
ponta do caminho de deteccao no laboratorio, nao apenas do motor Falco.

## Resultados

| Cenario | N | Regra esperada | Alertas correlacionados | Cobertura | Latencia mediana | Minimo | Maximo |
|---|---:|---|---:|---:|---:|---:|---:|
| C5 - execucao | 10 | `Exec into Juice Shop` | 10 | 100% | 196,103 ms | 185,945 ms | 260,804 ms |
| C6 - leitura | 10 | `Read sensitive file in Juice Shop` | 10 | 100% | 270,139 ms | 227,750 ms | 340,350 ms |

## Ruido e entrega visual

Na janela de oito segundos do experimento, o Falco emitiu 30 alertas associados
ao Juice Shop: 10 execucoes de C5, 10 execucoes produzidas pelo comando de C6 e
10 leituras de arquivo de C6. Os dez alertas de execucao gerados durante C6 sao
esperados, pois a leitura e feita por um novo processo Node.js; eles nao foram
contados como alertas da regra de leitura.

Dois alertas `Run shell untrusted` foram classificados como ruido externo: eles
nao possuiam pod ou namespace Kubernetes e correspondiam ao processo de
orquestracao do laboratorio no host. Eles nao foram incluidos nas metricas C5 e
C6. Essa separacao por `k8s.pod.name` e `k8s.ns.name` evita atribuir ao Juice
Shop eventos que pertencem ao host.

O Falcosidekick registrou `WebUI - POST OK (200)` para os eventos do periodo,
confirmando encaminhamento para a interface. Na rajada inicial tambem houve dois
registros de rate limit (`500`), o que limita a conclusao sobre entrega visual
de cada evento sob alta frequencia. A cobertura reportada neste documento e a
do Falco, medida pelos logs do agente; ela nao deve ser confundida com garantia
de entrega de 100% pela interface web.

## Limites de interpretacao

Os resultados demonstram a cobertura das duas regras customizadas para estes
eventos e ambiente. Eles nao medem a deteccao de toda execucao maliciosa nem de
toda leitura sensivel. A amostra e pequena, em no unico e executada de forma
sequencial. Para a demonstracao da banca, os eventos devem ser disparados com
pequeno intervalo ou filtrados na Falcosidekick UI para reduzir ruido visual.
