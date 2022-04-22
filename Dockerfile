FROM lsiobase/ubuntu:focal
LABEL maintainer="RandomNinjaAtk"

ENV TITLE="Automated Movie Trailer Downloader (AMTD)"
ENV TITLESHORT="AMTD"
ENV VERSION="1.0.8"

RUN \
	echo "************ install dependencies ************" && \
	echo "************ install & upgrade packages ************" && \
	apt-get update -y && \
	apt-get upgrade -y && \
	apt-get install -y --no-install-recommends \
		curl \
		jq \
		gcc \
		libc6-dev \
		python3 \
		python3-pip \
		python3-dev \
		g++ \
		ffmpeg \
		mkvtoolnix && \
	rm -rf \
		/tmp/* \
		/var/lib/apt/lists/* \
		/var/tmp/* && \
	echo "************ install python packages ************" && \
	python3 -m pip install --no-cache-dir -U \
		mutagen \
		yt-dlp

# copy local files
COPY root/ /

# set work directory
WORKDIR /config

# ports and volumes
VOLUME /config
