ip link set eth0 down
ip addr flush dev eth1
ip addr add 192.168.110.101/24 dev eth1
ip link set eth1 up
ip route add default via 192.168.110.1 dev eth1
ip -br addr
ip route
ping -c 3 192.168.110.1