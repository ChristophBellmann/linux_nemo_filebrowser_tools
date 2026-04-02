# Nemo Actions

Lokales Git-Repo fuer meine Nemo-Rechtsklick-Tools.

## Inhalt

- `actions/`: Nemo-Action-Dateien fuer das Kontextmenue
- `scripts/`: zugehoerige Shell-Skripte
- `extras/`: vorhandene Helferskripte, die aktuell nicht automatisch installiert werden
- `install.sh`: kopiert die Actions und Skripte in die ueblichen Nemo-Pfade

## Enthaltene Actions

- `extract_tar7z_to_moar_space.nemo_action`
  Entpackt `tar.7z` direkt im aktuellen Ordner mit Progress-Ausgabe im Terminal.
- `multicore-zip.nemo_action`
  Erstellt ein `tar.7z` mit konfigurierbaren Presets, heuristischer RAM-Schaetzung und Temp-Dateien auf dem Quell-Dateisystem.
- `vaapi-whatsapp-180mb.nemo_action`
  Konvertiert eine `mkv` per VA-API zu einer WhatsApp-tauglichen `mp4`.

## Installation

```bash
./install.sh
```

Standardpfade:

- `~/.local/share/nemo/actions`
- `~/.local/bin`

Konfigurierbar ueber Umgebungsvariablen:

- `NEMO_ACTIONS_DIR`
- `BIN_DIR`
- `XDG_DATA_HOME`
- `XDG_BIN_HOME`

## Abhaengigkeiten

- `7z`
- `pv`
- `tar`
- `ffmpeg`
- `ffprobe`
- optional fuer Extras: `zenity`, `pigz`

## Multicore-ZIP konfigurieren

`scripts/nemo-multicore-zip.sh` unterstuetzt Presets und eine grobe Speicherplanung fuer `7z` mit `LZMA2`.

Optionale Konfigurationsdatei:

```bash
mkdir -p ~/.config/nemo-actions
cp config/multicore-zip.conf.example ~/.config/nemo-actions/multicore-zip.conf
```

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

## Extras

`extras/nemo_pack_tar_gz_progress.sh` ist aus dem bisherigen Setup uebernommen, aber noch nicht als Nemo-Action verdrahtet.
