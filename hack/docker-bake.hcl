variable "REGISTRY" {
  default = "ghcr.io/n0rthernl1ghts/s6-rootfs"
}

variable "REGISTRY_CACHE" {
  default = "ghcr.io/n0rthernl1ghts/s6-rootfs-cache"
}

variable "S6_VERSIONS" {
  default = {
    # Legacy 2.x releases (use Dockerfile.legacy)
    "2.1.0.2"   = { legacy = true, extra_tags = ["2.1"] }
    "2.2.0.0"   = { legacy = true, extra_tags = [] }
    "2.2.0.1"   = { legacy = true, extra_tags = [] }
    "2.2.0.2"   = { legacy = true, extra_tags = [] }
    "2.2.0.3"   = { legacy = true, extra_tags = ["2.2"] }

    # 3.0.x releases with custom package extensions
    "3.0.0.0"   = { overlay_version = "3.0.0.0-1", pak_ext = "-3.0.0.0-1.tar.xz", extra_tags = ["3.0.0.0-1"] }
    "3.0.0.1"   = { pak_ext = "-3.0.0.1.tar.xz", extra_tags = [] }
    "3.0.0.2"   = { pak_ext = "-3.0.0.2.tar.xz", extra_tags = [] }
    "3.0.0.2-2" = { pak_ext = "-3.0.0.2-2.tar.xz", extra_tags = ["3.0"] }

    # 3.1.x releases
    "3.1.0.0"   = { extra_tags = [] }
    "3.1.0.1"   = { extra_tags = ["3.1.0"] }
    "3.1.1.0"   = { extra_tags = [] }
    "3.1.1.1"   = { extra_tags = [] }
    "3.1.1.2"   = { extra_tags = ["3.1", "3.1.1"] }
    "3.1.2.0"   = { extra_tags = [] }
    "3.1.2.1"   = { extra_tags = ["3.1.2"] }
    "3.1.3.0"   = { extra_tags = ["3.1.3"] }
    "3.1.4.0"   = { extra_tags = [] }
    "3.1.4.1"   = { extra_tags = [] }
    "3.1.4.2"   = { extra_tags = ["3.1.4"] }
    "3.1.5.0"   = { extra_tags = ["3.1.5"] }
    "3.1.6.0"   = { extra_tags = [] }
    "3.1.6.1"   = { extra_tags = [] }
    "3.1.6.2"   = { extra_tags = ["3.1", "3.1.6"] }

    # 3.2.x releases
    "3.2.0.0"   = { extra_tags = [] }
    "3.2.0.1"   = { extra_tags = [] }
    "3.2.0.2"   = { extra_tags = [] }
    "3.2.0.3"   = { extra_tags = ["3.2.0"] }
    "3.2.1.0"   = { extra_tags = ["3.2.1"] }
    "3.2.2.0"   = { extra_tags = ["3.2.2"] }
    "3.2.3.0"   = { extra_tags = [] }
    "3.2.3.1"   = { extra_tags = [] }
    "3.2.3.2"   = { extra_tags = ["3.2", "3.2.3", "latest"] }
  }
}

variable "LATEST_VERSION" {
  default = "3.2.3.2"
}

group "default" {
  targets = [replace(LATEST_VERSION, ".", "_")]
}

group "all" {
  targets = ["s6-rootfs"]
}

target "build-platforms" {
  platforms = ["linux/amd64", "linux/aarch64"]
}

target "build-common" {
  pull = true
}

# Generic cache-from function
function "get-cache-from" {
  params = [registry, version]
  result = [
    "type=registry,ref=${registry}:cache-${version}"
  ]
}

# Generic cache-to function
function "get-cache-to" {
  params = [registry, version]
  result = [
    "type=registry,mode=max,ref=${registry}:cache-${version}"
  ]
}

# Generic tags generation function
function "get-tags" {
  params = [image_name, version, extra_tags]
  result = concat(
    [ "${image_name}:${version}" ],
    flatten([
      for tag in extra_tags : [ "${image_name}:${tag}" ]
    ])
  )
}

# Build arguments function
function "get-args" {
  params = [version, pak_ext]
  result = pak_ext != "" ? {
    S6_OVERLAY_VERSION = version
    S6_OVERLAY_PAK_EXT = pak_ext
  } : {
    S6_OVERLAY_VERSION = version
  }
}

target "s6-rootfs" {
  name = replace(version, ".", "_")
  matrix = {
    version = keys(S6_VERSIONS)
  }

  inherits   = ["build-platforms", "build-common"]
  dockerfile = try(S6_VERSIONS[version].legacy, false) ? "Dockerfile.legacy" : "Dockerfile"

  tags       = get-tags(REGISTRY, version, try(S6_VERSIONS[version].extra_tags, []))
  args       = get-args(try(S6_VERSIONS[version].overlay_version, version), try(S6_VERSIONS[version].pak_ext, ""))

  cache-from = get-cache-from(REGISTRY_CACHE, try(S6_VERSIONS[version].overlay_version, version))
  cache-to   = get-cache-to(REGISTRY_CACHE, try(S6_VERSIONS[version].overlay_version, version))
}