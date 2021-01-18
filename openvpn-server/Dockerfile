FROM ubuntu:20.04

ARG DEBIAN_FRONTEND=noninteractive
ENV TZ=Europe/London

ARG SRV_CONF=./test_server.conf

# cd /usr/local/runme
WORKDIR /usr/local/runme

RUN apt-get update
RUN apt-get install -y openvpn nano unzip ufw easy-rsa iptables sudo 


# copy server configuration
COPY ${SRV_CONF} /etc/openvpn/test_server.conf

	


