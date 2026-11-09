#!/bin/bash
# IBMEC - Sistemas Operacionais (IBM8940) - Turma 8001
# Script com tela inicial e menu interativo

# ---------------- CONFIGURAÇÃO ----------------
LARG=66   # largura total da moldura (número de '#' da linha de cima)

ALUNOS=(
    "Diego Gode Bonani"
    "João Pedro Lima de Campos"
)

MESES=(janeiro fevereiro março abril maio junho julho agosto setembro outubro novembro dezembro)

# A opção 5 é a ÚNICA forma de sair: ignora Ctrl+C, Ctrl+Z e Ctrl+\
trap '' SIGINT SIGTSTP SIGQUIT

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
linha() {
    local esq="$1" dir="$2"
    local esp=$((LARG - 4 - ${#esq} - ${#dir}))
    ((esp < 0)) && esp=0
    printf '# %s%s%s #\n' "$esq" "$(repete ' ' "$esp")" "$dir"
}

# ---------------- TELA INICIAL ----------------
tela_inicial() {
    local dia mes ano hora min

    # Valores do sistema (mês em português pela tabela MESES)
    dia=$(date +%d)
    mes=${MESES[$(( 10#$(date +%m) - 1 ))]}
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
    echo "  3) Maiores itens em um diretório"
    echo "  4) Testar conectividade de rede"
    echo "  5) Finalizar o programa."
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

opcao4() {
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

# ---------------- LOOP PRINCIPAL ----------------
# A única forma de finalizar o script é pela opção 5.
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
