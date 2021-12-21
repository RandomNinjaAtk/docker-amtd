# AMTD - Automated Movie Trailer Downloader 
[![Docker Build](https://img.shields.io/docker/cloud/automated/randomninjaatk/amtd?style=flat-square)](https://hub.docker.com/r/randomninjaatk/amtd)
[![Docker Pulls](https://img.shields.io/docker/pulls/randomninjaatk/amtd?style=flat-square)](https://hub.docker.com/r/randomninjaatk/amtd)
[![Docker Stars](https://img.shields.io/docker/stars/randomninjaatk/amtd?style=flat-square)](https://hub.docker.com/r/randomninjaatk/amtd)
[![Docker Hub](https://img.shields.io/badge/Open%20On-DockerHub-blue?style=flat-square)](https://hub.docker.com/r/randomninjaatk/amtd)
[![Discord](https://img.shields.io/discord/747100476775858276.svg?style=flat-square&label=Discord&logo=discord)](https://discord.gg/JumQXDc "realtime support / chat with the community." )

[RandomNinjaAtk/amtd](https://github.com/RandomNinjaAtk/docker-amtd) is a Radarr companion script to automatically download movie trailers and extras for use in other video applications (plex/kodi/jellyfin/emby) 

[![RandomNinjaAtk/amtd](https://raw.githubusercontent.com/RandomNinjaAtk/unraid-templates/master/randomninjaatk/img/amtd.png)](https://github.com/RandomNinjaAtk/docker-amtd)


## Features
* Downloading **Movie Trailers** and **Extras** using online sources for use in popular applications (Plex/Kodi/Emby/Jellyfin): 
  * Connects to Radarr to automatically download trailers for Movies in your existing library
  * Downloads videos using youtube-dl automatically
  * Names videos correctly to match Plex/Emby naming convention (Emby not tested)
  * Embeds relevant metadata into each video
  

### Plex Example
![](https://raw.githubusercontent.com/RandomNinjaAtk/docker-amtd/master/.github/amvtd-plex-example.jpg)


## Supported Architectures

The architectures supported by this image are:

| Architecture | Tag |
| :----: | --- |
| x86-64 | latest |

## Version Tags

| Tag | Description |
| :----: | --- |
| latest | Newest release code |


## Parameters

Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate `<external>:<internal>` respectively. For example, `-p 8080:80` would expose port `80` from inside the container to be accessible from the host's IP on port `8080` outside the container.

| Parameter | Function |
| --- | --- |
| `-e PUID=1000` | for UserID - see below for explanation |
| `-e PGID=1000` | for GroupID - see below for explanation |
| `-v /config` | Configuration files for AMTD. |
| `-v /change/me/to/match/radarr` | Configure this volume to match your Radarr Radarr's volume mappings associated with Radarr's Library Root Folder settings |
| `-e AUTOSTART=true` | true = Enabled :: Runs script automatically on startup |
| `-e SCRIPTINTERVAL=1h` | #s or #m or #h or #d :: s = seconds, m = minutes, h = hours, d = days :: Amount of time between each script run, when AUTOSTART is enabled|
| `-e RadarrUrl=http://x.x.x.x:7878` | Set domain or IP to your Radarr instance including port. If using reverse proxy, do not use a trailing slash. Ensure you specify http/s. |
| `-e RadarrAPIkey=08d108d108d108d108d108d108d108d1` | Radarr API key. |
| `-e extrastype=all` | all or trailers :: all downloads all available videos (trailers, clips, featurette, etc...) :: trailers only downloads trailers |
| `-e LANGUAGES=en,de` | Set the primary desired language, if not found, fallback to next langauge in the list... (this is a "," separated list of ISO 639-1 language codes) |
| `-e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"` | For guidence, please see youtube-dl documentation |
| `-e subtitlelanguage=en` | Desired Language Code :: For guidence, please see youtube-dl documentation. |
| `-e USEFOLDERS=false` | true = enabled :: Creates subfolders within the movie folder for extras |
| `-e EndClient=plex` | plex or emby or jellyfin :: Select the appropriate client for maximum compatibility |
| `-e PREFER_EXISTING=false` | true = enabled :: Checks for existing "trailer" file, and skips it if found |
| `-e SINGLETRAILER=true` | true = enabled :: Only downloads the first available trailer, does not apply to other extras type |
| `-e FilePermissions=644` | Based on chmod linux permissions |
| `-e FolderPermissions=755` | Based on chmod linux permissions |

### docker

```
docker create \
  --name=amtd \
  -v /path/to/config/files:/config \
  -v /change/me/to/match/radarr:/change/me/to/match/radarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e AUTOSTART=true \
  -e SCRIPTINTERVAL=1h \
  -e extrastype=all \
  -e LANGUAGES=en,de \
  -e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio" \
  -e subtitlelanguage=en \
  -e USEFOLDERS=false \
  -e PREFER_EXISTING=false \
  -e SINGLETRAILER=true \
  -e FilePermissions=644 \
  -e FolderPermissions=755 \
  -e RadarrUrl=http://x.x.x.x:7878 \
  -e RadarrAPIkey=RADARRAPIKEY \
  -e EndClient=plex \
  --restart unless-stopped \
  randomninjaatk/amtd 
```


### docker-compose

Compatible with docker-compose v2 schemas.

```
version: "2.1"
services:
  amd:
    image: randomninjaatk/amtd 
    container_name: amtd
    volumes:
      - /path/to/config/files:/config
      - /change/me/to/match/radarr:/change/me/to/match/radarr
    environment:
      - PUID=1000
      - PGID=1000
      - AUTOSTART=true
      - SCRIPTINTERVAL=1h
      - extrastype=all
      - LANGUAGES=en,de
      - videoformat=--format bestvideo[vcodec*=avc1]+bestaudio
      - subtitlelanguage=en
      - USEFOLDERS=false
      - SINGLETRAILER=true
      - PREFER_EXISTING=false
      - FilePermissions=644
      - FolderPermissions=755
      - RadarrUrl=http://x.x.x.x:7878
      - RadarrAPIkey=RADARRAPIKEY
      - EndClient=plex
    restart: unless-stopped
```

# Script Information
* Script will automatically run when enabled, if disabled, you will need to manually execute with the following command:
  * From Host CLI: `docker exec -it amtd /bin/bash -c 'bash /config/scripts/download.bash'`
  * From Docker CLI: `bash /config/scripts/download.bash`
  
## Directories:
* <strong>/config/scripts</strong>
  * Contains the scripts that are run
* <strong>/config/logs</strong>
  * Contains the log output from the script
* <strong>/config/cache</strong>
  * Contains the artist data cache to speed up processes
* <strong>/config/coookies</strong>
  * Store your cookies.txt file in this location, may be required for youtube-dl to work properly
  
  
<br />
<br />
<br />
  
 
# Credits
- [ffmpeg](https://ffmpeg.org/)
- [youtube-dl](https://ytdl-org.github.io/youtube-dl/index.html)
- [Radarr](https://radarr.video/)
- [The Movie Database](https://www.themoviedb.org/)
- Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>
