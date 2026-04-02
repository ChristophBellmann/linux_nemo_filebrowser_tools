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
  Erstellt ein `tar.7z` mit allen CPU-Kernen und Temp-Dateien auf dem Quell-Dateisystem.
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

## Extras

`extras/nemo_pack_tar_gz_progress.sh` ist aus dem bisherigen Setup uebernommen, aber noch nicht als Nemo-Action verdrahtet.
