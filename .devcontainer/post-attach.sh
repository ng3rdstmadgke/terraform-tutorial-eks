#!/bin/bash

set -ex

SCRIPT_DIR=$(cd $(dirname $0); pwd)

mkdir -p $HOME/.docker

# .docker/config.jsonにcredsStoreが自動で追記されてしまうため、空のファイルで上書きする
cat <<EOF > $HOME/.docker/config.json
{}
EOF