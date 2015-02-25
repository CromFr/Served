FROM binhex/arch-base
MAINTAINER cromfr@gmail.com

RUN pacman-db-upgrade \
	&& pacman -Syu --noconfirm \
	&& pacman-db-upgrade \
	&& pacman -S dmd dub wget unzip libevent --noconfirm \
	&& mkdir /etc/served

ADD . /opt/Served

RUN cd /opt/Served \
	&& ./setup.sh \
	&& dub build --compiler=dmd \
	&& cp config.json /etc/served
	

VOLUME /etc/served

EXPOSE 80

CMD cd /opt/Served && ./served /etc/served/served.conf
