#!/usr/bin/env bash

while getopts 'o' OPT;
do
    case $OPT in
        o) DUMP_NS=True;;
    esac
done
shift $(($OPTIND - 1))

cp config/test/smfcfg.single.test.conf config/test/smfcfg.test.conf

GOPATH=$HOME/go
if [ $OS == "Ubuntu" ]; then
    GOROOT=/usr/local/go
elif [ $OS == "Fedora" ]; then
    GOROOT=/usr/lib/golang
fi
PATH=$PATH:$GOPATH/bin:$GOROOT/bin

UPFNS="UPFns"
EXEC_UPFNS="sudo -E ip netns exec ${UPFNS}"

export GIN_MODE=release

# Setup network namespace
sudo ip netns add ${UPFNS}

sudo ip link add veth0 type veth peer name veth1
sudo ip link set veth0 up
sudo ip addr add 60.60.0.1 dev lo
sudo ip addr add 10.200.200.1/24 dev veth0
sudo ip addr add 10.200.200.2/24 dev veth0

sudo ip link set veth1 netns ${UPFNS}

${EXEC_UPFNS} ip link set lo up
${EXEC_UPFNS} ip link set veth1 up
${EXEC_UPFNS} ip addr add 60.60.0.101 dev lo
${EXEC_UPFNS} ip addr add 10.200.200.101/24 dev veth1
${EXEC_UPFNS} ip addr add 10.200.200.102/24 dev veth1

if [ ${DUMP_NS} ]
then
    ${EXEC_UPFNS} tcpdump -i any -w ${UPFNS}.pcap &
    TCPDUMP_PID=$(sudo ip netns pids ${UPFNS})
fi

cd src/upf/build && ${EXEC_UPFNS} ./bin/free5gc-upfd -f config/upfcfg.test.yaml &
sleep 2

# ${EXEC_UPFNS} ip link set dev upfgtp0 mtu 1500

# cd src/test
# $GOROOT/bin/go test -v -vet=off -run $1

