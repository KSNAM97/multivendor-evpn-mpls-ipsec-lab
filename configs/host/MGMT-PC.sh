ip addr flush dev eth0
ip addr add 192.168.100.10/24 dev eth0
ip link set eth0 up
ip -br addr
ping -c 3 192.168.100.11