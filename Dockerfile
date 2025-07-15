FROM ubuntu:24.04 AS build
ENV DEBIAN_FRONTEND=noninteractive

# Install base build tools first (cacheable layer)
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git gcc g++ make binutils autoconf automake autotools-dev libtool \
        pkg-config ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install cmake separately (often changes)
RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake cmake-data && \
    rm -rf /var/lib/apt/lists/*

# Install nghttp2 dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        zlib1g-dev libev-dev libjemalloc-dev libc-ares-dev libssl-dev \
        libsystemd-dev libevent-dev libjansson-dev libxml2-dev python3-dev \
        libbrotli-dev && \
    rm -rf /var/lib/apt/lists/*

# Clone nghttp2 (separate step for better caching)
RUN git clone --depth 1 -b v1.64.0 https://github.com/nghttp2/nghttp2.git

# Build nghttp2 with minimal features for speed
RUN cd nghttp2 && \
    git submodule update --init --depth 1 && \
    autoreconf -i && \
    ./configure --enable-app \
        --disable-examples \
        --disable-hpack-tools \
        --disable-python-bindings \
        --disable-static \
        --disable-failmalloc \
        --disable-threads \
        CFLAGS="-O2" CXXFLAGS="-O2" && \
    make -j$(nproc) && \
    make install-strip && \
    ldconfig

FROM ubuntu:24.04 AS packetdrill
ENV DEBIAN_FRONTEND=noninteractive

# Install CA certificates first
RUN apt-get update && \
    apt-get install -y --no-install-recommends ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Install build tools
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git bison flex binutils build-essential && \
    rm -rf /var/lib/apt/lists/*

# Clone and build packetdrill
RUN git clone --depth 1 https://github.com/google/packetdrill.git && \
    cd packetdrill/gtests/net/packetdrill && \
    ./configure && \
    make -j$(nproc)

FROM ubuntu:24.04 AS h2o-quicly
ENV DEBIAN_FRONTEND=noninteractive

# Install base tools first
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates git binutils build-essential && \
    rm -rf /var/lib/apt/lists/*

# Install cmake and dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        autoconf automake autotools-dev cmake libssl-dev && \
    rm -rf /var/lib/apt/lists/*

# Clone and build quicly (build only cli target to avoid simulator segfault)
RUN git clone --depth 1 https://github.com/h2o/quicly.git && \
    cd quicly && \
    git submodule update --init --recursive --depth 1 && \
    cmake . -DCMAKE_BUILD_TYPE=Release && \
    make cli -j2




FROM ubuntu:24.04 AS oatpp
ENV DEBIAN_FRONTEND=noninteractive

# Install build tools separately for caching
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        ca-certificates git build-essential && \
    rm -rf /var/lib/apt/lists/*

RUN apt-get update && \
    apt-get install -y --no-install-recommends cmake && \
    rm -rf /var/lib/apt/lists/*

# Clone and build oatpp benchmark
# First install oatpp base library
RUN git clone --depth 1 https://github.com/oatpp/oatpp.git && \
    cd oatpp && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DOATPP_BUILD_TESTS=OFF && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf oatpp

# Then build oatpp-websocket
RUN git clone --depth 1 https://github.com/oatpp/oatpp-websocket.git && \
    cd oatpp-websocket && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release -DOATPP_BUILD_TESTS=OFF && \
    make -j$(nproc) && \
    make install && \
    cd ../.. && rm -rf oatpp-websocket

# Finally build the benchmark
RUN git clone --depth 1 https://github.com/oatpp/benchmark-websocket.git && \
    cd benchmark-websocket && \
    cd server && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc) && \
    cd ../../client && \
    mkdir build && cd build && \
    cmake .. -DCMAKE_BUILD_TYPE=Release && \
    make -j$(nproc)



FROM ubuntu:24.04 AS oha
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl && \
    curl -L https://github.com/hatoo/oha/releases/download/v1.4.5/oha-linux-amd64 -o /usr/local/bin/oha && \
    chmod +x /usr/local/bin/oha

FROM ubuntu:24.04 AS drill
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl && \
    curl -L https://github.com/fcsonline/drill/releases/download/0.8.3/drill-x86_64-unknown-linux-gnu -o /usr/local/bin/drill && \
    chmod +x /usr/local/bin/drill

FROM ubuntu:24.04 AS feroxbuster
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl unzip && \
    curl -L https://github.com/epi052/feroxbuster/releases/download/v2.10.4/x86_64-linux-feroxbuster.zip -o feroxbuster.zip && \
    unzip feroxbuster.zip -d /usr/local/bin && \
    chmod +x /usr/local/bin/feroxbuster && \
    rm feroxbuster.zip

FROM ubuntu:24.04 AS bombardier
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl && \
    curl -L https://github.com/codesenberg/bombardier/releases/download/v1.2.6/bombardier-linux-amd64 -o /usr/local/bin/bombardier && \
    chmod +x /usr/local/bin/bombardier

FROM ubuntu:24.04 AS ethr
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates wget unzip && \
    wget https://github.com/microsoft/ethr/releases/latest/download/ethr_linux.zip && \
    unzip ethr_linux.zip && \
    chmod +x ethr && \
    mv ethr /usr/local/bin/

# fasthttploader removed

FROM golang:1.13-buster AS goloris
RUN set +ex && \
GOOS=linux GOARCH=amd64 CGO_ENABLED=0 go get -u github.com/valyala/goloris

FROM ubuntu:24.04 AS hey
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates curl && \
    curl -L https://hey-release.s3.us-east-2.amazonaws.com/hey_linux_amd64 -o /usr/local/bin/hey && \
    chmod +x /usr/local/bin/hey

FROM golang:1.23-bookworm AS pandora
RUN apt-get update && apt-get install -y --no-install-recommends git make && \
    git clone --depth 1 https://github.com/yandex/pandora.git && \
    cd pandora && \
    go mod download && \
    go build -o /go/bin/pandora .

FROM ubuntu:24.04 AS tools
ENV DEBIAN_FRONTEND=noninteractive

# Copy all tools into this stage
COPY --from=build /usr/local/bin/h2load /usr/local/bin/h2load
COPY --from=build /usr/local/bin/nghttp /usr/local/bin/nghttp
COPY --from=build /usr/local/bin/nghttpd /usr/local/bin/nghttpd
COPY --from=build /usr/local/bin/nghttpx /usr/local/bin/nghttpx
COPY --from=oha /usr/local/bin/oha /usr/local/bin/oha
COPY --from=drill /usr/local/bin/drill /usr/local/bin/drill
COPY --from=bombardier /usr/local/bin/bombardier /usr/local/bin/bombardier
COPY --from=goloris /go/bin/goloris /usr/local/bin/goloris
COPY --from=hey /usr/local/bin/hey /usr/local/bin/hey
COPY --from=pandora /go/bin/pandora /usr/local/bin/pandora
COPY --from=h2o-quicly /quicly /quicly
COPY --from=feroxbuster /usr/local/bin/feroxbuster /usr/local/bin/feroxbuster
COPY --from=ethr /usr/local/bin/ethr /usr/local/bin/ethr
COPY --from=packetdrill /packetdrill /packedrill
COPY --from=oatpp /benchmark-websocket/ /benchmark-websocket/

# Download additional tools
RUN apt-get update && apt-get install -y --no-install-recommends wget ca-certificates && \
    wget -q https://github.com/phra/rustbuster/releases/download/v3.0.3/rustbuster-v3.0.3-x86_64-unknown-linux-gnu -O /usr/local/bin/rustbuster && \
    chmod +x /usr/local/bin/rustbuster || true && \
    rm -rf /var/lib/apt/lists/*

FROM ubuntu:24.04 AS test
ENV DEBIAN_FRONTEND=noninteractive

# Install runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        libjemalloc-dev libev4 libssl3 ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Copy all tools from tools stage
COPY --from=tools /usr/local/bin/ /usr/local/bin/
COPY --from=tools /quicly /quicly
COPY --from=tools /packedrill /packedrill
COPY --from=tools /benchmark-websocket/ /benchmark-websocket/

# Test all tools
WORKDIR /
RUN set +ex && \
echo "==============h2load==============" && \
h2load -h && \
echo "==============oha==============" && \
oha --version && \
echo "==============goloris==============" && \
goloris --help && \
echo "==============hey==============" && \
hey --help && \
echo "==============drill==============" && \
drill --version && \
echo "==============bombardier==============" && \
bombardier --version && \
echo "==============pandora==============" && \
pandora --version

FROM ubuntu:24.04
ENV DEBIAN_FRONTEND=noninteractive

# Install all runtime dependencies
RUN apt-get update && \
    apt-get install -y --no-install-recommends \
        git nmap curl wget apache2-utils libjemalloc-dev libev4 libssl3 \
        python3-pip pipx strace iperf tree ca-certificates && \
    pipx install httpstat && \
    rm -rf /var/lib/apt/lists/*

# Make pipx binaries available in PATH
ENV PATH="/root/.local/bin:${PATH}"

# Copy all tools from tools stage
COPY --from=tools /usr/local/bin/ /usr/local/bin/
COPY --from=tools /quicly /quicly
COPY --from=tools /packedrill /packedrill
COPY --from=tools /benchmark-websocket/ /benchmark-websocket/

# Install trivy for security scanning
RUN set +ex && \
curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin && \
trivy filesystem --exit-code 0 -f json -o /results.json --no-progress /

WORKDIR /
