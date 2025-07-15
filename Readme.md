<div align="center">
	<br>
	<div>
		<img height="300" src="https://raw.githubusercontent.com/docker-library/docs/471fa6e4cb58062ccbf91afc111980f9c7004981/swarm/logo.png" alt="Docker Swarm">
	</div>
	<br>
	<br>
  <h1>lukaskorl/swarm-wrapper</h1>
  <p>
    <sup>
      Run containers in Swarm while using Compose features
    </sup>
  </p>
	<br>
	<br>
	<br>
	<br>
	<br>
	<br>
	<br>
	<br>
</div>

> `lukaskorl/swarm-wrapper` is a container for running other containers with Docker Compose on a swarm node with access to features like devices which are not available to Swarm Mode.

[![License](https://img.shields.io/badge/License-Apache_2.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)

## Goals of `lukaskorl/swarm-wrapper`

- Temporarily overcome limitations of Swarm Mode
- Access to hardware devices on Swarm node (i.e. USB devices)
  - Personal use-case is running a [ser2net](https://github.com/jippi/docker-ser2net) container in a Docker Swarm

## Usage

For testing purposes run this image with a Compose file mounted or attached as a secret to `/compose.yml`:

```sh
# Using mount
docker run --rm -it \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ./demo/docker-compose.yml:/compose.yml:ro \
	lukaskorl/swarm-wrapper
```

### Advanced networking

This container includes a socat proxy for usage in Swarm mode. It can proxy TCP traffic to another container.

```sh
docker run --rm -it \
	-v /var/run/docker.sock:/var/run/docker.sock \
	-v ./demo/docker-compose.yml:/compose.yml:ro \
	-e PROXY_TARGET=host.docker.internal:8088 \
	-p 8080:8080 \
	lukaskorl/swarm-wrapper
```

In this scenario the `whoami` container is exposed on port `8088` directly by the compose stack. And on port `8080` through the proxy. Check the output by running `curl http://localhost:8080` and `curl http://localhost:8088`.

## Attribution

This container has been develop from an idea of [js-home.org](https://www.js-home.org/2022/10/docker-swarm-die-2.-mit-usb/) originating from a discussion on the [Swarmkit](https://github.com/moby/swarmkit/issues/1244) repo.

<br>
<br>

<img src="https://upload.wikimedia.org/wikipedia/commons/7/70/Docker_logo.png" height="20"/>

###### Docker is a registered trademarks of Docker, Inc. This project is not affiliated with Docker, Inc.
