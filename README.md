# Relatório do Script `ac.sh`

**Disciplina:** Sistemas Operacionais (IBM8940) — Turma 8001
**Professor:** Luiz Fernando T. de Farias
**Semestre:** 2 de 2026
**Integrantes:** Diego Bonani, João Pedro Lima

---

## 1. Visão geral

O `ac.sh` é um script Bash que exibe uma tela inicial padronizada (cabeçalho com dados da disciplina, equipe, data e hora do sistema) e um menu interativo com 4 funcionalidades mais a opção de finalizar, totalizando 5 opções. O menu roda em loop e **a única forma de encerrar o programa é pela opção 5**.

O script não usa `sudo` nem instala pacotes: roda apenas com comandos já presentes em uma instalação padrão do Linux, sem pedir senha de administrador.

Como executar:

```bash
chmod +x ac.sh
./ac.sh
```

### Estrutura do código

| Bloco | Função no script |
|---|---|
| Configuração | Variáveis `LARG` (largura da moldura) e array `ALUNOS` |
| Funções de desenho | `repete`, `borda`, `separador`, `linha` |
| Tela inicial | `tela_inicial` (cabeçalho + menu) |
| Opções do menu | `pausa` e `opcao1` a `opcao4` |
| Loop principal | `while true` + `case` |

### Resumo das opções

| Opção | Funcionalidade | Principais comandos |
|---|---|---|
| 1 | Informações do sistema | `whoami`, `hostname`, `uname`, `uptime`, `grep`, `nproc`, `free` |
| 2 | Processos que mais consomem memória e CPU | `ps`, `head` |
| 3 | Estado dos processos | `ps`, `awk`, `wc`, `paste`, `nproc` |
| 4 | Testar conectividade de rede | `ping` |
| 5 | Finalizar o programa | `exit` |

---

## 2. Tela inicial

### 2.1 Desenho da moldura

A moldura de `#` é desenhada por quatro funções auxiliares:

- **`repete caractere N`**: imprime um caractere N vezes, usando um laço `for ((i = 0; i < n; i++))`. É a base das demais funções.
- **`borda`**: linha de `#` com a largura definida em `LARG` (66).
- **`separador`**: linha no formato `#-----...-----#`.
- **`linha "esquerda" "direita"`**: imprime uma linha de conteúdo com o texto à esquerda e, opcionalmente, outro à direita (como "Semestre 2 de 2026"). Calcula o espaço entre os dois textos e fecha com `#`.

Detalhe técnico: o comprimento dos textos é medido com `${#variavel}`, que conta **caracteres** e não bytes. Isso mantém o alinhamento correto com acentos (como em "Código" e "Opção"), o que não aconteceria com a largura do `printf` (`%-20s`), que conta bytes.

### 2.2 Data e hora do sistema

```bash
dia=$(date +%d)
mes=$(LC_TIME=pt_BR.UTF-8 date +%B)
ano=$(date +%Y)
hora=$(date +%H)
min=$(date +%M)
```

- `date +FORMATO` exibe a data/hora atual no formato pedido: `%d` dia, `%B` nome do mês por extenso, `%Y` ano com 4 dígitos, `%H` hora (00–23) e `%M` minutos.
- `$(...)` é a *substituição de comando*: guarda a saída do comando na variável.
- `LC_TIME=pt_BR.UTF-8` faz o `date` escrever o mês em português. **Atenção:** isso exige que o locale `pt_BR.UTF-8` esteja instalado. Pode ser conferido com `locale -a | grep pt_BR`. Sem ele, o mês sai em inglês.

O semestre e o ano do canto superior direito ("Semestre 2 de 2026") são **fixos** no código, identificando a turma e a entrega do trabalho. Apenas a data e a hora são dinâmicas.

### 2.3 Outros comandos da tela

- `clear`: limpa o terminal antes de redesenhar a tela.
- `for aluno in "${ALUNOS[@]}"`: percorre o array com os nomes da equipe, permitindo qualquer número de alunos.
- `printf 'Selecione uma opção: '`: imprime o prompt **sem** quebra de linha, deixando o cursor ao lado do texto.

---

## 3. Funcionalidades

### Opção 1 — Informações do sistema

Mostra um resumo da máquina.

