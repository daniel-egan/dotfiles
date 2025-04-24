#!/usr/bin/env bash

# Update system packages
sudo apt-get upgrade -y

# Configure Git
git config --global --add safe.directory $PWD
git config --global pull.rebase false
