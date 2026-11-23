# =============================================================================
# Configuración de Fish
# Archivo: ~/.config/fish/config.fish
# =============================================================================


# Ajustes de CachyOS para sesiones interactivas.
if status is-interactive
    if test -r /usr/share/cachyos-fish-config/conf.d/done.fish
        set -g __done_min_cmd_duration 10000
        set -g __done_notification_urgency_level low
        source /usr/share/cachyos-fish-config/conf.d/done.fish
    end

    if command -q bat; and command -q col
        set -gx MANROFFOPT -c
        set -gx MANPAGER "sh -c 'col -bx | bat -l man -p'"
    end
end

function fish_greeting
 #    if command -q fastfetch
 #        command fastfetch
 #    end
end

if test -r ~/.fish_profile
    source ~/.fish_profile
end

fish_add_path --global ~/.local/bin ~/.cargo/bin ~/Applications/depot_tools


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
        printf ' ❯ '
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

alias nv='nvim'

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

    if command -q pacman
        set packages (command pacman -Qq | command wc -l | string trim)
    else if type -q dpkg-query
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


# =============================================================================
# Funciones y alias de CachyOS
# =============================================================================

function __history_previous_command
    switch (commandline -t)
        case '!'
            if set -q history[1]
                commandline -t -- $history[1]
                commandline -f repaint
            else
                commandline -i '!'
            end
        case '*'
            commandline -i '!'
    end
end

function __history_previous_command_arguments
    switch (commandline -t)
        case '!'
            commandline -t ''
            commandline -f history-token-search-backward
        case '*'
            commandline -i '$'
    end
end

if status is-interactive
    if test "$fish_key_bindings" = fish_vi_key_bindings
        bind -M insert '!' __history_previous_command
        bind -M insert '$' __history_previous_command_arguments
    else
        bind '!' __history_previous_command
        bind '$' __history_previous_command_arguments
    end
end

function history
    builtin history --show-time='%F %T ' $argv
end

function backup --argument-names filename
    if test (count $argv) -ne 1
        printf 'Uso: backup <archivo>\n' >&2
        return 2
    end

    command cp -- "$filename" "$filename.bak"
end

function copy
    if test (count $argv) -eq 2; and test -d "$argv[1]"
        command cp -r -- "$argv[1]" "$argv[2]"
    else
        command cp $argv
    end
end

if command -q eza
    alias ls='eza -al --color=always --group-directories-first --icons=always'
    alias la='eza -a --color=always --group-directories-first --icons=always'
    alias ll='eza -l --color=always --group-directories-first --icons=always'
    alias lt='eza -aT --color=always --group-directories-first --icons=always'
    alias l.="eza -a | grep -e '^\.'"
end

alias .....='cd ../../../..; pwd'
alias ......='cd ../../../../..; pwd'
alias grubup='sudo grub-mkconfig -o /boot/grub/grub.cfg'
alias fixpacman='sudo rm /var/lib/pacman/db.lck'
alias tarnow='tar -acf'
alias untar='tar -zxvf'
alias wget='wget -c'
alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'
alias dir='dir --color=auto'
alias vdir='vdir --color=auto'
alias grep='grep --color=auto'
alias fgrep='grep -F --color=auto'
alias egrep='grep -E --color=auto'
alias hw='hwinfo --short'
alias big="expac -H M '%m\t%n' | sort -h | nl"
alias gitpkg="pacman -Q | grep -ic -- '-git'"
alias update='sudo cachyos-rate-mirrors && sudo pacman -Syu'
alias mirror='sudo cachyos-rate-mirrors'
alias apt='man pacman'
alias apt-get='man pacman'
alias tb='nc termbin.com 9999'
alias jctl='journalctl -p 3 -xb'
alias rip="expac --timefmt='%Y-%m-%d %T' '%l\t%n %v' | sort | tail -200 | nl"

function cleanup
    set -l orphans (command pacman -Qtdq)
    if set -q orphans[1]
        sudo pacman -Rns -- $orphans
    end
end
