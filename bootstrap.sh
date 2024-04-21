#!/usr/bin/env bash

set -eo pipefail

if [ "$(uname)" = "Darwin" ]; then
  xcode-select --install > /dev/null 2>&1 || true
  sudo xcodebuild -license accept
fi

if [ "$(uname)" = "Linux" ]; then
  sudo pacman -S git python3
fi

curl https://bootstrap.pypa.io/get-pip.py -o get-pip.py
python3 get-pip.py
pip3 install --ignore-installed --user ansible
rm get-pip.py
ansible-galaxy install -r requirements.yml

ansible-playbook -i "localhost" -c local dev-machine.yml --ask-become-pass
