### S6-overlay rootfs

The simplest and fastest way to get S6 supervisor in your image

### Usage
```Docker
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:latest ["/", "/"]
```
or with fixed version:
```Docker
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:3.1.2.1 ["/", "/"]
```

That's it!

Note: We have moved to `ghcr.io`. Docker hub `docker.io/nlss/s6-rootfs` builds are discontinued.<br/>

###### Recommended way to integrate with your image (example)
```Docker
# ---------------------
# Build root filesystem
# ---------------------
FROM scratch AS rootfs

# Copy over base files
COPY ["./rootfs", "/"]

# Install S6
COPY --from=ghcr.io/n0rthernl1ghts/s6-rootfs:3.1.2.1 ["/", "/"]


# ---------------------
# Build image
# ---------------------
FROM alpine:latest

COPY --from=rootfs ["/", "/"]
RUN apk add --update --no-cache nano

# S6 configuration - not required
# See: https://github.com/just-containers/s6-overlay#customizing-s6-overlay-behaviour
ENV S6_KEEP_ENVS6_KEEP_ENV=1
ENV S6_BEHAVIOUR_IF_STAGE2_FAILS=2
ENV S6_CMD_RECEIVE_SIGNALS=1

# Important, this is required for S6 to work
ENTRYPOINT ["/init"]
```
