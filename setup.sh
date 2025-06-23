#!/bin/bash

echo "Attempting to setup security tools and execution environments"

PYTHON3_PATH="$(which python3)"
PIP3_PATH="$(which pip3)"

if [ $? -eq 1 ]; then
    echo "Unable to locate path for pip3 binary"
    return 1
fi

HAS_VENV="$(${PYTHON3_PATH} -m venv --help > /dev/null 2>&1)"

if [ $? -eq 1 ]; then
    echo "Unable to locate venv package"
    while true ;
    do
        read -p "Would you like to install venv using pip? [Y/n]" INSTALL_VENV
        if [[ $INSTALL_VENV==[yY] || $INSTALL_VENV==[yY][eE][sS] ]]; then
            echo "[*] Installing venv"
            ${PIP3_PATH} install -q venv
            if [ $? -eq 1 ]; then
                echo "Failed to install venv, please set it up and try again"
                break;
            fi
        elif [[ $INSTALL_VENV==[nN] || $INSTALL_VENV==[nN][oO] ]]; then
            echo "Not going to install, please install venv library for python and try again"
            return 1
        else
            echo "Invalid input"
        fi
    done
fi

PROJ_DIR="$( cd -- "$(dirname "$0")" >/dev/null 2>&1 ; pwd -P )"

cd $PROJ_DIR

mkdir "bin"

mkdir "venv_dirs"

echo "[*] Pulling submodule for other tools"

git submodule update --recursive

BLOODY_AD_DIR="bloodyAD"
CERTIPY_DIR="Certipy"
TGTD_KERBRST_DIR="targetedKerberoast"

cd "venv_dirs"


echo "[*] Creating execution environment for ${BLOODY_AD_DIR}"
"${PYTHON3_PATH}" -m venv --clear bloody_ad_venv
echo "[*] Using new environment for dependencies"
source ./bloody_ad_venv/bin/activate
echo "[*] Installing dependency libraries for ${BLOODY_AD_DIR}"
cd "${PROJ_DIR}/${BLOODY_AD_DIR}/"
pip install -qqq -r "requirements.txt" --disable-pip-version-check
cd "${PROJ_DIR}/venv_dirs"
echo "[*] Deactivating environment"
deactivate


echo "[*] Creating execution environment for ${CERTIPY_DIR}"
"${PYTHON3_PATH}" -m venv --clear certipy_venv
echo "[*] Using new environment for dependencies"
source ./certipy_venv/bin/activate
echo "[*] Installing dependency libraries for ${CERTIPY_DIR}"
# pip install -qqq certipy argcomplete impacket --disable-pip-version-check
cd "${PROJ_DIR}/${CERTIPY_DIR}"
pip install -qqq . --disable-pip-version-check
echo "[*] Setting up extra file reference"
cp "certipy/entry.py" "entry.py"
cd "${PROJ_DIR}/venv_dirs"
echo "[*] Deactivating environment"
deactivate


echo "[*] Creating execution environment for ${TGTD_KERBRST_DIR}"
"${PYTHON3_PATH}" -m venv --clear trgt_kerbrst_venv
echo "[*] Using new environment for dependencies"
source ./trgt_kerbrst_venv/bin/activate
echo "[*] Installing dependency libraries for ${TGTD_KERBRST_DIR}"
pip install -qqq -r "${PROJ_DIR}/${TGTD_KERBRST_DIR}/requirements.txt" --disable-pip-version-check
echo "[*] Deactivating environment"
deactivate


echo "[*] Setting up binaries"

cd "${PROJ_DIR}/bin"

if [ "$(ls -A ./)" ]; then
     echo "[*] Reomving existing files in bin"
    rm ./*
fi


echo "[*] Setting up binary for ${BLOODY_AD_DIR}"
echo "#!/bin/bash" >> "bloodyAD"
echo "" >> "bloodyAD"
echo "source \"${PROJ_DIR}/venv_dirs/bloody_ad_venv/bin/activate\"" >> "bloodyAD"
echo "python \"${PROJ_DIR}/${BLOODY_AD_DIR}/bloodyAD.py\" \"\$@\"" >> "bloodyAD"
echo "deactivate" >> "bloodyAD"
chmod 700 "bloodyAD"


echo "[*] Setting up binary for ${CERTIPY_DIR}"
echo "#!/bin/bash" >> "certipy-ad"
echo "" >> "certipy-ad"
echo "source \"${PROJ_DIR}/venv_dirs/certipy_venv/bin/activate\"" >> "certipy-ad"
echo "python \"${PROJ_DIR}/${CERTIPY_DIR}/entry.py\" \"\$@\"" >> "certipy-ad"
echo "deactivate" >> "certipy-ad"
chmod 700 "certipy-ad"


echo "[*] Setting up binary for ${TGTD_KERBRST_DIR}"
echo "#!/bin/bash" >> "targetedKerberoast"
echo "" >> "targetedKerberoast"
echo "source \"${PROJ_DIR}/venv_dirs/trgt_kerbrst_venv/bin/activate\"" >> "targetedKerberoast"
echo "python \"${PROJ_DIR}/${TGTD_KERBRST_DIR}/targetedKerberoast.py\" \"\$@\"" >> "targetedKerberoast"
echo "deactivate" >> "targetedKerberoast"
chmod 700 "targetedKerberoast"

if grep -Fxq "PATH=\"${PROJ_DIR}/bin:\${PATH}\"" ~/.bashrc ; then
    echo "[*] Path already set"
else
    echo "[*] Setting up PATH in .bashrc for new shells, please source .bashrc or open new shell to add tools"
    echo "PATH=\"${PROJ_DIR}/bin:\${PATH}\"" >> ~/.bashrc
fi

echo "[*] Setup finished"
