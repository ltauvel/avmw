#!/bin/sh

# Install avm and avmw
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #

## Define AVM installation path
export AVM_BASEDIR=/opt/avm

## Creating AVM installation path
sudo mkdir -p "$AVM_BASEDIR"
sudo chown -R $USER:$USER "$AVM_BASEDIR"

## Creating a temp dir to download AVM source files
avm_dir="$(mktemp -d 2> /dev/null || mktemp -d -t 'mytmpdir')"
git clone https://github.com/ahelal/avm.git "${avm_dir}" #> /dev/null 2>&1

## Running the AVM setup
AVM_VERBOSE=vv "${avm_dir}"/setup.sh

## Removing temp folder
rm -rf "${avm_dir}"

## Setting right permissions  on the AVM installation path
sudo chown -R root:root "$AVM_BASEDIR"


## Creating an AVM wrapper script
sudo bash -c "cat >> $AVM_BASEDIR/.avmw" << EOL
#!/bin/sh

# avm cli tool wrapper
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

AVM_BASEDIR=$AVM_BASEDIR

# Ensure the AVM directory exists
sudo mkdir -p "\$AVM_BASEDIR"

# Aloowing the user to access the AVM directory
sudo chown -R "\$USER":"\$USER" "\$AVM_BASEDIR"

# Executing avm command
case \$1 in
  "path" | "use" | "set" | "activate")
    if [ -z "\$2" ] && [ -f "\$PWD"/.ansible-version ]; then
      AVM_BASEDIR="\$AVM_BASEDIR" "\$AVM_BASEDIR"/avm "\$@" \$(cat "\$PWD"/.ansible-version)
    else
      AVM_BASEDIR="\$AVM_BASEDIR" "\$AVM_BASEDIR"/avm "\$@"
    fi
    ;;
  "install")
    version_found=0
    for i in "\$@"; do
      if [ "\$i" = "-v" -o "\$i" = "--version" ]; then
        version_found=1
        break
      fi
    done
    if [ \$version_found -ne 1 ] && [ -f "\$PWD"/.ansible-version ]; then
      AVM_BASEDIR="\$AVM_BASEDIR" "\$AVM_BASEDIR"/avm "\$@" --version \$(cat "\$PWD"/.ansible-version)
    else
      AVM_BASEDIR="\$AVM_BASEDIR" "\$AVM_BASEDIR"/avm "\$@"
    fi
    ;;
  *)
    AVM_BASEDIR="\$AVM_BASEDIR" "\$AVM_BASEDIR"/avm "\$@"
    ;;
esac

# Resetting  permission on AVM directory
sudo chown -R root:root "\$AVM_BASEDIR"

# Ensure the avm command point to this wrapper script
sudo rm /usr/local/bin/avm
sudo ln -s "\$AVM_BASEDIR"/.avmw /usr/local/bin/avm
EOL

## Creating symbolic link to wrapper script
sudo rm /usr/local/bin/avm
sudo ln -s "$AVM_BASEDIR"/.avmw /usr/local/bin/avm

## Setting permission on AVM wrapper script
sudo chown root:root /usr/local/bin/avm
sudo chmod 0755 /usr/local/bin/avm

## Unsetting AVM installation path from environment
unset AVM_BASEDIR
