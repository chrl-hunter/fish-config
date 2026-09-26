# =============================================================================
# Configuración de Fish
# Archivo: ~/.config/fish/config.fish
# =============================================================================


# -----------------------------------------------------------------------------
# Modo interactivo
# Evita ejecutar configuración visual en scripts que invoquen Fish.
# -----------------------------------------------------------------------------

if status is-interactive

    # Fish utiliza bindings tipo Emacs por defecto.
    fish_default_key_bindings
end

# =============================================================================
# Prompt
# =============================================================================

function fish_prompt
    set -l last_status $status

    # Rama Git.
    if type -q git
        set -l branch (
            command git symbolic-ref --quiet --short HEAD 2>/dev/null
        )

        if test -n "$branch"
            set_color blue
            printf '(%s)' $branch
        end
    end

    # Directorio actual.
    set_color green
    printf ' %s' (prompt_pwd)

    # Símbolo del prompt.
    set_color DAA520

    if fish_is_root_user
        set_color bred
        printf ' %s ' (whoami)
        printf ' # '
    else
        printf ' -> '
    end

    set_color normal
end


# =============================================================================
# Alias de Git
# =============================================================================

alias gs='git status'
alias ga='git add'
alias gaa='git add --all'
alias gc='git commit'
alias gl='git log --oneline'

# alias gb='git checkout -b'
# alias gd='git diff'


# =============================================================================
# Alias generales
# =============================================================================

alias ..='cd ..; pwd'
alias ...='cd ../..; pwd'
alias ....='cd ../../..; pwd'
alias cl='clear'
alias h='history'
alias tre='tree -L 3 --dirsfirst -F'
alias mkdir='mkdir -p -v'
alias l='ls'
alias la='ls -la'
alias lah='ls -lah'
alias ll='ls -l'
alias norman='watch -n 2 norminette'
alias forest='watch -n 5 tree -L 3 --dirsfirst -F'

# =============================================================================
# NeoVim
# =============================================================================

alias vim='nvim'
alias vi='nvim'

# =============================================================================
# Alias de C
# =============================================================================

alias ccw='cc -Wall -Wextra -Werror'


# =============================================================================
# Buscar en el historial
#
# Uso:
#   hg git
#   hg norminette
# =============================================================================

function hg
    if test (count $argv) -eq 0
        printf 'Uso: hg <texto>\n'
        return 1
    end

    history | grep --color=auto -i -- "$argv"
end


# =============================================================================
# Mostrar los 20 elementos más grandes del directorio actual
# =============================================================================

function find_largest_files
    command du -h -x -s -- * 2>/dev/null |
        command sort -r -h |
        command head -n 20
end


# =============================================================================
# Obtener la rama Git actual
#
# Se conserva como función independiente aunque fish_prompt ya obtiene la rama.
# =============================================================================

function git_branch
    if test -d .git
        set -l branch (
            command git symbolic-ref --quiet --short HEAD 2>/dev/null
        )

        if test -n "$branch"
            printf '(%s)' $branch
        end
    end
end


# =============================================================================
# Crear un directorio e inicializar un repositorio Git
#
# Uso:
#   git_init nombre_del_proyecto
# =============================================================================

function git_init
    if test (count $argv) -eq 0
        printf '%s\n' 'Please provide a directory name.'
        return 1
    end

    set -l directory $argv[1]

    command mkdir -p -v -- "$directory"
    or return 1

    builtin cd -- "$directory"
    or return 1

    command git init
    or return 1

    command touch readme.md .gitignore LICENSE

    if not grep -q '^# ' readme.md 2>/dev/null
        printf '# %s\n' (basename "$PWD") >>readme.md
    end
end


# =============================================================================
# Obtener resolución de pantalla
# Compatible parcialmente con X11 y Wayland.
# =============================================================================

function current_resolution
    if type -q xrandr
        set -l resolution (
            command xrandr 2>/dev/null |
            awk '/\*/ { print $1; exit }'
        )

        if test -n "$resolution"
            printf '%s' "$resolution"
            return 0
        end
    end

    printf '%s' unknown
end


# =============================================================================
# Información básica del sistema
# =============================================================================

function fetch
    clear

    set -l public_ip unavailable
    set -l cpu unknown
    set -l os unknown
    set -l packages unknown
    set -l memory unknown

    if type -q curl
        set public_ip (
            command curl \
                --silent \
                --max-time 3 \
                https://ifconfig.me 2>/dev/null
        )

        if test -z "$public_ip"
            set public_ip unavailable
        end
    end

    if type -q lscpu
        set cpu (
            command lscpu |
            awk -F: '/Model name/ {
                sub(/^[ \t]+/, "", $2);
                print $2;
                exit
            }'
        )
    end

    if test -r /etc/os-release
        set os (
            string match 'PRETTY_NAME=*' < /etc/os-release |
            string replace 'PRETTY_NAME=' '' |
            string trim --chars='"'
        )
    end

    if type -q dpkg-query
        set packages (
            command dpkg-query -f '.\n' -W 2>/dev/null |
            command wc -l |
            string trim
        )
    end

    if type -q free
        set memory (
            command free -h |
            awk '/^Mem:/ { print $3 "/" $2 }'
        )
    end

    printf '\n'
    printf '   IP ADDR:    %s\n' "$public_ip"
    printf '   USER:       %s\n' "$USER"
    printf '   DATE:       %s\n' (date)
    printf '   UPTIME:     %s\n' (uptime -p)
    printf '   HOSTNAME:   %s\n' (hostname -f)
    printf '   CPU:        %s\n' "$cpu"
    printf '   OS:         %s\n' "$os"
    printf '   KERNEL:     %s\n' (uname -rms)
    printf '   PACKAGES:   %s\n' "$packages"
    printf '   RESOLUTION: %s\n' (current_resolution)
    printf '   MEMORY:     %s\n' "$memory"
    printf '\n'
end


export USER=cperez-h
export MAIL=cperez-h@student.42barcelona.com
