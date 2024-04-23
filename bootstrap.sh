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
  if ! command -v git &>/dev/null; then
    echo 'git is not installed. Attempting to install git...'
    if ! sudo pacman -S --noconfirm git; then
      echo 'Failed to install git' >&2
      exit 1
    fi
  fi

  if ! command -v python3 &>/dev/null; then
    echo 'python3 is not installed. Attempting to install python3...'
    if ! sudo pacman -S --noconfirm python3; then
      echo 'Failed to install python3' >&2
      exit 1
    fi
  fi
}

download_playbooks_and_run() {
  local repo_url="https://github.com/kcierzan/dev-env.git"
  local target_dir="$HOME/src/dev-env"

  mkdir -p "$target_dir"

  pushd "$target_dir" > /dev/null 2>&1 || exit 255

  if [ ! -d ".git" ]; then
    if ! git clone "$repo_url" . ; then
      echo 'Failed to clone the repository' >&2
      popd > /dev/null 2>&1
      exit 1
    fi
  else
    echo "Repository already exists, skipping clone..."
  fi

  if ! ansible-galaxy install -r requirements.yml ||
     ! ansible-playbook -i 'localhost' -c local dev-machine.yml --ask-become-pass; then
    echo 'Ansible setup failed' >&2
    popd > /dev/null 2>&1
    exit 1
  fi

  popd > /dev/null 2>&1
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
