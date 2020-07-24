FROM ubuntu:bionic

COPY ./bootnode /bin/

WORKDIR /root
# INFO: booknode.key can be obtained by "/bin/bootnode -genkey bootnode.key"
COPY ./bootnode.key .

CMD /bin/bootnode -nodekey bootnode.key

EXPOSE 30301/udp
EXPOSE 30303/udp
