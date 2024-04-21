#!/usr/bin/env bash

set -eo pipefail

install_dependencies_macos() {
  xcode-select --install > /dev/null 2>&1 || true
  if ! sudo xcodebuild -license accept; then
    echo "Failed to accept Xcode license" >&2
    exit 1
  fi
}

install_dependencies_linux() {
  if ! sudo pacman -S git python3; then
    echo 'Failed to install git + python3 packages' >&2
    exit 1
  fi
}

download_playbooks_and_run() {
  local target_dir="$HOME/ENV_SETUP"
  mkdir -p "$target_dir"
  pushd "$target_dir" || exit 255

  if ! curl -O https://raw.githubusercontent.com/kcierzan/dev-env/main/dev-machine.yml ||
     ! curl -O https://raw.githubusercontent.com/kcierzan/dev-env/main/requirements.yml; then
    echo 'Failed to download playbook files' >&2
    exit 1
  fi

  if ! ansible-galaxy install -r requirements.yml ||
     ! ansible-playbook -i 'localhost' -c local dev-machine.yml --ask-become-pass; then
    echo 'Ansible setup failed' >&2
    exit 1
  fi

  popd || exit 255
  rm -rf "$target_dir"
}

case "$(uname)" in
  Darwin)
    install_dependencies_macos
    ;;
  Linux)
    install_dependencies_linux
    ;;
esac

if ! curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py; then
  echo 'Failed to download get-pip.py' >&2
  exit 1
fi

if ! python3 get-pip.py; then
  echo 'Failed to install pip' >&2
  exit 1
fi

if ! pip3 install --ignore-installed --user ansible; then
  echo 'Failed to install ansible'
fi

rm get-pip.py
download_playbooks_and_run
