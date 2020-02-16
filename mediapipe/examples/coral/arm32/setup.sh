#!/bin/sh

set -e
set -v

echo 'Please run this from root level mediapipe directory! \n Ex:'
echo '  sh mediapipe/examples/coral/setup.sh  '

sleep 3

mkdir opencv34_arm32_libs

cp mediapipe/examples/coral/arm32/update_sources.sh update_sources.sh
chmod +x update_sources.sh

mv Dockerfile Dockerfile.orig
cp mediapipe/examples/coral/arm32/Dockerfile Dockerfile

cp WORKSPACE WORKSPACE.orig
cp mediapipe/examples/coral/WORKSPACE WORKSPACE

