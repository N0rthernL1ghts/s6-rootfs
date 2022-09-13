### S6-overlay rootfs

The simplest and fastest way to get S6 supervisor in your image

### Usage
```Docker
COPY --from=nlss/s6-rootfs:latest ["/", "/"]
```
or with fixed version:
```Docker
COPY --from=nlss/s6-rootfs:3.1.2.1 ["/", "/"]
```

That's it!

###### Recommended way to integrate with your image (example)
```Docker
# ---------------------
# Build root filesystem
# ---------------------
FROM scratch AS rootfs

# Copy over base files
COPY ["./rootfs", "/"]

# Install S6
COPY --from=nlss/s6-rootfs:3.1.2.1 ["/", "/"]


# ---------------------
# Build image
# ---------------------
FROM alpine:latest

COPY --from=rootfs ["/", "/"]
RUN apk add --update --no-cache nano
```

