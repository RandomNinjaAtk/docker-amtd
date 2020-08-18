# AMTD - Automated Movie Trailer Downloader 
![Docker Build](https://img.shields.io/docker/cloud/automated/randomninjaatk/amtd?style=flat-square)
![Docker Pulls](https://img.shields.io/docker/pulls/randomninjaatk/amtd?style=flat-square)
![Docker Stars](https://img.shields.io/docker/stars/randomninjaatk/amtd?style=flat-square)
[![Docker Hub](https://img.shields.io/badge/Open%20On-DockerHub-blue)](https://hub.docker.com/r/randomninjaatk/amtd)

[RandomNinjaAtk/amtd](https://github.com/RandomNinjaAtk/docker-amtd) is a Radarr companion script to automatically download movie trailers for use in other video applications (plex/kodi/jellyfin/emby) 

[![RandomNinjaAtk/amtd](https://raw.githubusercontent.com/RandomNinjaAtk/unraid-templates/master/randomninjaatk/img/amtd.png)](https://github.com/RandomNinjaAtk/docker-amtd)


## Features
* Downloading **Movie Trailers** using online sources for use in popular applications (Plex/Kodi/Emby/Jellyfin): 
  * Connects to Radarr to automatically download trailers for Movies in your existing library
  * Downloads trailers using youtube-dl automatically
  * Names trailers correctly to match Plex/Emby naming convention (Emby not tested)
  * Embeds relevant metadata into each trailer
  

### Plex Example
![](https://raw.githubusercontent.com/RandomNinjaAtk/docker-amtd/themoviedb/.github/amvtd-plex-example.jpg)


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
| `-e AUTOSTART="true"` | true = Enabled :: Runs script automatically on startup |
| `-e RadarrUrl="http://127.0.0.1:7878"` | Set domain or IP to your Radarr instance including port. If using reverse proxy, do not use a trailing slash. Ensure you specify http/s. |
| `-e RadarrAPIkey="08d108d108d108d108d108d108d108d1"` | Radarr API key. |
| `-e extrastype=all` | all or trailers :: all downloads all available videos (trailers, clips, featurette, etc...) :: trailers only downloads trailers |
| `-e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"` | For guidence, please see youtube-dl documentation |
| `-e subtitlelanguage=en` | Desired Language Code :: For guidence, please see youtube-dl documentation. |
| `-e FilePermissions=666` | Based on chmod linux permissions |

### docker

```
docker create \
  --name=amtd \
  -v /path/to/config/files:/config \
  -v /change/me/to/match/radarr:/change/me/to/match/radarr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e AUTOSTART=true \
  -e extrastype=all \
  -e videoformat="--format bestvideo[vcodec*=avc1]+bestaudio" \
  -e subtitlelanguage=en \
  -e FilePermissions=666 \
  -e RadarrUrl=http://127.0.0.1:7878 \
  -e RadarrAPIkey=RADARRAPIKEY \
  --restart unless-stopped \
  randomninjaatk/amtd 
```


### docker-compose

Compatible with docker-compose v2 schemas.

```
---
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
      - extrastype=all
      - videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"
      - subtitlelanguage=en
      - FilePermissions=666
      - RadarrUrl=http://127.0.0.1:7878
      - RadarrAPIkey=RADARRAPIKEY
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
<br />
  
 
# Credits
- [ffmpeg](https://ffmpeg.org/)
- [youtube-dl](https://ytdl-org.github.io/youtube-dl/index.html)
- [Radarr](https://radarr.video/)
- Icons made by <a href="http://www.freepik.com/" title="Freepik">Freepik</a> from <a href="https://www.flaticon.com/" title="Flaticon"> www.flaticon.com</a>