| Informação | Comando |
|---|---|
| Usuário | `whoami` |
| Host | `hostname` |
| Kernel | `uname -sr` |
| Uptime | `uptime -p` |
| Modelo da CPU | `grep -m1 'model name' /proc/cpuinfo \| cut -d: -f2 \| sed 's/^ //'` |
| Núcleos | `nproc` |
| Memória (MB) | `free -m \| awk '/Mem:/ {print $3 " usados de " $2}'` |

Explicação dos comandos:

- `whoami`: nome do usuário que está executando o script.
- `uname -sr`: `-s` nome do kernel (Linux) e `-r` versão.
- `uptime -p`: tempo ligado em formato legível ("up 2 hours, 5 minutes").
- `grep -m1 'model name' /proc/cpuinfo`: procura a primeira linha (`-m1`) com o modelo da CPU. O arquivo `/proc/cpuinfo` é uma interface do kernel com informações do processador.
- `cut -d: -f2`: separa a linha no caractere `:` (`-d`) e pega o 2º campo (`-f2`).
- `sed 's/^ //'`: remove o espaço que sobra no início do texto.
- `nproc`: quantidade de núcleos/processadores lógicos disponíveis.
- `free -m`: memória em megabytes. O `awk` seleciona a linha `Mem:` e imprime a coluna 3 (usada) e a 2 (total).

### Opção 2 — Processos que mais consomem memória e CPU

Exibe duas tabelas, cada uma com o top 5.

```bash
ps -eo pid,user,%mem,%cpu,comm --sort=-%mem 2>/dev/null | head -n 6
ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu 2>/dev/null | head -n 6
```

- `ps`: lista processos.
- `-e`: todos os processos do sistema.
- `-o pid,user,%mem,%cpu,comm`: escolhe as colunas (PID, dono, % de memória, % de CPU, nome do comando).
- `--sort=-%mem` / `--sort=-%cpu`: ordena pela coluna indicada; o `-` inverte para ordem **decrescente**.
- `2>/dev/null`: descarta mensagens de erro (canal 2, `stderr`).
- `| head -n 6`: o pipe passa a saída ao `head`, que mantém as 6 primeiras linhas (1 de cabeçalho + 5 processos).

Em cada tabela, a coluna usada para ordenar aparece primeiro.

### Opção 3 — Estado dos processos

Conta os processos por estado e lista os PIDs dos que estão em execução ou prontos.

```bash
snap=$(ps -eo pid=,stat=)
total=$(wc -l <<<"$snap")
exec_pronto=$(awk '$2 ~ /^R/' <<<"$snap" | wc -l)
espera=$(awk '$2 ~ /^[SDI]/' <<<"$snap" | wc -l)
outros=$((total - exec_pronto - espera))
```

- `ps -eo pid=,stat=`: lista PID e estado (`stat`) de todos os processos. O `=` após o nome da coluna remove o cabeçalho, de modo que cada linha seja um processo.
- A saída é guardada **uma única vez** em `snap` (uma "foto"), para que todas as contagens sejam consistentes entre si.
- `<<<"$snap"` (*here-string*): envia o conteúdo da variável como entrada do comando.
- `wc -l`: conta linhas, ou seja, processos.
- `awk '$2 ~ /^R/'`: seleciona as linhas cuja 2ª coluna (o estado) **começa** com `R`.
- `$((...))`: aritmética do Bash.
- `paste -sd' ' -`: junta várias linhas em uma só, separadas por espaço (usado para listar os PIDs).

**Estados do Linux e a classificação usada:**

| Código | Significado no Linux | Classificação no relatório |
|---|---|---|
| `R` | Running (executando **ou** pronto na fila) | Execução / Pronto |
| `S` | Sleeping (espera interrompível) | Em espera |
| `D` | Espera não interrompível (geralmente E/S de disco) | Em espera |
| `I` | Thread ociosa do kernel | Em espera |
| `T` | Parado (sinal de parada ou depuração) | Outros |
| `Z` | Zumbi (terminou, mas o pai não coletou o status) | Outros |

**Limitação importante:** o Linux usa o mesmo estado `R` para o processo que está de fato na CPU e para o que está pronto aguardando na fila. Para separar os dois, o script assume **no máximo um processo em execução por núcleo** (`nproc`):

```bash
cpus=$(nproc)
if ((exec_pronto > cpus)); then executando=$cpus; else executando=$exec_pronto; fi
pronto=$((exec_pronto - executando))
```

