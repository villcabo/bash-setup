# TMUX Configuration

## Instalacion

Instalacion configuration de **TMUX**

```bash
wget -q https://raw.githubusercontent.com/villcabo/bash-setup/main/tmux_configuration/tmux.conf -O ~/.tmux.conf
```

Tmux Plugin Manager **TPM**

```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```

Para recargar la configuracion, debe iniciar **tmux** y teclear **ctrl + A shit I**

**En caso de que tmux ya se este ejecutando, puede utilizar este comando para recargar la configuracion**
```
tmux source ~/.tmux.conf
```

Si desea customizar el tema vaya al siguiente link:
- [Tokyo Night Tmux (DEFAULT)](https://github.com/janoamaral/tokyo-night-tmux?tab=readme-ov-file)
- [Tokyo Night Tmux Theme](https://github.com/fabioluciano/tmux-tokyo-night?tab=readme-ov-file)
