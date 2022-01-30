group "default" {
  targets = ["2.1.0.2", "2.2.0.0", "2.2.0.1", "2.2.0.2", "2.2.0.3", "3.0.0.0"]
}

target "build-dockerfile" {
  dockerfile = "Dockerfile"
}

target "build-dockerfile-legacy" {
  dockerfile = "Dockerfile.legacy"
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/armhf", "linux/aarch64"]
}

target "build-common" {
  pull = true
}

target "2.1.0.2" {
  inherits = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/s6-rootfs:2.1.0.2", "docker.io/nlss/s6-rootfs:2.1"]
  args = {
    S6_OVERLAY_VERSION = "2.1.0.2"
  }
}

target "2.2.0.0" {
  inherits = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/s6-rootfs:2.2.0.0"]
  args = {
    S6_OVERLAY_VERSION = "2.2.0.0"
  }
}

target "2.2.0.1" {
  inherits = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/s6-rootfs:2.2.0.1"]
  args = {
    S6_OVERLAY_VERSION = "2.2.0.1"
  }
}

target "2.2.0.2" {
  inherits = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/s6-rootfs:2.2.0.2"]
  args = {
    S6_OVERLAY_VERSION = "2.2.0.2"
  }
}

target "2.2.0.3" {
  inherits = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/s6-rootfs:2.2.0.3", "docker.io/nlss/s6-rootfs:2.2"]
  args = {
    S6_OVERLAY_VERSION = "2.2.0.3"
  }
}

target "3.0.0.0" {
  inherits = ["build-dockerfile", "build-platforms", "build-common"]
  tags     = ["docker.io/nlss/s6-rootfs:3.0.0.0", "docker.io/nlss/s6-rootfs:3.0.0.0-1", "docker.io/nlss/s6-rootfs:3.0", "docker.io/nlss/s6-rootfs:latest"]
  args = {
    S6_OVERLAY_VERSION = "3.0.0.0-1"
  }
}