O que ultrapassar o número de núcleos é contado como "pronto". É uma aproximação, e o próprio script avisa isso na tela.

Conexão com a teoria de SO: os estados clássicos *executando*, *pronto* e *bloqueado/em espera* do modelo de processos correspondem, no Linux, a `R` (executando e pronto) e `S`/`D` (bloqueado).

Na maior parte do tempo, uma máquina ociosa mostra 1 processo em execução (o próprio `ps`) e nenhum pronto. Para ver processos na fila de prontos, pode-se gerar carga em outro terminal com `yes > /dev/null &` (várias vezes) e depois usar a opção; para encerrar a carga, `pkill yes`.

### Opção 4 — Testar conectividade de rede

Pede um host (padrão: `google.com`) e testa se ele responde.

```bash
read -r -p "Host a testar [padrão: google.com]: " host
host=${host:-google.com}
if ping -c 3 "$host" 2>/dev/null; then
    echo "Resultado: host acessível."
else
    echo "Resultado: host inacessível."
fi
```

- `read -r -p "..." host`: lê a entrada do usuário mostrando uma mensagem (`-p`). O `-r` impede que a barra invertida seja interpretada.
- `host=${host:-google.com}`: se nada foi digitado, usa `google.com`.
- `ping` envia pacotes ICMP *Echo Request* e aguarda a resposta (*Echo Reply*).
- `-c 3` envia apenas 3 pacotes e encerra (sem isso, o ping rodaria indefinidamente).
- O código de saída do `ping` decide a mensagem: se retornar sucesso (`0`), o host está "acessível"; caso contrário, "inacessível". Isso é feito com `if ping ...; then`.

### Opção 5 — Finalizar o programa

```bash
5) echo; echo "Programa finalizado."; exit 0 ;;
```

`exit 0` encerra o script com código de sucesso. É a única saída do loop; qualquer entrada inválida apenas mostra "Opção inválida!" e volta ao menu.

---

## 4. Fluxo principal

```bash
while true; do
    tela_inicial
    read -r opcao
    case "$opcao" in
        1) opcao1 ;;
        2) opcao2 ;;
        3) opcao3 ;;
        4) opcao4 ;;
        5) echo; echo "Programa finalizado."; exit 0 ;;
        *) echo; echo "Opção inválida!"; sleep 1 ;;
    esac
done
```

- `while true`: repete indefinidamente, redesenhando a tela a cada volta.
- `read -r opcao`: lê a escolha do usuário.
- `case`: direciona cada número para a função correspondente; o `*` trata qualquer outra entrada.
- `sleep 1`: mantém a mensagem de erro visível por 1 segundo antes de o `clear` apagar a tela.
- `pausa` (ao final de cada opção): `read -r -p "Pressione ENTER..."` segura a tela para que o resultado possa ser lido antes de o menu ser redesenhado.

---

## 5. Conceitos de Sistemas Operacionais envolvidos

| Conceito | Onde aparece |
|---|---|
| Estados de processo (executando, pronto, bloqueado) | Opção 3 |
| Escalonamento e fila de prontos | Opção 3 (processos `R` acima do número de núcleos) |
| Processos zumbis e parados | Opção 3 (estados `Z` e `T`) |
| Uso de CPU e memória por processo | Opção 2 |
| Pseudo-sistema de arquivos `/proc` | Opção 1 (`/proc/cpuinfo`) e, indiretamente, `ps`, `free` e `uptime` |
| Pipes e redirecionamento (`\|`, `>`, `2>`, `<<<`) | Em todo o script |
| Entrada, saída e erro padrão (`stdin`, `stdout`, `stderr`) | `2>/dev/null`, `read` |
| Códigos de saída | `if ping ...`, `exit 0` |
| Protocolo ICMP | Opção 4 (`ping`) |

---

## 6. Observações e limitações

- **Locale:** o mês em português depende do locale `pt_BR.UTF-8` instalado. Sem ele, o mês aparece em inglês.
- **Opção 3:** a separação entre "executando" e "pronto" é uma aproximação, pois o Linux usa o mesmo estado `R` para ambos.
- **Opção 4:** depende de o comando `ping` estar instalado e de a rede permitir ICMP. Se o comando não existir ou a rede bloquear as respostas, o script mostra "host inacessível", mesmo que o host esteja no ar.
- **Permissões:** nenhuma opção exige privilégios de administrador.
