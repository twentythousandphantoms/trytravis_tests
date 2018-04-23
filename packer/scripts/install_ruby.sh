#!/bin/bash
set -e

# Install ruby
apt-get update
apt install -y ruby-full ruby-bundler build-essential
