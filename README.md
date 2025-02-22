# SmartX CoreOS Config

Manifest configuration for SmartX CoreOS.

## How to Build

### Install [CoreOS Assembler](https://github.com/coreos/coreos-assembler)

```bash
cat <<"EOF" >> ~/.bashrc
cosa() {
   env | grep COREOS_ASSEMBLER
   local -r COREOS_ASSEMBLER_CONTAINER_LATEST="quay.io/coreos-assembler/coreos-assembler:latest"
   if [[ -z ${COREOS_ASSEMBLER_CONTAINER} ]] && $(podman image exists ${COREOS_ASSEMBLER_CONTAINER_LATEST}); then
       local -r cosa_build_date_str="$(podman inspect -f "{{.Created}}" ${COREOS_ASSEMBLER_CONTAINER_LATEST} | awk '{print $1}')"
       local -r cosa_build_date="$(date -d ${cosa_build_date_str} +%s)"
       if [[ $(date +%s) -ge $((cosa_build_date + 60*60*24*7)) ]] ; then
         echo -e "\e[0;33m----" >&2
         echo "The COSA container image is more that a week old and likely outdated." >&2
         echo "You should pull the latest version with:" >&2
         echo "podman pull ${COREOS_ASSEMBLER_CONTAINER_LATEST}" >&2
         echo -e "----\e[0m" >&2
         sleep 10
       fi
   fi
   set -x
   podman run --rm -ti --security-opt label=disable --privileged                                    \
              --uidmap=1000:0:1 --uidmap=0:1:1000 --uidmap 1001:1001:64536                          \
              -v ${PWD}:/srv/ --device /dev/kvm --device /dev/fuse                                  \
              --tmpfs /tmp -v /var/tmp:/var/tmp --name cosa                                         \
              ${COREOS_ASSEMBLER_CONFIG_GIT:+-v $COREOS_ASSEMBLER_CONFIG_GIT:/srv/src/config/:ro}   \
              ${COREOS_ASSEMBLER_GIT:+-v $COREOS_ASSEMBLER_GIT/src/:/usr/lib/coreos-assembler/:ro}  \
              ${COREOS_ASSEMBLER_CONTAINER_RUNTIME_ARGS}                                            \
              ${COREOS_ASSEMBLER_CONTAINER:-$COREOS_ASSEMBLER_CONTAINER_LATEST} "$@"
   rc=$?; set +x; return $rc
}
EOF
```

### Build SmartX CoreOS

```bash
mkdir -p $HOME/tmp/smartx-coreos && cd $HOME/tmp/smartx-coreos
cosa init https://github.com/coreos/fedora-coreos-config.git
export COREOS_ASSEMBLER_CONFIG_GIT=$HOME/Projects/smartx-coreos-config
cosa fetch && cosa build --version 36.kubernetes-1.21.13.20220624 && cosa buildextend-metal && cosa buildextend-metal4k && cosa buildextend-live
```

### Embed an Ignition File for Unattended Installations

```bash
curl -LO http://192.168.17.20/kubrid/misc/default.ign
coreos-installer iso customize --dest-device /dev/vda --dest-ignition default.ign -o builds/latest/x86_64/smartx-coreos-35.20220408.dev.0-auto.x86_64.iso builds/latest/x86_64/smartx-coreos-35.20220408.dev.0-live.x86_64.iso
```
