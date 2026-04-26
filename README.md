# WezTerm Installer

This repository provides:

- `install-wezterm-neovim.sh`: installs WezTerm and the fonts required by the bundled WezTerm configuration.
- `.wezterm.lua`: downloaded from the repository raw URL and installed as the active WezTerm configuration.

## Supported distributions

- Arch Linux and Arch-based distributions.
- Ubuntu, Debian, and Debian-based distributions.

## What the script installs

### Arch Linux

The script installs these packages with pacman:

- wezterm
- ttf-jetbrains-mono-nerd
- ttf-firacode-nerd
- ttf-nerd-fonts-symbols-mono

### Ubuntu and Debian

The script installs these base packages first:

- ca-certificates
- curl
- gnupg
- unzip
- fontconfig

Then it configures the official WezTerm APT repository and installs:

- wezterm

It also downloads and installs these Nerd Fonts from the official Nerd Fonts release assets:

- JetBrains Mono Nerd Font
- FiraCode Nerd Font
- Symbols Nerd Font Mono

## What happens to the WezTerm config

The script downloads `.wezterm.lua` from:

- `https://raw.githubusercontent.com/Tonymartos/tonys-wezterm-conf/main/.wezterm.lua`

After the packages and fonts are installed, the script:

1. Downloads that file and installs it to the target user's home as `~/.wezterm.lua`.
2. Creates a timestamped backup if a different ~/.wezterm.lua already exists.
3. Skips the install if the downloaded config is identical to the current one.

## How to run it

### Quick install

Once the script is published at the repository root, the fastest way to run it is:

~~~bash
bash <(curl -fsSL https://raw.githubusercontent.com/Tonymartos/tonys-wezterm-conf/main/install-wezterm-neovim.sh)
~~~

### Download only the config

If you only want the WezTerm config:

~~~bash
curl -fsSL -o ~/.wezterm.lua https://raw.githubusercontent.com/Tonymartos/tonys-wezterm-conf/main/.wezterm.lua
~~~

### Run from a local copy

If you already have the script locally:

~~~bash
./install-wezterm-neovim.sh
~~~

If the script is not executable yet:

~~~bash
chmod +x ./install-wezterm-neovim.sh
./install-wezterm-neovim.sh
~~~

The script uses sudo automatically when needed.

## Notes

- You can override the config URL by exporting `WEZTERM_CONFIG_URL` before running the script.
- Restart WezTerm after the installation finishes so the installed fonts and copied config are picked up.
