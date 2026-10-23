ip addr flush dev eth0
ip addr add 192.168.10.102/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.10.1
ip -br addr
ping -c 3 192.168.10.1