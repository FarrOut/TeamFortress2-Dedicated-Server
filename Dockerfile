FROM centos

LABEL maintainer="farr.gs@gmail.com"

ENV STEAMAPPID 232250
ENV STEAMAPP tf

# To workaround....
# Error: Failed to download metadata for repo 'appstream': Cannot prepare internal mirrorlist: No URLs in mirrorlist
#
# https://forketyfork.medium.com/centos-8-no-urls-in-mirrorlist-error-3f87c3466faa
# https://stackoverflow.com/questions/70930615/no-urls-in-mirrorlist-with-yum-on-centos-due-to-appstream
RUN sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-* && \
    sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*

RUN dnf update -y && \
    dnf install -y glibc.i686 libstdc++.i686 \
    # Install tmux and/or screen for easy server management
    tmux libgcc.x86_64 libgcc.i686 glibc.i686 \
    libstdc++.x86_64 libstdc++.i686 ncurses-libs.i686 libcurl.i686 \
    centos-release-stream

# Create and switch to the steam user
ENV USER steam
ENV HOMEDIR "/home/${USER}"
RUN groupadd steamers
RUN useradd --create-home --shell /bin/bash "${USER}"
USER steam:steamers

# Create a directory for Steam and switch to it.
ENV STEAMCMDDIR "${HOMEDIR}/steamcmd"
RUN mkdir "${STEAMCMDDIR}"
RUN mkdir -p "~/.steam/sdk32"
WORKDIR "${STEAMCMDDIR}"
RUN ln -s "${STEAMCMDDIR}/linux32/steamclient.so" "${HOMEDIR}/.steam/sdk32/steamclient.so"
RUN ln -s "${STEAMCMDDIR}/linux32/steamclient.so" "/usr/lib/i386-linux-gnu/steamclient.so"
RUN ln -s "${STEAMCMDDIR}/linux64/steamclient.so" "/usr/lib/x86_64-linux-gnu/steamclient.so"
RUN ln -s "${STEAMCMDDIR}/linux32/steamcmd\" \"${STEAMCMDDIR}/linux32/steam"

# Download and extract SteamCMD for Linux.
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -

# Download game
ENV STEAMAPPDIR "/home/steam/${STEAMAPP}-dedicated"
RUN mkdir -p "${STEAMAPPDIR}" || true
WORKDIR "${STEAMAPPDIR}"
RUN "/home/steam/SteamCMD/steamcmd.sh" +force_install_dir "${STEAMAPPDIR}" \
				+login anonymous \
				+app_update "${STEAMAPPID}" \
				+quit

# Launch game server
ENV SRCDS_MAXPLAYERS=32 \
    SRCDS_PORT=27015 \
    SRCDS_TV_PORT=27020 \
    SRCDS_TICKRATE=66 \
    SRCDS_FPSMAX=300

WORKDIR "${STEAMAPPDIR}"
RUN ln -s ./hlserver/tf2/bin ~/.steam/sdk32
CMD "${STEAMAPPDIR}/srcds_run -game \"${STEAMAPP}\" -console -autoupdate " \
    "-steam_dir \"${STEAMCMDDIR}\"" \
    "-steamcmd_script \"${HOMEDIR}/${STEAMAPP}_update.txt\"" \
    "-usercon" \
    "+fps_max \"${SRCDS_FPSMAX}\"" \
    "-tickrate \"${SRCDS_TICKRATE}\"" \
    "-port \"${SRCDS_PORT}\"" \
    "+tv_port \"${SRCDS_TV_PORT}\"" \
    "--debug"


#CMD ["${STEAMAPPDIR}/srcds_run", "-game \"${STEAMAPP}\"", "-console", "-autoupdate",
#                        " -steam_dir \"${STEAMCMDDIR}\"",
#                        "-steamcmd_script \"${HOMEDIR}/${STEAMAPP}_update.txt\"",
#                        "-usercon",
#                        "+fps_max \"${SRCDS_FPSMAX}\"",
#                        "-tickrate \"${SRCDS_TICKRATE}\"",
#                        "-port \"${SRCDS_PORT}\"",
#                        "+tv_port \"${SRCDS_TV_PORT}\"",
##                        +clientport "${SRCDS_CLIENT_PORT}" \
#                        "+maxplayers \"${SRCDS_MAXPLAYERS}\"",
##                        +map "${SRCDS_STARTMAP}" \
##                        +sv_setsteamaccount "${SRCDS_TOKEN}" \
##                        +rcon_password "${SRCDS_RCONPW}" \
##                        +sv_password "${SRCDS_PW}" \
##                        +sv_region "${SRCDS_REGION}" \
##                        -ip "${SRCDS_IP}" \
##                        -authkey "${SRCDS_WORKSHOP_AUTHKEY}"
#                         "--debug"]


# Expose ports
EXPOSE  27015/tcp \
	    27015/udp \
	    27020/udp


### References ###
# Pre-Fortress 2: Linux Dedicated Server Setup
# https://steamcommunity.com/sharedfiles/filedetails/?id=2737475433

# Dedicated server configuration
# https://wiki.teamfortress.com/wiki/Dedicated_server_configuration

# TF2 Dedicated Server Setup Guide (Detailed)
# https://steamcommunity.com/sharedfiles/filedetails/?id=285509230

# How to make a Team Fortress 2 Dedicated Server (srcds)
# https://steamcommunity.com/sharedfiles/filedetails/?id=1877365208

# cm2network/tf2
# https://github.com/CM2Walki/TF2/blob/master/etc/entry.sh

