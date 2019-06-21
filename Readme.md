# P2PD

## Goal

This application is supposed to be the backend server for the [p2pd ui](https://github.com/azryelryvel/p2pd-ui), but it 
should still be modular (no p2pd-ui special dependency).
It should roughly be able to download p2p data and allow them to seed, but more importantly, it should expose RPC 
methods for listing, adding and removing data from its queues.

## Building

To build this application, run :

```bash
cd /path/to/the/project
docker build -t p2pd-build .
docker run -v $(pwd):/usr/src/ -v ${HOME}/.gradle/wrapper:/root/.gradle/wrapper p2pd-build
```