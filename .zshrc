# Définir GEM_HOME pour les gemmes utilisateur
export GEM_HOME="$(ruby -e 'puts Gem.user_dir' 2>/dev/null)"
[ -n "$GEM_HOME" ] && export PATH="$GEM_HOME/bin:$PATH"

# Alias pour reapack-index
alias reapack-index="/Users/mariotticedric/.gem/ruby/3.4.0/bin/reapack-index"

# Alias pour synchroniser ReaPack
alias reaperscripts='cd ~/Reaper_Scripts-Mariow'
alias reapack-sync='cd ~/Reaper_Scripts-Mariow && git add . && git commit -m "Mise à jour ReaPack" && git push origin main '
alias github-sync='cd ~/Reaper_Scripts-Mariow && git pull origin main '

# Alias si branches divergentes
alias divergent='git pull --rebase &&git push &&git pull'

# Initialiser rbenv
export PATH="$HOME/.rbenv/bin:$PATH"
eval "$(rbenv init - zsh)"

# Chemin pour java
export PATH="/usr/local/opt/openjdk/bin:$PATH"

# Alias commandes
alias gs='git status'
alias ga='git add .'
alias gc='git commit -m'
alias push='cd ~/Reaper_Scripts-Mariow &&git push origin main'
alias pull='cd ~/Reaper_Scripts-Mariow &&git pull origin main'
alias gl='git log --oneline --graph --decorate --all'
alias gb='git branch'
alias gco='git checkout'

# Alias reset reapack (effacement de l'historique)
alias reapack-reset='
cd ~/Reaper_Scripts-Mariow && \
rm -rf .git && \
git init && \
git remote add origin git@github.com:Geeksound/Reaper_Scripts-Mariow.git && \
git add . && \
git commit -m "Reset propre pour ReaPack" && \
git branch -M main && \
git push --force origin main'

# Alias pour ouvrir ce fichier et le sourcer
alias nano='nano ~/.zshrc'
alias source='source ~/.zshrc'

# Alias pour Capture du Tree > PICTURES
alias Githubtree='cd ~/Documents/GithubTree &&tree -L 2'

## Alias pour pousser la nouvelle image TREE
alias Githubtreepush='cd ~/Reaper_Scripts-Mariow &&git add PICTURES/Tree-Github.png &&git commit -m"MAJ Tree Picture" &&git push'
