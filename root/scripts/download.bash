#!/usr/bin/with-contenv bash

Configuration () {
	processstartid="$(ps -A -o pid,cmd|grep "start.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	processdownloadid="$(ps -A -o pid,cmd|grep "download.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	echo "To kill script, use the following command:"
	echo "kill -9 $processstartid"
	echo "kill -9 $processdownloadid"
	echo ""
	echo ""
	sleep 2
	echo "############################################ $TITLE"
	echo "############################################ SCRIPT VERSION 1.2.81"
	echo "############################################ DOCKER VERSION $VERSION"
	echo "############################################ CONFIGURATION VERIFICATION"
	themoviedbapikey="3b7751e3179f796565d88fdb2fcdf426"
	error=0
	
	if [ "$AUTOSTART" == "true" ]; then
		echo "$TITLESHORT Script Autostart: ENABLED"
		if [ -z "$SCRIPTINTERVAL" ]; then
			echo "WARNING: $TITLESHORT Script Interval not set! Using default..."
			SCRIPTINTERVAL="15m"
		fi
		echo "$TITLESHORT Script Interval: $SCRIPTINTERVAL"
	else
		echo "$TITLESHORT Script Autostart: DISABLED"
	fi
	
	#Verify Radarr Connectivity using v0.2 and v3 API url
	radarrtestv02=$(curl -s "$RadarrUrl/api/system/status?apikey=${RadarrAPIkey}" | jq -r ".version")
	radarrtestv3=$(curl -s "$RadarrUrl/api/v3/system/status?apikey=${RadarrAPIkey}" | jq -r ".version")
	if [ ! -z "$radarrtestv02" ] || [ ! -z "$radarrtestv3" ] ; then
		if [ "$radarrtestv02" != "null" ]; then
			echo "Radarr v0.2 API: Connection Valid, version: $radarrtestv02"
		elif [ "$radarrtestv3" != "null" ]; then
			echo "Radarr v3 API: Connection Valid, version: $radarrtestv3"
		else
			echo "ERROR: Cannot communicate with Radarr, most likely a...."
			echo "ERROR: Invalid API Key: $RadarrAPIkey"
			error=1
		fi
	else
		echo "ERROR: Cannot communicate with Radarr, no response"
		echo "ERROR: URL: $RadarrUrl"
		echo "ERROR: API Key: $RadarrAPIkey"
		error=1
	fi

	radarrmovielist=$(curl -s --header "X-Api-Key:"${RadarrAPIkey} --request GET  "$RadarrUrl/api/v3/movie")
	radarrmovietotal=$(echo "${radarrmovielist}"  | jq -r '.[] | select(.hasFile==true) | .id' | wc -l)
	radarrmovieids=($(echo "${radarrmovielist}" | jq -r '.[] | select(.hasFile==true) | .id'))
	
	echo "Radarr: Verifying Movie Directory Access:"
	for id in ${!radarrmovieids[@]}; do
		currentprocessid=$(( $id + 1 ))
		radarrid="${radarrmovieids[$id]}"
		radarrmoviedata="$(echo "${radarrmovielist}" | jq -r ".[] | select(.id==$radarrid)")"
		radarrmoviepath="$(echo "${radarrmoviedata}" | jq -r ".path")"
		radarrmovierootpath="$(dirname "$radarrmoviepath")"
		if [ -d "$radarrmovierootpath" ]; then
			echo "Radarr: Root Media Folder Found: $radarrmovierootpath"
			error=0
			break
		else
			echo "ERROR: Radarr Root Media Folder not found, please verify you have the right volume configured, expecting path:"
			echo "ERROR: Expected volume path: $radarrmovierootpath"
			error=1
			break
		fi
	done
	
	# extrastype
	if [ ! -z "$extrastype" ]; then
		echo "Radarr Extras Selection: $extrastype"
	else
		echo "WARNING: Radarr Extras Selection not specified"
		echo "Radarr Extras Selection: trailers"
		extrastype="trailers"
	fi
	
	# LANGUAGES
	if [ ! -z "$LANGUAGES" ]; then
		LANGUAGES="${LANGUAGES,,}"
		echo "Radarr Extras Audio Languages: $LANGUAGES (first one found is used)"
	else
		LANGUAGES="en"
		echo "Radarr Extras Audio Languages: $LANGUAGES (first one found is used)"
	fi
	
	# videoformat
	if [ ! -z "$videoformat" ]; then
		echo "Radarr Extras Format Set To: $videoformat"
	else
		echo "Radarr Extras Format Set To: --format bestvideo[vcodec*=avc1]+bestaudio"
		videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"
	fi
	

	# subtitlelanguage
	if [ ! -z "$subtitlelanguage" ]; then
		subtitlelanguage="${subtitlelanguage,,}"
		echo "Radarr Extras Subtitle Language: $subtitlelanguage"
	else
		subtitlelanguage="en"
		echo "Radarr Extras Subtitle Language: $subtitlelanguage"
	fi

	if [ ! -z "$FilePermissions" ]; then
		echo "Radarr Extras File Permissions: $FilePermissions"
	else
		echo "ERROR: FilePermissions not set, using default..."
		FilePermissions="666"
		echo "Radarr Extras File Permissions: $FilePermissions"
	fi
	
	if [ ! -z "$FolderPermissions" ]; then
		echo "Radarr Extras Foldder Permissions: $FolderPermissions"
	else
		echo "WARNING: FolderPermissions not set, using default..."
		FolderPermissions="766"
		echo "Radarr Extras Foldder Permissions: $FolderPermissions"
	fi
	
	if [ ! -z "$SINGLETRAILER" ]; then
		if [ "$SINGLETRAILER" == "true" ]; then
			echo "Radarr Single Trailer: ENABLED"
		else
			echo "Radarr Single Trailer: DISABLED"
		fi
	else
		echo "WARNING: SINGLETRAILER not set, using default..."
		SINGLETRAILER="true"
		echo "Radarr Single Trailer: ENABLED"
	fi
	
	if [ ! -z "$USEFOLDERS" ]; then
		if [ "$USEFOLDERS" == "true" ]; then
			echo "Radarr Use Extras Folders: ENABLED"
			if [ "$EndClient" == "plex" ]; then
				echo "Extras Folders configured for Plex compatibility (end_client=$EndClient)"
			elif [ "$EndClient" == "emby" ]; then
				echo "Extras Folders configured for Emby compatibility (end_client=$EndClient)"
			elif [ "$EndClient" == "jellyfin" ]; then
				echo "Extras Folders configured for Jellyfin compatibility (end_client=$EndClient)"
			else
				EndClient=plex
				echo "WARNING: EndClient not set, using default..."
				echo "Extras Folders configured for Plex compatibility (end_client=$EndClient)"
			fi
			
		else
			echo "Radarr Use Extras Folders: DISABLED"
		fi
	else
		echo "WARNING: USEFOLDERS not set, using default..."
		USEFOLDERS="false"
		echo "Radarr Use Extras Folders: DISABLED"
	fi

	if [ ! -z "$PREFER_EXISTING" ]; then
		if [ "$PREFER_EXISTING" == "true" ]; then
			echo "Prefer Existing Trailer: ENABLED"
		else
			echo "Prefer Existing Trailer: DISABLED"
		fi
	else
		echo "WARNING: PREFER_EXISTING not set, using default..."
		PREFER_EXISTING="false"
		echo "Prefer Existing Trailer: DISABLED"
	fi

	if [ $error == 1 ]; then
		echo "ERROR :: Exiting..."
		exit 1
	fi
	sleep 2.5
}

