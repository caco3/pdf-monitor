# PDF Monitor

This is a simple docker container which uses `inotifywait` to monitor a folder for new files.
Once it detects that a new file got created (dropped into the folder), it checks if it is a `PDF` file.
If so, it renames it based on the creation Date/Time.
Afterwards it compresses it to save space and moves it into a new folder.

I use this tool to process PDFs automatically uploaded by my scanner. They usually are named `Scan001.pdf` and not compressed at all.

## Usage:
In docker compose:
```docker
services:
  pdf-monitor:
    build:
      context: monitor-and-modify-files
      dockerfile: Dockerfile
    container_name: pdf-monitor
    volumes:
      - ./uploaded:/uploaded
      - /processed:/processed
    restart: unless-stopped
```

The files must be dropped into the `uploaded` folder. The tool will move them to the `processed` folder.
