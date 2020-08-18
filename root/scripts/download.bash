#!/usr/bin/with-contenv bash

Configuration () {
	processstartid="$(ps -A -o pid,cmd|grep "start.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	processdownloadid="$(ps -A -o pid,cmd|grep "download.bash" | grep -v grep | head -n 1 | awk '{print $1}')"
	echo "To kill script, use the following command:"
	echo "kill -9 $processstartid"
	echo "kill -9 $processdownloadid"
	echo ""
	echo ""
	sleep 5
	echo "############################################ SCRIPT VERSION 1.0.1"
	echo "############################################ DOCKER VERSION $VERSION"
	echo "############################################ CONFIGURATION VERIFICATION"
	themoviedbapikey="3b7751e3179f796565d88fdb2fcdf426"
	error=0

	#Verify Radarr Connectivity
	radarrtest=$(curl -s "$RadarrUrl/api/v3/system/status?apikey=${RadarrAPIkey}" | jq -r ".version")
	if [ ! -z "$radarrtest" ]; then
		if [ "$radarrtest" != "null" ]; then
			echo "Radarr: Connection Valid, version: $radarrtest"
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

	radarrmovielist=$(curl -s --header "X-Api-Key:"${RadarrAPIkey} --request GET  "$RadarrUrl/api/movie")
	radarrmovietotal=$(echo "${radarrmovielist}"  | jq -r '.[].id' | wc -l)
	radarrmovieids=($(echo "${radarrmovielist}" | jq -r ".[].id"))
	
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

	echo "youtube-dl: Checking for cookies.txt"
	if [ -f "/config/cookies/cookies.txt" ]; then
		echo "youtube-dl: /config/cookies/cookies.txt found!"
		cookies="--cookies /config/cookies/cookies.txt"
	else
		echo "WARNING: youtube-dl cookies.txt not found at the following location: /config/cookies/cookies.txt"
		echo "WARNING: not having cookies may result in failed downloads..."
		cookies=""
	fi

	# videoformat
	if [ ! -z "$videoformat" ]; then
		echo "Radarr Trailer Format Set To: $videoformat"
	else
		echo "Radarr Trailer Format Set To: --format bestvideo[vcodec*=avc1]+bestaudio"
		videoformat="--format bestvideo[vcodec*=avc1]+bestaudio"
	fi

	# extrastype
	if [ ! -z "$extrastype" ]; then
		echo "Radarr Extras Selection: $extrastype"
	else
		echo "WARNING: Radarr Extras Selection not specified"
		echo "Radarr Extras Selection: trailers"
		extrastype="trailers"
	fi

	# subtitlelanguage
	if [ ! -z "$subtitlelanguage" ]; then
		subtitlelanguage="${subtitlelanguage,,}"
		echo "Radarr Trailer Subtitle Language: $subtitlelanguage"
	else
		subtitlelanguage="en"
		echo "Radarr Trailer Subtitle Language: $subtitlelanguage"
	fi

	if [ ! -z "$FilePermissions" ]; then
		echo "Radarr Trailer File Permissions: $FilePermissions"
	else
		echo "ERROR: FilePermissions not set, using default..."
		FilePermissions="666"
		echo "Radarr Trailer File Permissions: $FilePermissions"
	fi

	if [ $error == 1 ]; then
		echo "ERROR :: Exiting..."
		exit 1
	fi
	sleep 5
}

