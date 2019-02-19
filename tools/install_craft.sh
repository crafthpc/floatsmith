#!/bin/bash
PREFIX="${FLOATSMITH_TOOLS}"

#install CRAFT
printf "\n\nInstalling CRAFT\n\n"
cd ${PREFIX}
git clone https://github.com/crafthpc/craft

cat > craft_env.sh << EOF
export PATH=${PREFIX}/craft/scripts:\$PATH
EOF
