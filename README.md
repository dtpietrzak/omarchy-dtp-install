# omarchy-dtp-install

Installs every `omarchy-dtp-<feature>` repo.

```bash
./install.sh
```

Each feature stays in its own repo and installs itself. This script runs those installers in the order listed in `install.sh`. Running it again leaves anything that already matches untouched.

A checkout next to this repo is used when it is there. Once a feature has a git URL, add it after the name:

```bash
"omarchy-dtp-app-list https://example.com/omarchy-dtp-app-list.git"
```

Without a neighboring checkout, that URL is cloned into `~/.local/share/omarchy-dtp/<name>` and then installed.

## Features

- `omarchy-dtp-app-list`, the list launcher. Plugin id `dtpietrzak.applist`.
