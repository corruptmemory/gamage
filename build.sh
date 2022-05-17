#!/usr/bin/env bash

cd "$(git rev-parse --show-toplevel)"
rm -f gamage
/home/jim/projects/Odin/odin build main -out:gamage -vet -debug -extra-linker-flags:'/home/jim/projects/stb/libstb_image.a /home/jim/projects/raylib/build/raylib/libraylib.a'
