ip addr flush dev eth0
ip addr add 192.168.50.101/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.50.1
ip -br addr
ping -c 3 192.168.50.1