DownloadTrailers () {
	echo "############################################ DOWNLOADING TRAILERS"
	for id in ${!radarrmovieids[@]}; do
		currentprocessid=$(( $id + 1 ))
		radarrid="${radarrmovieids[$id]}"
		radarrmoviedata="$(echo "${radarrmovielist}" | jq -r ".[] | select(.id==$radarrid)")"
		radarrmoviecredit="$(curl -s --header "X-Api-Key:"${RadarrAPIkey} --request GET  "$RadarrUrl/api/v3/credit?movieId=$radarrid")"
		radarrmoviedirector="$(echo "${radarrmoviecredit}" | jq -r ".[] | select(.job==\"Director\") | .personName"  | head -n 1)"
		radarrmovietitle="$(echo "${radarrmoviedata}" | jq -r ".title")"
		radarrmovieyear="$(echo "${radarrmoviedata}" | jq -r ".year")"
		radarrmoviepath="$(echo "${radarrmoviedata}" | jq -r ".path")"
		radarrmoviegenre="$(echo "${radarrmoviedata}" | jq -r ".genres | .[]" | head -n 1)"
		radarrmoviefolder="$(basename "${radarrmoviepath}")"
		radarrmoviecertification="$(echo "${radarrmoviedata}" | jq -r ".certification")"
		radarrmovieoverview="$(echo "${radarrmoviedata}" | jq -r ".overview")"
		radarrmovieostudio="$(echo "${radarrmoviedata}" | jq -r ".studio")"
		themoviedbmovieid="$(echo "${radarrmoviedata}" | jq -r ".tmdbId")"
		if [ ! -d "$radarrmoviepath" ]; then
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: ERROR: Movie Path does not exist ($radarrmovietitle), Skipping..."
			continue
		fi
		echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle"
		themoviedbvideoslistdata=$(curl -s "https://api.themoviedb.org/3/movie/${themoviedbmovieid}/videos?api_key=${themoviedbapikey}&language=$subtitlelanguage")
		if [ "$extrastype" == "all" ]; then
			themoviedbvideoslistids=($(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$subtitlelanguage\") | .id"))
		else
			themoviedbvideoslistids=($(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$subtitlelanguage\" and .type==\"Trailers\") | .id"))
		fi
		themoviedbvideoslistidscount=$(echo "$themoviedbvideoslistdata" | jq -r ".results[] |  select(.site==\"YouTube\" and .iso_639_1==\"$subtitlelanguage\") | .id" | wc -l)
		if [ -z "$themoviedbvideoslistids" ]; then
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: ERROR: No Trailer ID Found ($radarrmovietitle), Skipping..."
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
		find "$radarrmoviepath" -maxdepth 1 -type f -iname "*-trailer.mkv" -delete

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
			sanatizethemoviedbvidename="$(echo "${themoviedbvidename}" | sed -e 's/[\\/:\*\?"<>\|\x01-\x1F\x7F]//g' -e 's/^\(nul\|prn\|con\|lpt[0-9]\|com[0-9]\|aux\)\(\.\|$\)//i' -e 's/^\.*$//' -e 's/^$/NONAME/')"
			if [ "$themoviedbvidetype" == "Featurette" ]; then
				folder="Featurettes"
			elif [ "$themoviedbvidetype" == "Trailer" ]; then
				folder="Trailers"
			elif [ "$themoviedbvidetype" == "Behind the Scenes" ]; then
				folder="Behind The Scenes"
			elif [ "$themoviedbvidetype" == "Clip" ]; then
				folder="Scenes"
			elif [ "$themoviedbvidetype" == "Bloopers" ]; then
				folder="Shorts"
			elif [ "$themoviedbvidetype" == "Teaser" ]; then
				folder="Trailers"
			fi
			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename"

			if [ -f "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" ]; then
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Trailer already Downloaded..."
				continue
			fi

			if [ ! -d "$radarrmoviepath/$folder" ]; then
				mkdir -p "$radarrmoviepath/$folder"
				chmod $FilePermissions "$radarrmoviepath/$folder"
				chown abc:abc "$radarrmoviepath/$folder"
			fi


			echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Sending Trailer link to youtube-dl..."
			echo "=======================START YOUTUBE-DL========================="
			python3 /usr/local/bin/youtube-dl ${cookies} -o "$radarrmoviepath/$folder/$sanatizethemoviedbvidename" ${videoformat} --write-sub --sub-lang $subtitlelanguage --embed-subs --merge-output-format mkv --no-mtime --geo-bypass "$youtubeurl"
			echo "========================STOP YOUTUBE-DL========================="
			if [ -f "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" ]; then
				audiochannels="$(ffprobe -v quiet -print_format json -show_streams "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" | jq -r ".[] | .[] | select(.codec_type==\"audio\") | .channels")"
				width="$(ffprobe -v quiet -print_format json -show_streams "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .width")"
				height="$(ffprobe -v quiet -print_format json -show_streams "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" | jq -r ".[] | .[] | select(.codec_type==\"video\") | .height")"
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
					-i "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" \
					-frames:v 1 \
					-vf "scale=640:-2" \
					"$radarrmoviepath/$folder/cover.jpg"
				echo "========================STOP FFMPEG========================="
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Updating File Statistics via mkvtoolnix (mkvpropedit)..."
				echo "========================START MKVPROPEDIT========================"
				mkvpropedit "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" --add-track-statistics-tags
				echo "========================STOP MKVPROPEDIT========================="
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Embedding metadata with ffmpeg..."
				echo "========================START FFMPEG========================"
				mv "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" "$radarrmoviepath/$folder/temp.mkv"
				ffmpeg -y \
					-i "$radarrmoviepath/$folder/temp.mkv" \
					-c copy \
					-metadata TITLE="${themoviedbvidename}" \
					-metadata DATE_RELEASE="$radarrmovieyear" \
					-metadata GENRE="$radarrmoviegenre" \
					-metadata COPYRIGHT="$radarrmovieostudio" \
					-metadata ENCODED_BY="AMTD" \
					-metadata CONTENT_TYPE="Movie $folder" \
					-metadata:s:v:0 title="$qualitydescription" \
					-metadata:s:a:0 title="$audiodescription" \
					-attach "$radarrmoviepath/$folder/cover.jpg" -metadata:s:t mimetype=image/jpeg \
					"$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv"
				echo "========================STOP FFMPEG========================="
				if [ -f "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv" ]; then
					echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: Metadata Embedding Complete!"
					if [ -f "$radarrmoviepath/$folder/temp.mkv" ]; then
						rm "$radarrmoviepath/$folder/temp.mkv"
					fi
				else
					echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER :: ERROR: Metadata Embedding Failed!"
					mv "$radarrmoviepath/$folder/temp.mkv" "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv"
				fi
				if [ -f "$radarrmoviepath/$folder/cover.jpg" ]; then
					rm "$radarrmoviepath/$folder/cover.jpg"
				fi
				chmod $FilePermissions "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv"
				chown abc:abc "$radarrmoviepath/$folder/$sanatizethemoviedbvidename.mkv"
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: Complete!"
			else
				echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $currentsubprocessid of $themoviedbvideoslistidscount :: $folder :: $themoviedbvidename :: TRAILER DOWNLOAD :: ERROR :: Skipping..."
			fi
		done
		trailercount="$(find "$radarrmoviepath" -mindepth 2 -type f -iname "*.mkv" | wc -l)"
		echo "$currentprocessid of $radarrmovietotal :: $radarrmovietitle :: $trailercount Extras Downloaded!"
	done
	trailercount="$(find "$radarrmovierootpath" -mindepth 3 -type f -iname "*.mkv" | wc -l)"
	echo "############################################ $trailercount TRAILERS DOWNLOADED"
	echo "############################################ SCRIPT COMPLETE"

}

Configuration
DownloadTrailers
exit 0
