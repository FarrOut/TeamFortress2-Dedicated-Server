FROM centos

# To workaround....
# Error: Failed to download metadata for repo 'appstream': Cannot prepare internal mirrorlist: No URLs in mirrorlist
#
# https://forketyfork.medium.com/centos-8-no-urls-in-mirrorlist-error-3f87c3466faa
# https://stackoverflow.com/questions/70930615/no-urls-in-mirrorlist-with-yum-on-centos-due-to-appstream
RUN sed -i -e "s|mirrorlist=|#mirrorlist=|g" /etc/yum.repos.d/CentOS-* && \
    sed -i -e "s|#baseurl=http://mirror.centos.org|baseurl=http://vault.centos.org|g" /etc/yum.repos.d/CentOS-*

RUN yum update -y && \
    yum install -y glibc.i686 libstdc++.i686

# Create and switch to the steam user
USER steam:steamers

# Create a directory for SteamCMD and switch to it.
RUN mkdir /home/steam/SteamCMD
WORKDIR /home/steam/SteamCMD

# Download and extract SteamCMD for Linux.
RUN curl -sqL "https://steamcdn-a.akamaihd.net/client/installer/steamcmd_linux.tar.gz" | tar zxvf -