#!/bin/bash
PREFIX="${FLOATSMITH_TOOLS}"

#install CoDiPack
printf "\n\nInstalling CoDiPack\n\n"
cd ${PREFIX}
git clone https://github.com/SciCompKL/CoDiPack

#install ADAPT
printf "\n\nInstalling ADAPT\n\n"
cd ${PREFIX}
git clone https://github.com/LLNL/adapt-fp

cat > adapt_env.sh << EOF
export CODIPACK_HOME=${PREFIX}/CoDiPack
export ADAPT_HOME=${PREFIX}/adapt-fp
EOF


