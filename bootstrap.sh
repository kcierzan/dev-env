#!/usr/bin/env bash

set -eo pipefail

install_dependencies_macos() {
  xcode-select --install > /dev/null 2>&1 || true
  if ! sudo xcodebuild -license accept; then
    echo "Failed to accept Xcode license" >&2
    exit 1
  fi

  if ! command -v brew &>/dev/null; then
    echo 'Homebrew is not installed. Attempting to install homebrew...'
    eval "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi

  if ! command -v python &>/dev/null; then
    echo 'python is not installed. Attempting to install python...'
    if ! brew install python; then
      echo "Failed to install python"
    fi
  fi
}

install_dependencies_linux() {
  if ! command -v git &>/dev/null; then
    echo 'Git is not installed. Attempting to install git...'
    if ! sudo pacman -S --noconfirm git; then
      echo 'Failed to install git' >&2
      exit 1
    fi
  fi

  if ! command -v python &>/dev/null; then
    echo 'Python is not installed. Attempting to install python...'
    if ! sudo pacman -S --noconfirm python; then
      echo 'Failed to install python' >&2
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

if ! ansible --version &>/dev/null; then
  echo 'Ansible is not installed. Attempting to install Ansible...'
  if ! pip install --ignore-installed --user ansible; then
    echo 'Failed to install ansible'
  fi
fi

download_playbooks_and_run
