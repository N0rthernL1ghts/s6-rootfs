group "default" {
  targets = ["2_1_0_2", "2_2_0_0", "2_2_0_1", "2_2_0_2", "2_2_0_3", "3_0_0_0", "3_0_0_1", "3_0_0_2", "3_0_0_2-2", "3_1_0_0", "3_1_0_1", "3_1_1_0", "3_1_1_1", "3_1_1_2", "3_1_2_0", "3_1_2_1", "3_1_3_0", "3_1_4_0", "3_1_4_1", "3_1_4_2"]
}

target "build-dockerfile" {
  dockerfile = "Dockerfile"
}

target "build-dockerfile-legacy" {
  dockerfile = "Dockerfile.legacy"
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/aarch64"]
}

target "build-common" {
  pull = true
}

variable "REGISTRY_CACHE" {
  default = "docker.io/nlss/s6-rootfs-cache"
}

######################
# Define the functions
######################

# Get the arguments for the build
function "get-args" {
  params = [version]
  result = {
    S6_OVERLAY_VERSION = version
  }
}

# Get the arguments for the build
function "get-args-with-pak-ext" {
  params = [version, pak_ext]
  result = {
    S6_OVERLAY_VERSION = version
    S6_OVERLAY_PAK_EXT = pak_ext
  }
}

# Get the cache-from configuration
function "get-cache-from" {
  params = [version]
  result = [
    "type=gha,scope=${version}_${BAKE_LOCAL_PLATFORM}",
    "type=registry,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get the cache-to configuration
function "get-cache-to" {
  params = [version]
  result = [
    "type=gha,mode=max,scope=${version}_${BAKE_LOCAL_PLATFORM}",
    "type=registry,mode=max,ref=${REGISTRY_CACHE}:${sha1("${version}-${BAKE_LOCAL_PLATFORM}")}"
  ]
}

# Get list of image tags and registries
# Takes a version and a list of extra versions to tag
# eg. get-tags("3.1.4.1", ["3.1", "latest"])
function "get-tags" {
  params = [version, extra_versions]
  result = concat(
    [
      "docker.io/nlss/s6-rootfs:${version}",
      "ghcr.io/n0rthernl1ghts/s6-rootfs:${version}"
    ],
    flatten([
      for extra_version in extra_versions : [
        "docker.io/nlss/s6-rootfs:${extra_version}",
        "ghcr.io/n0rthernl1ghts/s6-rootfs:${extra_version}"
      ]
    ])
  )
}

##########################
# Define the build targets
##########################

target "2_1_0_2" {
  inherits   = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  cache-from = get-cache-from("2.1.0.2")
  cache-to   = get-cache-to("2.1.0.2")
  tags       = get-tags("2.1.0.2", ["2.1"])
  args       = get-args("2.1.0.2")
}

target "2_2_0_0" {
  inherits   = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  cache-from = get-cache-from("2.2.0.0")
  cache-to   = get-cache-to("2.2.0.0")
  tags       = get-tags("2.2.0.0", [])
  args       = get-args("2.2.0.0")
}

target "2_2_0_1" {
  inherits   = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  cache-from = get-cache-from("2.2.0.1")
  cache-to   = get-cache-to("2.2.0.1")
  tags       = get-tags("2.2.0.1", [])
  args       = get-args("2.2.0.1")
}

target "2_2_0_2" {
  inherits   = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  cache-from = get-cache-from("2.2.0.2")
  cache-to   = get-cache-to("2.2.0.2")
  tags       = get-tags("2.2.0.2", [])
  args       = get-args("2.2.0.2")
}

target "2_2_0_3" {
  inherits   = ["build-dockerfile-legacy", "build-platforms", "build-common"]
  cache-from = get-cache-from("2.2.0.3")
  cache-to   = get-cache-to("2.2.0.3")
  tags       = get-tags("2.2.0.3", ["2.2"])
  args       = get-args("2.2.0.3")
}

target "3_0_0_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.0.0.0-1")
  cache-to   = get-cache-to("3.0.0.0-1")
  tags       = get-tags("3.0.0.0", ["3.0.0.0-1"])
  args       = get-args-with-pak-ext("3.0.0.0-1", "-3.0.0.0-1.tar.xz")
}

target "3_0_0_1" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.0.0.1")
  cache-to   = get-cache-to("3.0.0.1")
  tags       = get-tags("3.0.0.1", [])
  args       = get-args-with-pak-ext("3.0.0.1", "-3.0.0.1.tar.xz")
}

target "3_0_0_2" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.0.0.2")
  cache-to   = get-cache-to("3.0.0.2")
  tags       = get-tags("3.0.0.2", [])
  args       = get-args-with-pak-ext("3.0.0.2", "-3.0.0.2.tar.xz")
}

target "3_0_0_2-2" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.0.0.2-2")
  cache-to   = get-cache-to("3.0.0.2-2")
  tags       = get-tags("3.0.0.2-2", ["3.0"])
  args       = get-args-with-pak-ext("3.0.0.2-2", "-3.0.0.2-2.tar.xz")
}

target "3_1_0_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.0.0")
  cache-to   = get-cache-to("3.1.0.0")
  tags       = get-tags("3.1.0.0", [])
  args       = get-args("3.1.0.0")
}

target "3_1_0_1" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.0.1")
  cache-to   = get-cache-to("3.1.0.1")
  tags       = get-tags("3.1.0.1", ["3.1.0"])
  args       = get-args("3.1.0.1")
}

target "3_1_1_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.1.0")
  cache-to   = get-cache-to("3.1.1.0")
  tags       = get-tags("3.1.1.0", [])
  args       = get-args("3.1.1.0")
}

target "3_1_1_1" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.1.1")
  cache-to   = get-cache-to("3.1.1.1")
  tags       = get-tags("3.1.1.1", [])
  args       = get-args("3.1.1.1")
}

target "3_1_1_2" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.1.2")
  cache-to   = get-cache-to("3.1.1.2")
  tags       = get-tags("3.1.1.2", ["3.1", "3.1.1"])
  args       = get-args("3.1.1.2")
}

target "3_1_2_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.2.0")
  cache-to   = get-cache-to("3.1.2.0")
  tags       = get-tags("3.1.2.0", [])
  args       = get-args("3.1.2.0")
}

target "3_1_2_1" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.2.1")
  cache-to   = get-cache-to("3.1.2.1")
  tags       = get-tags("3.1.2.1", ["3.1.2"])
  args       = get-args("3.1.2.1")
}

target "3_1_3_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.3.0")
  cache-to   = get-cache-to("3.1.3.0")
  tags       = get-tags("3.1.3.0", ["3.1.3"])
  args       = get-args("3.1.3.0")
}

target "3_1_4_0" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.4.0")
  cache-to   = get-cache-to("3.1.4.0")
  tags       = get-tags("3.1.4.0", [])
  args       = get-args("3.1.4.0")
}

target "3_1_4_1" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.4.1")
  cache-to   = get-cache-to("3.1.4.1")
  tags       = get-tags("3.1.4.1", [])
  args       = get-args("3.1.4.1")
}

target "3_1_4_2" {
  inherits   = ["build-dockerfile", "build-platforms", "build-common"]
  cache-from = get-cache-from("3.1.4.2")
  cache-to   = get-cache-to("3.1.4.2")
  tags       = get-tags("3.1.4.2", ["3.1", "3.1.4", "latest"])
  args       = get-args("3.1.4.2")
}
