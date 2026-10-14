#!/usr/bin/env bash
# Shared build helpers. Callers define repo_root, configuration and arch_mode.
locked_use_architectures() {
  case "$arch_mode" in
    native) architectures=("$(uname -m)") ;;
    universal) architectures=(arm64 x86_64) ;;
    arm64|x86_64) architectures=("$arch_mode") ;;
    *) echo "Unsupported Locked Use architecture: $arch_mode" >&2; return 64 ;;
  esac
}

locked_use_build_product() {
  local product="$1" destination="$2" arch binary_dir
  local binaries=()
  for arch in "${architectures[@]}"; do
    local args=(-c "$configuration")
    if [[ "$arch_mode" != native ]]; then
      args+=(--triple "${arch}-apple-macosx14.0" --scratch-path ".build/${arch}-${configuration}")
    fi
    swift build "${args[@]}" --product "$product"
    binary_dir="$(swift build "${args[@]}" --show-bin-path)"
    binaries+=("$binary_dir/$product")
  done
  if [[ "${#binaries[@]}" == 1 ]]; then
    cp "${binaries[0]}" "$destination"
  else
    lipo -create -output "$destination" "${binaries[@]}"
  fi
  lipo "$destination" -verify_arch "${architectures[@]}"
}

locked_use_sign() {
  local args=()
  if [[ -n "${OPEN_COMPUTER_USE_CODESIGN_KEYCHAIN:-}" ]]; then
    args+=(--keychain "$OPEN_COMPUTER_USE_CODESIGN_KEYCHAIN")
  fi
  /usr/bin/codesign "${args[@]}" "$@"
}

locked_use_version="$(python3 - "$repo_root/plugins/open-computer-use/.codex-plugin/plugin.json" <<'PYVERSION'
import json, sys
with open(sys.argv[1], encoding="utf-8") as source:
    print(json.load(source)["version"])
PYVERSION
)"
