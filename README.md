# load-bench
This Dockerfile provide image, that contains following tools 
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

apache2-benchmark, and also strace
With those tools you able to generate loads such as 
- packets
- (http|https) CRUD, and somethiung specific
- QUIC
- websockets
  - actually client and server too
