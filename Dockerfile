FROM lsiobase/ubuntu:focal
LABEL maintainer="RandomNinjaAtk"

ENV TITLE="Automated Music Video Downloader"
ENV VERSION="1.0.0"
ENV MBRAINZMIRROR="https://musicbrainz.org"
ENV SMA_PATH /usr/local/sma

RUN \
	echo "************ install dependencies ************" && \
	echo "************ install packages ************" && \
	apt-get update -y && \
	apt-get install -y --no-install-recommends \
		wget \
		nano \
		unzip \
		git \
		jq \
		python3 \
		python3-pip \
		ffmpeg \
		mkvtoolnix \
		cron && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* && \
	echo "************ install youtube-dl ************" && \
	curl -L https://yt-dl.org/downloads/latest/youtube-dl -o /usr/local/bin/youtube-dl && \
	chmod a+rx /usr/local/bin/youtube-dl && \
	echo "************ install mp4 tagging software ************" && \
	pip3 install --no-cache-dir -U \
		mutagen && \
	echo "************ setup SMA ************" && \
	echo "************ setup directory ************" && \
	mkdir -p ${SMA_PATH} && \
	echo "************ download repo ************" && \
	git clone https://github.com/mdhiggins/sickbeard_mp4_automator.git ${SMA_PATH} && \
	mkdir -p ${SMA_PATH}/config && \
	echo "************ create logging file ************" && \
	mkdir -p ${SMA_PATH}/config && \
	touch ${SMA_PATH}/config/sma.log && \
	chgrp users ${SMA_PATH}/config/sma.log && \
	chmod g+w ${SMA_PATH}/config/sma.log && \
	echo "************ install pip dependencies ************" && \
	python3 -m pip install --user --upgrade pip && \	
	pip3 install -r ${SMA_PATH}/setup/requirements.txt

WORKDIR /

# copy local files
COPY root/ /

# ports and volumes
VOLUME /config
