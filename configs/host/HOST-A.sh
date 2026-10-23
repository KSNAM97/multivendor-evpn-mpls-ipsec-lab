ip -br link
ip link add bond0 type bond mode 802.3ad
ip link set bond0 type bond miimon 100 lacp_rate fast xmit_hash_policy layer3+4
ip link set eth0 down
ip link set eth1 down
ip link set eth0 master bond0
ip link set eth1 master bond0
ip link set bond0 up
ip addr add 192.168.10.101/24 dev bond0
ip route add default via 192.168.10.1
cat /proc/net/bonding/bond0
ping -c 3 192.168.10.1