# load-bench
This Dockerfile provide image, that contains following tools
## With those tools you able to generate loads such as 
- packets
- (http|https) CRUD, and somethiung specific
- QUIC
- websockets
  - actually client and server too

---
## http load generators
- build 
- oha 
- drill 
- bombardier 
- fasthttploader 
- goloris 
- hey 
- pandora 
- pandora 
- h2o-quicly 
## dir busters
- feroxbuster 
- rustbuster

## packet generators
- ethr 
- packetdrill 
## ws
- oatpp 
## QUIC
- h2o/quicly

## system packages
- apache2-benchmark
- strace
- libjemalloc
- iperf

---
# For futher advanced scenarios consider using
https://k6.io/
https://yandex.ru/dev/tank/
https://jmeter.apache.org/
https://gatling.io
or some libraries like
https://github.com/mhjort/clj-gatling
