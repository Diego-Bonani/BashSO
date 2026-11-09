#!/bin/bash
# IBMEC - Sistemas Operacionais (IBM8940) - Turma 8001
# Script com tela inicial e menu interativo

# ---------------- CONFIGURAÇÃO ----------------
LARG=66   # largura total da moldura (número de '#' da linha de cima)

ALUNOS=(
    "Diego Gode Bonani"
    "João Pedro Lima de Campos"
)

# ---------------- FUNÇÕES DE DESENHO ----------------

# Repete um caractere N vezes
repete() {
    local c="$1" n="$2" out=""
    for ((i = 0; i < n; i++)); do out+="$c"; done
    printf '%s' "$out"
}

# Linha de '#' (topo/rodapé)
borda() {
    repete "#" "$LARG"; echo
}

# Linha separadora "#------#"
separador() {
    printf '#'; repete "-" $((LARG - 2)); printf '#\n'
}

# Linha de conteúdo: texto à esquerda e (opcional) texto à direita.
# Usa ${#var} (conta caracteres, não bytes) para alinhar acentos corretamente.
linha() {
    local esq="$1" dir="$2"
    local esp=$((LARG - 4 - ${#esq} - ${#dir}))
    ((esp < 0)) && esp=0
    printf '# %s%s%s #\n' "$esq" "$(repete ' ' "$esp")" "$dir"
}

# ---------------- TELA INICIAL ----------------
tela_inicial() {
    local dia mes ano hora min

    # Valores do sistema (mês por extenso em português vindo do date)
    dia=$(date +%d)
    mes=$(LC_TIME=pt_BR.UTF-8 date +%B)
    ano=$(date +%Y)
    hora=$(date +%H)
    min=$(date +%M)

    clear
    borda
    linha "IBMEC"
    linha "Sistemas Operacionais" "Semestre 2 de 2026"
    linha "Código: IBM8940" "Turma: 8001"
    linha "Professor: Luiz Fernando T. de Farias"
    separador
    linha "Equipe Desenvolvedora:"
    for aluno in "${ALUNOS[@]}"; do
        linha "  Aluno: $aluno"
    done
    separador
    linha "Rio de Janeiro, $dia de $mes de $ano"
    linha "Hora do Sistema: $hora Horas e $min Minutos"
    borda
    echo
    echo "Menu de Escolhas:"
    echo "  1) Informações do sistema"
    echo "  2) Processos que mais consomem memória e CPU"
    echo "  3) Estado dos processos (execução, pronto, espera)"
    echo "  4) Espaço em disco por diretório"
    echo "  5) Testar conectividade de rede"
    echo "  6) Rastrear rota até um host (traceroute)"
    echo "  7) Verificar se uma porta de rede está em uso"
    echo "  8) Finalizar o programa."
    echo
    printf 'Selecione uma opção: '
}

# ---------------- OPÇÕES DO MENU ----------------
pausa() {
    echo
    read -r -p "Pressione ENTER para voltar ao menu..." _
}

opcao1() {
    echo
    echo "=== Informações do sistema ==="
    echo "Usuário......: $USER"
    echo "Host.........: $(hostname)"
    echo "Kernel.......: $(uname -sr)"
    echo "Uptime.......: $(uptime -p 2>/dev/null)"
    echo "CPU..........: $(grep -m1 'model name' /proc/cpuinfo 2>/dev/null | cut -d: -f2 | sed 's/^ //')"
    echo "Núcleos......: $(nproc 2>/dev/null)"
    echo "Memória (MB).: $(free -m 2>/dev/null | awk '/Mem:/ {print $3 " usados de " $2}')"
    pausa
}

opcao2() {
    echo
    echo "=== Top 5 processos por uso de memória ==="
    ps -eo pid,user,%mem,%cpu,comm --sort=-%mem 2>/dev/null | head -n 6
    echo
    echo "=== Top 5 processos por uso de CPU ==="
    ps -eo pid,user,%cpu,%mem,comm --sort=-%cpu 2>/dev/null | head -n 6
    pausa
}

opcao3() {
    local snap total exec_pronto espera outros cpus executando pronto
    echo
    echo "=== Estado dos processos ==="

    # Uma única "foto" dos processos, para os números ficarem consistentes
    snap=$(ps -eo pid=,stat=)
    total=$(wc -l <<<"$snap")
    exec_pronto=$(awk '$2 ~ /^R/' <<<"$snap" | wc -l)   # R = executando ou pronto
    espera=$(awk '$2 ~ /^[SDI]/' <<<"$snap" | wc -l)    # S, D, I = em espera
    outros=$((total - exec_pronto - espera))            # T (parado), Z (zumbi)...

    # O Linux usa o mesmo estado (R) para "executando" e "pronto".
    # No máximo 1 processo por núcleo executa de fato; o resto está na fila.
    cpus=$(nproc)
    if ((exec_pronto > cpus)); then executando=$cpus; else executando=$exec_pronto; fi
    pronto=$((exec_pronto - executando))

    echo "Total de processos........: $total"
    echo "Em execução...............: $executando"
    echo "Prontos (fila da CPU).....: $pronto"
    echo "Em espera (dormindo/E-S)..: $espera"
    echo "Outros (parados, zumbis)..: $outros"
    echo
    echo "PIDs em execução/prontos (R): $(awk '$2 ~ /^R/ {print $1}' <<<"$snap" | paste -sd' ' -)"
    echo
    echo "Obs.: o Linux marca execução e pronto com o mesmo estado (R); a divisão"
    echo "acima assume no máximo 1 processo em execução por núcleo ($cpus núcleo(s))."
    pausa
}

opcao4() {
    local dir
    echo
    read -r -p "Diretório a analisar [padrão: $HOME]: " dir
    dir=${dir:-$HOME}
    if [[ -d "$dir" ]]; then
        echo "=== Maiores itens em $dir ==="
        du -sh "$dir"/* 2>/dev/null | sort -rh | head -n 10
    else
        echo "Diretório inválido: $dir"
    fi
    pausa
}

opcao5() {
    local host
    echo
    read -r -p "Host a testar [padrão: google.com]: " host
    host=${host:-google.com}
    echo "=== Testando conectividade com $host ==="
    if ping -c 3 "$host" 2>/dev/null; then
        echo "Resultado: host acessível."
    else
        echo "Resultado: host inacessível."
    fi
    pausa
}

opcao6() {
    local host
    echo
    read -r -p "Host a rastrear [padrão: google.com]: " host
    host=${host:-google.com}
    echo "=== Rota até $host ==="

    if command -v traceroute >/dev/null 2>&1; then
        # -I usa ICMP (menos filtrado que o UDP padrão); exige root
        sudo traceroute -I -m 20 "$host"
    else
        echo "Não foi possível instalar o traceroute. Usando tracepath."
        tracepath -m 20 "$host"
    fi
    pausa
}

opcao7() {
    local porta escuta conexoes hex n
    echo
    read -r -p "Número da porta a verificar (1-65535): " porta
    if ! [[ "$porta" =~ ^[0-9]+$ ]] || ((10#$porta < 1 || 10#$porta > 65535)); then
        echo "Porta inválida."
        pausa
        return
    fi
    porta=$((10#$porta))
    echo "=== Verificando a porta $porta ==="

    if command -v ss >/dev/null 2>&1; then
        # Serviços em escuta (TCP/UDP) nessa porta local
        escuta=$(ss -tulnpH "sport = :$porta" 2>/dev/null)
        # Conexões TCP estabelecidas que usam a porta como origem ou destino
        conexoes=$(ss -tnH state established "( sport = :$porta or dport = :$porta )" 2>/dev/null)
    else
        # Plano B sem o comando ss: lê as tabelas de sockets do kernel.
        # Portas aparecem em hexadecimal; TCP: estado 0A = escuta, 01 = estabelecida.
        printf -v hex '%04X' "$porta"
        escuta=$(awk -v h=":$hex" '
            $2 ~ (h "$") && (FILENAME ~ /udp/ || $4 == "0A") {print FILENAME ": " $2}
        ' /proc/net/tcp /proc/net/tcp6 /proc/net/udp /proc/net/udp6 2>/dev/null)
        conexoes=$(awk -v h=":$hex" '
            $4 == "01" && ($2 ~ (h "$") || $3 ~ (h "$")) {print $2 " -> " $3}
        ' /proc/net/tcp /proc/net/tcp6 2>/dev/null)
    fi

    echo
    echo "[1] Serviço escutando nessa porta (este computador é o servidor):"
    if [[ -n "$escuta" ]]; then
        echo "$escuta"
    else
        echo "    Nenhum."
    fi

    echo
    echo "[2] Conexões TCP estabelecidas usando essa porta:"
    if [[ -n "$conexoes" ]]; then
        n=$(wc -l <<<"$conexoes")
        echo "$conexoes"
        echo "    Total: $n conexão(ões)."
    else
        echo "    Nenhuma."
    fi

    echo
    if [[ -n "$escuta" ]]; then
        echo "Resultado: porta $porta EM USO (servindo)."
    elif [[ -n "$conexoes" ]]; then
        echo "Resultado: porta $porta sem servidor local, mas com conexões ativas (este computador é cliente)."
    else
        echo "Resultado: porta $porta LIVRE."
    fi
    pausa
}

# ---------------- PREPARAÇÃO DO AMBIENTE ----------------
# Roda uma única vez, antes de desenhar a tela: pede a senha de administrador
# (fica em cache por alguns minutos) e instala o traceroute em silêncio.
preparar_ambiente() {
    echo "Preparando o ambiente (pode ser solicitada a senha de administrador)..."
    sudo -v 2>/dev/null
    if ! command -v traceroute >/dev/null 2>&1; then
        sudo apt-get install -y -qq traceroute >/dev/null 2>&1
    fi
}

# ---------------- LOOP PRINCIPAL ----------------
# A única forma de finalizar o script é pela opção 8.
preparar_ambiente
while true; do
    tela_inicial
    read -r opcao
    case "$opcao" in
        1) opcao1 ;;
        2) opcao2 ;;
        3) opcao3 ;;
        4) opcao4 ;;
        5) opcao5 ;;
        6) opcao6 ;;
        7) opcao7 ;;
        8) echo; echo "Programa finalizado."; exit 0 ;;
        *) echo; echo "Opção inválida!"; sleep 1 ;;
    esac
done
