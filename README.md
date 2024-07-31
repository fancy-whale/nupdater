# Nupdater - NuShell Module Update Manager

Nupdater is a script that ensures your nushell environment is always up to date. It runs automatically every time you open your nushell and attempts to update all modules located in the modules folder.

## How it works

1. When you open your nushell, the `nupdater.nu` script is triggered.
2. It checks for the cadence of the last update. If the last update was more than 24 hours ago (Configurable), it will proceed with the update process.
3. It scans the modules folder to identify all installed modules.
4. It checks for updates for each module by comparing the state of the local git repository with the remote repository.
5. If an update is available, it will pull the latest changes from the remote repository.
6. Once all modules have been updated, the nushell environment will be ready for use.

## Installation

To install nupdater, you can clone this repository into your nushell scripts folder and sourcing the `nupdater.nu` script in your nu config file:

```bash
git clone https://github.com/fancy-whale/nupdater.git ($nu.default-config-dir | path join scripts/nupdater)
echo "source nupdater/nupdater.nu\n" | save --append $nu.config-path
```

## Available Commands:

nupdate_check_modules: Checks for updates for all installed modules.
nupdate_modules: Updates all installed modules. (by default in the modules folder)