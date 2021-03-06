
#!/bin/bash
# post-commit hook to create git file directory for node subdomain

echo ""
echo ""
echo -e "\033[33m\033[1m

      hh                                                 kkk
    hh:h                                              kkk::k
  hh:::h                                             k:::::k
  h::::h                                             k:::::k
  h::::h hhhhh         ooooooooooo      ooooooooooo  k:::::k    kkkkkkk
  h::::hh:::::hhh    oo:::::::::::oo  oo:::::::::::oo  k:::k   k:::::k
  h::::::::::::::h  o:::::::::::::::oo:::::::::::::::o  k::k  k:::::k
  h::::::hhhh::::h  o:::::ooooo:::::::o::::ooooo:::::o  k::k k:::::k
  h:::::h    h:::h  o::::o     oo::::::o::o     o::::o  k:::k:::::k
  h:::::h     h::h  o::::o     o::o::::::oo     o::::o  k:::kkk::::k
  h:::::h     h::h  o:::::ooooo::::o:::::::ooooo:::::o  k::k   k::::k
  h:::::h     h::h  o:::::::::::::::oo:::::::::::::::o  k::k    k::::k
  h:::::h     h:::h  oo:::::::::::oo  oo:::::::::::oo  k:::k     k::::k
  hhhhhhh     hhhhhhh  ooooooooooo      ooooooooooo  kkkkkkk      kkkkkk \033[22m\033[39m

                           http://tryhook.com/"
echo ""
echo ""

SECRETKEY=PleaseRestartMyAppMKey
GITBASE=/git
APPSBASE=/app

OLD_PWD=$PWD
gitdirsuffix=${PWD##*/}
gitdir=${gitdirsuffix%.git}
GITBASELEN=${#GITBASE};
OLD_PWDLEN=${#OLD_PWD};
MY_LEN=$(( ${OLD_PWDLEN} - ${GITBASELEN} - 4 ));
appdir="${APPSBASE}${OLD_PWD:${GITBASELEN}:${MY_LEN}}";

if [ -d "${appdir}" ]; then
  echo "Syncing repo with chroot"
  cd ${appdir};
  unset GIT_DIR;
  # git pull;
  git fetch origin
  git reset --hard origin/master
else
  echo "Fresh git clone into chroot"
  mkdir -p ${appdir};
  git clone . ${appdir};
  cd ${appdir};
fi

# Because I hate bash..
python <<END

import json
import os

# Add a package.json

outfile = 'package.json'

data = {}
if os.path.exists(outfile):
  with open(outfile, "r") as jsonFile:
    data = json.load(jsonFile)

if not 'repository' in data:
  data['repository'] = {'type': 'git', 'url': 'http://thisisto.supresswarning.com'}

data['main'] = 'bootstrap.js'
data['dependencies'] = {'console-ten': '*'}

with open(outfile, "w") as jsonFile:
  jsonFile.write(json.dumps(data))

# Write the README file (to supress warnings)

with open("README.md","w+") as f:
  f.write('<3')

# Create a base script

with open("bootstrap.js","w+") as f:
  f.write('require("console-ten").init(console);')
  f.write('require("fs").readdirSync(require("path").resolve(__dirname, "includes")).forEach(function(file) { require("./includes/" + file); });');

END

hook=./.git/hooks/post-receive
if [ -f "$hook" ]; then
    rm $hook
fi

if [ -f ./.gitmodules ]; then
    echo "Found git submodules, updating them now..."
    git submodule init;
    git submodule update;
fi

if [ -f ./package.json ]; then
    echo "Updating npm modules..."
    #npm install
    /usr/local/bin/npm install --loglevel silent
fi

cd $OLD_PWD

echo "Attempting to restart your app: ${gitdir}"
curl "http://127.0.0.1:4001/app_restart?repo_id=${gitdir}&restart_key=${SECRETKEY}" 2>/dev/null
echo "App restarted.."
echo ""
echo "  \m/ Hook out \m/"
echo ""
exit 0;
