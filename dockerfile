FROM ubuntu:18.04
ENV USER=root
#images and vnc password
ENV PASSWORD=123456
ENV DEBIAN_FRONTEND=noninteractive 
ENV DEBCONF_NONINTERACTIVE_SEEN=true
#change sources
RUN sed -i "s/ports.ubuntu./mirrors.aliyun./g" /etc/apt/sources.list
#copy local bc/BORLANDC to images /home/dos/bc31, dosbox will mount /home/dos as c:
COPY bc/BORLANDC /home/dos/bc31
#copy user defined dosbox config
COPY dosbox.bc31.conf  /home/projects/dosbox.bc31.conf
RUN apt-get update && \
	echo "tzdata tzdata/Areas select America" > ~/tx.txt && \
	echo "tzdata tzdata/Zones/America select New York" >> ~/tx.txt && \
	debconf-set-selections ~/tx.txt && \
	apt-get install -y tightvncserver ratpoison dosbox novnc websockify && \
	mkdir ~/.vnc/ && \
	mkdir ~/.dosbox && \	
	mv  /home/projects/dosbox.bc31.conf ~/.dosbox/dosbox.bc31.conf &&\
	echo $PASSWORD | vncpasswd -f > ~/.vnc/passwd && \
	chmod 0600 ~/.vnc/passwd && \
	echo "set border 0" > ~/.ratpoisonrc  && \
	echo "exec dosbox -conf ~/.dosbox/dosbox.bc31.conf -fullscreen  -c 'C:'">> ~/.ratpoisonrc && \
	export DOSCONF=$(dosbox -printconf) && \
	cp $DOSCONF ~/.dosbox/dosbox.conf && \
	sed -i 's/usescancodes=true/usescancodes=false/' ~/.dosbox/dosbox.conf && \
	openssl req -x509 -nodes -newkey rsa:2048 -keyout ~/novnc.pem -out ~/novnc.pem -days 3650 -subj "/C=US/ST=NY/L=NY/O=NY/OU=NY/CN=NY emailAddress=email@example.com"
EXPOSE 80
CMD vncserver && websockify -D --web=/usr/share/novnc/ --cert=~/novnc.pem 80 localhost:5901 && tail -f /dev/null
