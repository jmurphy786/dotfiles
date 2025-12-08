## Dotfiles setup

# Install git
sudo pacman -S git stow

# Clone your dotfiles from GitHub
git clone https://github.com/yourusername/dotfiles.git ~/dotfiles

# Stow your configs
cd ~/dotfiles
stow bash
stow tmux
stow nvim
# etc

# Install your saved packages
sudo pacman -S --needed - < ~/dotfiles/packages.txt

# Test!
tmux  # test tmux config
nvim  # test nvim config
