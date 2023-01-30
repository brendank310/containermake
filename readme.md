# containermake
`containermake` is a GNU make template for building containers with dependencies. It writes dummy files to `.containermake/` to track if a container needs rebuilding.

To use containermake, rename the Makefile to containermake.mk and add `include containermake.mk` to your makefile. Override the variables following variables:
```
CONTAINER_CLI?=docker # here for those who don't use podman
CONTAINERS?= \ # List of container names, e.g. nginx
	hello-world \
	goodnight-moon
DOCKER_PATH?=images # where your container files live
REGISTRY?=registry.dummy.io # your registry to push to?
TAG?=latest # Container tag, not git
```
