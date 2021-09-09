FROM ubuntu:latest as build
ENV DEBIAN_FRONTEND=noninteractive
RUN set +ex && \
rm -f /etc/apt/sources.list && touch /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal main restricted" | tee /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security multiverse" | tee -a /etc/apt/sources.list
RUN set +ex && \
apt update && \
apt dist-upgrade -y && \
apt install -y autoconf automake autotools-dev binutils build-essential cython cython3 g++ git libc-ares-dev libcunit1-dev libev4 libev-dev libevent-dev libjansson-dev libjemalloc-dev libspdylay-dev libssl-dev libsystemd-dev libtool libxml2-dev make pkg-config python3.8-dev python3.8-distutils python3-dev python3-setuptools python-setuptools zlib1g-dev
RUN set +ex && \
git clone https://github.com/nghttp2/nghttp2.git && \
cd nghttp2 && \
git submodule update --init 
RUN set +ex && \
cd nghttp2 && \
autoreconf -i && \
automake && \
autoconf && \
./configure --enable-app  PYTHON_VERSION=3.8 && \
make -j $(nproc)

FROM ubuntu:latest as packetdrill
ENV DEBIAN_FRONTEND=noninteractive
RUN set +ex && \
rm -f /etc/apt/sources.list && touch /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal main restricted" | tee /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security multiverse" | tee -a /etc/apt/sources.list
RUN set +ex && \
apt update && \
apt dist-upgrade -y && \
apt install -y git bison flex binutils build-essential && \
git clone https://github.com/google/packetdrill.git && \
cd packetdrill/gtests/net/packetdrill && \
./configure && \
make -j $(nproc)

FROM ubuntu:latest as h2o-quicly
ENV DEBIAN_FRONTEND=noninteractive
RUN set +ex && \
rm -f /etc/apt/sources.list && touch /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal main restricted" | tee /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security multiverse" | tee -a /etc/apt/sources.list
RUN set +ex && \
apt update && \
apt dist-upgrade -y && \
apt install -y git binutils build-essential autoconf automake autotools-dev binutils cmake libssl-dev && \
git clone https://github.com/h2o/quicly.git && cd quicly && \
git submodule update --init --recursive && \
cmake . && \
make -j $(nproc)




FROM ubuntu:latest as oatpp
ENV DEBIAN_FRONTEND=noninteractive
RUN set +ex && \
rm -f /etc/apt/sources.list && touch /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal main restricted" | tee /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security multiverse" | tee -a /etc/apt/sources.list

RUN set +ex && \
apt update && \
apt dist-upgrade -y && \
apt install -y cmake build-essential git tree vim

RUN set +ex && \
git clone https://github.com/oatpp/benchmark-websocket.git && \
cd benchmark-websocket && \
sed 's/\<make\>/make -j $(nproc)/g' -i prepare.sh && \
bash prepare.sh && \
cd server/build/ && \
cmake .. && \
make -j $(nproc) && \
cd - && \
cd client/build/ && \
cmake .. && \
make -j $(nproc)



FROM rust:1.53.0 as oha
RUN set +ex && \
cargo install oha

FROM rust:1.53.0 as drill
RUN set +ex && \
cargo install drill

FROM rust:1.53.0 as feroxbuster
RUN set +ex && \
cargo install feroxbuster

FROM golang:1.16.6-buster as bombardier
RUN set +ex && \
go get -u github.com/codesenberg/bombardier

FROM golang:1.15-buster as ethr
RUN set +ex && \
apt update && apt install -y git && \
git clone https://github.com/Microsoft/ethr.git && \
cd ethr && \
mkdir /out && \
go build . && \
pwd && ls -alh

FROM golang:1.16.6-buster as fasthttploader
RUN set +ex && \
go get github.com/hagen1778/fasthttploader

FROM golang:1.16.6-buster as goloris
RUN set +ex && \
go get github.com/valyala/goloris


FROM golang:1.16.6-buster as hey
RUN set +ex && \
go get github.com/rakyll/hey


#yandex tank stack
#pandora

FROM golang:1.16.6-buster as pandora
RUN set +ex && \
apt update && apt install -y git && \
git clone https://github.com/yandex/pandora.git && \
cd pandora && \
make deps && \
go install


FROM ubuntu:latest
ENV DEBIAN_FRONTEND=noninteractive
RUN set +ex && \
rm -f /etc/apt/sources.list && touch /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal main restricted" | tee /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-updates multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://mirror.yandex.ru/ubuntu/ focal-backports main restricted universe multiverse" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security main restricted" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security universe" | tee -a /etc/apt/sources.list && \
echo "deb [arch=amd64] http://security.ubuntu.com/ubuntu focal-security multiverse" | tee -a /etc/apt/sources.list
RUN set -ex \
apt-get update && apt-get dist-upgrade -y && \
apt-get update && \
apt-get install -y git nmap curl wget apache2-utils libjemalloc-dev libev4 libssl-dev python3-pip strace iperf tree && \
pip3 install httpstat && \
wget -qP /usr/local/bin/rustbuster https://github.com/phra/rustbuster/releases/download/$(curl -s https://github.com/phra/rustbuster/releases | grep "rustbuster-v" | head -n1 | cut -d'/' -f6)/rustbuster-$(curl -s https://github.com/phra/rustbuster/releases | grep "rustbuster-v" | head -n1 | cut -d'/' -f6)-x86_64-unknown-linux-gnu && \
#python3-pip
rm -rf /var/lib/apt/lists/* 

#http load generators 
COPY --from=build /nghttp2/ /nghttp2/
COPY --from=oha /usr/local/cargo/bin/oha /usr/local/bin/oha
COPY --from=drill /usr/local/cargo/bin/drill /usr/local/bin/drill
COPY --from=bombardier /go/bin/bombardier /usr/local/bin/bombardier
COPY --from=fasthttploader /go/bin/fasthttploader /usr/local/bin/fasthttploader
COPY --from=goloris /go/bin/goloris /usr/local/bin/goloris
COPY --from=hey /go/bin/hey /usr/local/bin/hey
COPY --from=pandora /go/bin/pandora /usr/local/bin/pandora
COPY --from=pandora /go/pandora /pandora
COPY --from=h2o-quicly /quicly /quicly
#ab

#dir busters
COPY --from=feroxbuster /usr/local/cargo/bin/feroxbuster /usr/local/bin/feroxbuster
#rustbuster

#packet generators
COPY --from=ethr /go/ethr/ethr /usr/local/bin/ethr
COPY --from=packetdrill /packetdrill /packedrill
#ws
COPY --from=oatpp /benchmark-websocket/ /benchmark-websocket/

#
# apt-get install -y software-properties-common && \
# add-apt-repository -y ppa:deadsnakes/ppa && \
# apt-get update && \
# apt-get install -y python3.7 python3-pip && \

# pip3 install --upgrade pip && \

# pip3 install --upgrade setuptools && \
# apt-get install -y python3-software-properties && \ 
# python3.7 -m pip install https://api.github.com/repos/yandex/yandex-tank/tarball/master && \
# add-apt-repository -y ppa:yandex-load/main && \
# apt-get update &&  apt-get install -y phantom phantom-ssl && \

#&& apt-get install -y libjemalloc-dev libev4 openssl-dev && \
WORKDIR /nghttp2/src
RUN set +ex && \
./h2load -h && \
oha --version && \
fasthttploader --help && \
goloris --help && \
hey --help && \
drill --version && \
bombardier --version && \
pandora --version 

RUN set +ex && \
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
trivy filesystem --exit-code 0 -f json -o /results.json --no-progress /
