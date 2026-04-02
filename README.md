# Nemo Actions

Lokales Git-Repo fuer meine Nemo-Rechtsklick-Tools.

## Inhalt

- `actions/`: Nemo-Action-Dateien fuer das Kontextmenue
- `scripts/`: zugehoerige Shell-Skripte
- `extras/`: vorhandene Helferskripte, die aktuell nicht automatisch installiert werden
- `config/`: lauffaehige Standardkonfigurationen
- `install.sh`: kopiert Actions, Skripte und Standardkonfigurationen in die ueblichen Nemo-Pfade

## Enthaltene Actions

- `extract_tar7z_to_moar_space.nemo_action`
  Entpackt `tar.7z` direkt im aktuellen Ordner mit Progress-Ausgabe im Terminal.
- `multicore-zip.nemo_action`
  Erstellt ein `tar.7z` mit konfigurierbaren Presets, heuristischer RAM-Schaetzung und Temp-Dateien auf dem Quell-Dateisystem.
- `vaapi-whatsapp-180mb.nemo_action`
  Konvertiert eine `mkv` per VA-API zu einer WhatsApp-tauglichen `mp4`.

## Installation

```bash
./install.sh --all
```

Selektiv:

```bash
./install.sh --extract-tar7z
./install.sh --multicore-zip
./install.sh --vaapi-whatsapp
./install.sh --extract-tar7z --vaapi-whatsapp
```

Standardpfade:

- `~/.local/share/nemo/actions`
- `~/.local/bin`
- `~/.config/nemo-actions`

Konfigurierbar ueber Umgebungsvariablen:

- `NEMO_ACTIONS_DIR`
- `BIN_DIR`
- `NEMO_CONFIG_DIR`
- `XDG_DATA_HOME`
- `XDG_BIN_HOME`
- `XDG_CONFIG_HOME`

Optional fuer `install.sh`:

- `INSTALL_NEMO_CONFIG=0` installiert keine Config-Dateien
- `OVERWRITE_NEMO_CONFIG=1` ueberschreibt vorhandene aktive Configs
- `MERGE_NEMO_RAM_SETTINGS=1` traegt bei bestehender `multicore-zip.conf` nur fehlende RAM-Keys nach
- `./install.sh --help` zeigt alle installierbaren Tools und Optionen

## Abhaengigkeiten

- `7z`
- `pv`
- `tar`
- `ffmpeg`
- `ffprobe`
- optional fuer Extras: `zenity`, `pigz`

## Multicore-ZIP konfigurieren

`scripts/nemo-multicore-zip.sh` unterstuetzt Presets und eine grobe Speicherplanung fuer `7z` mit `LZMA2`.

Standardkonfiguration:

```bash
./install.sh --all
```

Danach liegt standardmaessig vor:

- `~/.config/nemo-actions/multicore-zip.conf`

Bei bestehender `multicore-zip.conf` bleibt die aktive Konfiguration standardmaessig erhalten. Der Installer installiert die Standard-Config nur bei Erstinstallation und kann spaeter fehlende RAM-bezogene Variablen in die aktive Config nachtragen.

Wichtige Variablen:

- `NEMO_7Z_PRESET=safe|balanced|aggressive|legacy`
- `NEMO_7Z_RAM_BUDGET_GIB=16`
- `NEMO_7Z_THREADS=8`
- `NEMO_7Z_DICT=128m`
- `NEMO_7Z_LEVEL=9`

Aktuelle Presets:

- `safe`: `-mx7 -md64m -mmt4`
- `balanced`: `-mx9 -md128m -mmt8`
- `aggressive`: `-mx9 -md256m -mmt12`
- `legacy`: `-mx9 -md320m -mmt$(nproc)`

Die ausgegebene RAM-Schaetzung ist absichtlich nur heuristisch. Das Skript verwendet fuer `LZMA2` grob:

```text
estimate ~= ceil(threads / 2) * dict_mib * factor
```

Standardmaessig ist `factor=11`.

## VAAPI-WhatsApp konfigurieren

`scripts/vaapi_whatsapp_180mb.sh` liest optional:

- `~/.config/nemo-actions/vaapi-whatsapp-180mb.conf`

Wichtige Variablen:

- `NEMO_WA_TARGET_MB=180`
- `NEMO_WA_AUDIO_KBPS=128`
- `NEMO_WA_MAX_WIDTH=1920`
- `NEMO_WA_MAX_HEIGHT=1080`
- `NEMO_WA_SAFETY_FACTOR=0.94`
- `NEMO_WA_VAAPI_DEVICE=/dev/dri/renderD128`

## Extras

`extras/nemo_pack_tar_gz_progress.sh` ist aus dem bisherigen Setup uebernommen, aber noch nicht als Nemo-Action verdrahtet.
