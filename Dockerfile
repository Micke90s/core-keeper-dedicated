###########################################################
# Dockerfile that builds a Core Keeper Gameserver
###########################################################
FROM debian:buster-slim

LABEL maintainer="leandro.martin@protonmail.com"
ARG PUID=1000

#cm2network/steamcmd
ENV USER steam
ENV HOMEDIR "/home/${USER}"
ENV STEAMCMDDIR "${HOMEDIR}/steamcmd"

#core-keeper-dedicated
ENV STEAMAPPID 1007
ENV STEAMAPPID_TOOL 1963720
ENV STEAMAPP core-keeper
ENV STEAMAPPDIR "${HOMEDIR}/${STEAMAPP}-dedicated"
ENV STEAMAPPDATADIR "${HOMEDIR}/${STEAMAPP}-data"
ENV DLURL https://raw.githubusercontent.com/escapingnetwork/core-keeper-dedicated

#cm2network/steamcmd
RUN set -x \
    && dpkg --add-architecture i386 \
    && apt-get update \
    && apt-get install -y --no-install-recommends --no-install-suggests \
        lib32stdc++6 \
        lib32gcc1 \
        wget \
        ca-certificates \
        nano \
        libsdl2-2.0-0:i386 \
        libcurl4 \
        curl \
        locales \
#core-keeper-dedicated
        mesa-utils \
        libx32gcc1 \
        build-essential \
        libxi6 \
        x11-utils \
# Installing xvfb direct from Debian Buster causes the Segmentation fault error
#        xvfb \
# The workaround by using Debian Bullseye causes a system freeze on Synology because of installed dependencies
     && echo "deb http://deb.debian.org/debian bullseye main" | tee /etc/apt/sources.list.d/bullseye.list \
     && apt-get update \
     && apt-get install -y --no-install-recommends --no-install-suggests -t bullseye xvfb \
#cm2network/steamcmd
    && sed -i -e 's/# en_US.UTF-8 UTF-8/en_US.UTF-8 UTF-8/' /etc/locale.gen \
    && dpkg-reconfigure --frontend=noninteractive locales \
    && useradd -u "${PUID}" -m "${USER}" \
        && su "${USER}" -c \
                "mkdir -p \"${STEAMCMDDIR}\" \
                && wget -qO- 'https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz' | tar xvzf - -C \"${STEAMCMDDIR}\" \
                && \"./${STEAMCMDDIR}/steamcmd.sh\" +quit \
                && mkdir -p \"${HOMEDIR}/.steam/sdk32\" \
                && ln -s \"${STEAMCMDDIR}/linux32/steamclient.so\" \"${HOMEDIR}/.steam/sdk32/steamclient.so\" \
        && ln -s \"${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam\" \
        && ln -s \"${STEAMCMDDIR}/steamcmd.sh\" \"${STEAMCMDDIR}/steam.sh\"" \
    && ln -s "${STEAMCMDDIR}/linux32/steamclient.so" "/usr/lib/i386-linux-gnu/steamclient.so" \
    && ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so" \
    && apt-get remove --purge -y \
        wget \
    && apt-get clean autoclean \
    && apt-get autoremove -y \
    && rm -rf /var/lib/apt/lists/*

#core-keeper-dedicated
COPY ./entry.sh ${HOMEDIR}/entry.sh
COPY ./launch.sh ${HOMEDIR}/launch.sh

#core-keeper-dedicated
RUN set -x \
    && mkdir -p "${STEAMAPPDIR}" \
    && mkdir -p "${STEAMAPPDATADIR}" \
    && chmod +x "${HOMEDIR}/entry.sh" \
    && chmod +x "${HOMEDIR}/launch.sh" \
    && chown -R "${USER}:${USER}" "${HOMEDIR}/entry.sh" "${HOMEDIR}/launch.sh" "${STEAMAPPDIR}" "${STEAMAPPDATADIR}"

RUN mkdir /tmp/.X11-unix \
    && chown -R "${USER}:${USER}" /tmp/.X11-unix

ENV WORLD_INDEX=0 \
    WORLD_NAME="Core Keeper Server" \
    WORLD_SEED=0 \
    WORLD_MODE=0 \
    GAME_ID="" \
    DATA_PATH="${STEAMAPPDATADIR}" \
    MAX_PLAYERS=10 \
    SEASON=-1 \
    SERVER_IP="" \
    SERVER_PORT=""

# Switch to user
USER ${USER}

# Switch to workdir
WORKDIR ${HOMEDIR}

VOLUME ${STEAMAPPDIR}

CMD ["bash", "entry.sh"]