DownloadTrailers () {
	echo "############################################ DOWNLOADING TRAILERS"
	for id in ${!radarrmovieids[@]}; do
		currentprocessid=$(( $id + 1 ))
		radarrid="${radarrmovieids[$id]}"
		radarrmoviedata="$(echo "${radarrmovielist}" | jq -r ".[] | select(.id==$radarrid)")"
		radarrmovietitle="$(echo "${radarrmoviedata}" | jq -r ".title")"
		themoviedbmovieid="$(echo "${radarrmoviedata}" | jq -r ".tmdbId")"
		if [ -f "/config/cache/${themoviedbmovieid}-complete" ]; then
			if [[ $(find "/config/cache/${themoviedbmovieid}-complete" -mtime +7 -print) ]]; then
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: Checking for changes..."
				rm "/config/cache/${themoviedbmovieid}-complete"
			else
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: All videos already downloaded, skipping..."
				continue
			fi
		fi
		radarrmoviepath="$(echo "${radarrmoviedata}" | jq -r ".path")"
		if [ ! -d "$radarrmoviepath" ]; then
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: ERROR: Movie Path does not exist, Skipping..."
			continue
		fi
		radarrmovieyear="$(echo "${radarrmoviedata}" | jq -r ".year")"
		radarrmoviegenre="$(echo "${radarrmoviedata}" | jq -r ".genres | .[]" | head -n 1)"
		radarrmoviefolder="$(basename "${radarrmoviepath}")"
		radarrmovieostudio="$(echo "${radarrmoviedata}" | jq -r ".studio")"		
		echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle"
		
		
		IFS=',' read -r -a filters <<< "$LANGUAGES"
		for filter in "${filters[@]}"
		do
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: Searching for \"$filter\" extras..."
			themoviedbvideoslistdata=$(curl -s "https://api.themoviedb.org/3/movie/${themoviedbmovieid}/videos?api_key=${themoviedbapikey}&language=$filter")
			if [ "$extrastype" == "all" ]; then
				themoviedbvideoslistids=($(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$filter\") | .id"))
			else
				themoviedbvideoslistids=($(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$filter\" and .type==\"Trailer\") | .id"))
			fi
			themoviedbvideoslistidscount=$(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$filter\") | .id" | wc -l)
			if [ -z "$themoviedbvideoslistids" ]; then
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: None found..."
				continue
			else
				break
			fi
		done
		
		if [ -z "$themoviedbvideoslistids" ]; then
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: ERROR: No Extras in wanted languages found, Skipping..."
			if [ -f "/config/logs/NotFound.log" ]; then
				if cat "/config/logs/NotFound.log" | grep -i ":: $radarrmovietitle ::" | read; then
					sleep 0.1
				else
					echo "No Trailer Found :: $radarrmovietitle :: themoviedb missing Youtube Trailer ID"  >> "/config/logs/NotFound.log"
				fi
			else
				echo "No Trailer Found :: $radarrmovietitle :: themoviedb Missing Youtube Trailer ID"  >> "/config/logs/NotFound.log"
			fi
			continue
		fi

		echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $themoviedbvideoslistidscount Extras Found!"
		for id in ${!themoviedbvideoslistids[@]}; do
			currentsubprocessid=$(( $id + 1 ))
			themoviedbvideoid="${themoviedbvideoslistids[$id]}"
			themoviedbvideodata="$(echo "$themoviedbvideoslistdata" | jq -r ".results[] | select(.id==\"$themoviedbvideoid\") | .")"
			themoviedbvidelanguage="$(echo "$themoviedbvideodata" | jq -r ".iso_639_1")"
			themoviedbvidecountry="$(echo "$themoviedbvideodata" | jq -r ".iso_3166_1")"
			themoviedbvidekey="$(echo "$themoviedbvideodata" | jq -r ".key")"
			themoviedbvidename="$(echo "$themoviedbvideodata" | jq -r ".name")"
			themoviedbvidetype="$(echo "$themoviedbvideodata" | jq -r ".type")"
			youtubeurl="https://www.youtube.com/watch?v=$themoviedbvidekey"
			sanatizethemoviedbvidename="$(echo "${themoviedbvidename}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g'  -e "s/  */ /g")"
								
			if [ "$themoviedbvidetype" == "Featurette" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					if [ "$EndClient" == "jellyfin" ]; then
						folder="featurettes"
					else
						folder="Featurettes"
					fi
				else
					folder="Featurette"
				fi
			elif [ "$themoviedbvidetype" == "Trailer" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					if [ "$EndClient" == "jellyfin" ]; then
						folder="trailers"
					else
						folder="Trailers"
					fi
				else
					folder="Trailer"
				fi
			elif [ "$themoviedbvidetype" == "Behind the Scenes" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					if [ "$EndClient" == "jellyfin" ]; then
						folder="behind the scenes"
					else
						folder="Behind The Scenes"
					fi
				else
					folder="Behind The Scenes"
				fi
			elif [ "$themoviedbvidetype" == "Clip" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					if [ "$EndClient" == "jellyfin" ]; then
						folder="scenes"
					else
						folder="Scenes"
					fi
				else
					folder="Scene"
				fi
			elif [ "$themoviedbvidetype" == "Bloopers" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					if [ "$EndClient" == "jellyfin" ]; then
						folder="shorts"
					else
						folder="Shorts"
					fi
				else
					folder="Short"
				fi
			elif [ "$themoviedbvidetype" == "Teaser" ]; then
				if [ "$USEFOLDERS" == "true" ]; then
					if [ "$EndClient" == "jellyfin" ]; then
						folder="extras"
					else
						folder="Other"
					fi
				else
					folder="Other"
				fi
			fi				
			
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename"
			
			if [ "$USEFOLDERS" == "true" ]; then
				if [ "$SINGLETRAILER" == "true" ]; then
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						if find "$radarrmoviepath/$folder" -name "*.mkv" | read; then
							echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Trailer found, skipping..."
							continue
						fi
					fi
				fi
				if [ "$PREFER_EXISTING" == "true" ]; then
					# Check for existing manual trailer
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						if find "$radarrmoviepath/$folder" -name "*.*" | read; then
							echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Manual Trailer found, skipping..."
							continue
						fi
					fi
				fi
				outputfile="$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv"
			else
				if [[ -d "$radarrmoviepath/${folder}s" || -d "$radarrmoviepath/${folder}" ]]; then
					if [ "$themoviedbvidetype" == "Behind the Scenes" ]; then
						rm -rf "$radarrmoviepath/${folder}"
					else
						rm -rf "$radarrmoviepath/${folder}s"
					fi
				fi
				folder="$(echo "${folder,,}" | sed 's/ *//g')"
				if [ "$SINGLETRAILER" == "true" ]; then
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						if find "$radarrmoviepath" -name "*-trailer.mkv" | read; then
							echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Trailer found, skipping..."
							continue
						fi
					fi
				fi

				if [ "$PREFER_EXISTING" == "true" ]; then
					if [ "$themoviedbvidetype" == "Trailer" ]; then
						# Check for existing manual trailer
						if find "$radarrmoviepath" -name "*-trailer.*" | read; then
							echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Existing Manual Trailer found, skipping..."
							continue
						fi
					fi
				fi
				outputfile="$radarrmoviepath/$sanatizethemoviedbvidename-$folder.mkv"
			fi			
			
			if [ -f "$outputfile" ]; then
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Trailer already Downloaded..."
				continue
			fi
			
			if [ ! -d "/config/temp" ]; then
				mkdir -p /config/temp
			else
				rm -rf /config/temp
				mkdir -p /config/temp
			fi
			tempfile="/config/temp/download"

			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Sending Trailer link to youtube-dl..."
			echo "=======================START YOUTUBE-DL========================="
			yt-dlp -o "$tempfile" ${videoformat} --write-sub --sub-lang $subtitlelanguage --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "$youtubeurl"
			echo "========================STOP YOUTUBE-DL========================="
			if [ -f "$tempfile.mkv" ]; then
				audiochannels="$(ffprobe -v quiet -print_format json -show_streams "$tempfile.mkv" | jq -r ".[] | .[] | select(.codec_type==\"audio\") | .channels")"
				width="$(ffprobe -v quiet -print_format json -show_streams "$tempfile.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .width")"
				height="$(ffprobe -v quiet -print_format json -show_streams "$tempfile.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .height")"
				if [[ "$width" -ge "3800" || "$height" -ge "2100" ]]; then
					videoquality=3
					qualitydescription="UHD"
				elif [[ "$width" -ge "1900" || "$height" -ge "1060" ]]; then
					videoquality=2
					qualitydescription="FHD"
				elif [[ "$width" -ge "1260" || "$height" -ge "700" ]]; then
					videoquality=1
					qualitydescription="HD"
				else
					videoquality=0
					qualitydescription="SD"
				fi

				if [ "$audiochannels" -ge "3" ]; then
					channelcount=$(( $audiochannels - 1 ))
					audiodescription="${audiochannels}.1 Channel"
				elif [ "$audiochannels" == "2" ]; then
					audiodescription="Stereo"
				elif [ "$audiochannels" == "1" ]; then
					audiodescription="Mono"
				fi

				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER DOWNLOAD :: Complete!"
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Extracting thumbnail with ffmpeg..."
				echo "========================START FFMPEG========================"
				ffmpeg -y \
					-ss 10 \
					-i "$tempfile.mkv" \
					-frames:v 1 \
					-vf "scale=640:-2" \
					"/config/temp/cover.jpg"
				echo "========================STOP FFMPEG========================="
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Updating File Statistics via mkvtoolnix (mkvpropedit)..."
				echo "========================START MKVPROPEDIT========================"
				mkvpropedit "$tempfile.mkv" --add-track-statistics-tags
				echo "========================STOP MKVPROPEDIT========================="
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Embedding metadata with ffmpeg..."
				echo "========================START FFMPEG========================"
				mv "$tempfile.mkv" "$tempfile-temp.mkv"
				ffmpeg -y \
					-i "$tempfile-temp.mkv" \
					-c copy \
					-metadata TITLE="${themoviedbvidename}" \
					-metadata DATE_RELEASE="$radarrmovieyear" \
					-metadata GENRE="$radarrmoviegenre" \
					-metadata COPYRIGHT="$radarrmovieostudio" \
					-metadata ENCODED_BY="AMTD" \
					-metadata CONTENT_TYPE="Movie $folder" \
					-metadata:s:v:0 title="$qualitydescription" \
					-metadata:s:a:0 title="$audiodescription" \
					-attach "/config/temp/cover.jpg" -metadata:s:t mimetype=image/jpeg \
					"$tempfile.mkv"
				echo "========================STOP FFMPEG========================="
				if [ -f "$tempfile.mkv" ]; then
					echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Metadata Embedding Complete!"
					if [ -f "$tempfile-temp.mkv" ]; then
						rm "$tempfile-temp.mkv"
					fi
				else
					echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: ERROR: Metadata Embedding Failed!"
					mv "$tempfile-temp.mkv" "$tempfile.mkv"
				fi
				
				if [ -f "$tempfile.mkv" ]; then
					if [ "$USEFOLDERS" == "false" ]; then
						mv "$tempfile.mkv" "$outputfile"
						chmod $FilePermissions "$outputfile"
						chown abc:abc "$outputfile"
					else
						if [ ! -d "$radarrmoviepath/$folder" ]; then
							mkdir -p "$radarrmoviepath/$folder"
							chmod $FolderPermissions "$radarrmoviepath/$folder"
							chown abc:abc "$radarrmoviepath/$folder"
						fi
						if [ -d "$radarrmoviepath/$folder" ]; then
							mv "$tempfile.mkv" "$outputfile"
							chmod $FilePermissions "$outputfile"
							chown abc:abc "$outputfile"
						fi
					fi
				fi
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Complete!"
			else
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER DOWNLOAD :: ERROR :: Skipping..."
			fi
			
			if [ -d "/config/temp" ]; then
				rm -rf /config/temp
			fi
		done
		if [ "$USEFOLDERS" == "true" ]; then
			trailercount="$(find "$radarrmoviepath" -mindepth 2 -type f -iname "*.mkv" | wc -l)"
		else
			trailercount="$(find "$radarrmoviepath" -mindepth 1 -type f -regex '.*\(-trailer.mkv\|-scene.mkv\|-short.mkv\|-featurette.mkv\|-other.mkv\|-behindthescenes.mkv\)' | wc -l)"
		fi
		
		echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $trailercount Extras Downloaded!"
		if [ "$trailercount" -ne "0" ]; then
			touch "/config/cache/${themoviedbmovieid}-complete"
		fi
	done
	if [ "$USEFOLDERS" == "true" ]; then
		trailercount="$(find "$radarrmovierootpath" -mindepth 3 -type f -iname "*.mkv" | wc -l)"
	else
		trailercount="$(find "$radarrmovierootpath" -mindepth 2 -type f -regex '.*\(-trailer.mkv\|-scene.mkv\|-short.mkv\|-featurette.mkv\|-other.mkv\|-behindthescenes.mkv\)' | wc -l)"
	fi
	echo "############################################ $trailercount TRAILERS DOWNLOADED"
	echo "############################################ SCRIPT COMPLETE"
	if [ "$AUTOSTART" == "true" ]; then
		echo "############################################ SCRIPT SLEEPING FOR $SCRIPTINTERVAL"
	fi
}

Configuration
DownloadTrailers

exit 0
