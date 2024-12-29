#!/bin/bash
set -ex

cp ${PROJECT_DIR}/.devcontainer/etc/.tmux.conf ~/.tmux.conf

cat <<EOF >> ~/.bashrc

source ${PROJECT_DIR}/.devcontainer/.bashrc_private
EOF