ip addr flush dev eth0
ip addr add 10.9.0.10/24 dev eth0
ip route add default via 10.9.0.1
ip link set eth0 up
ip -br addr
ping -c 3 10.9.0.1
