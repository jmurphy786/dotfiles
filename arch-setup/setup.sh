#!/usr/bin/env bash
set -e

curl -L -o devpod "https://github.com/loft-sh/devpod/releases/latest/download/devpod-linux-amd64"
sudo mv devpod /usr/local/bin/devpod
sudo chmod +x /usr/local/bin/devpod
