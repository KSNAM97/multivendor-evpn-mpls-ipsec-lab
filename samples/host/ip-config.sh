# Ubuntu Docker Guest (GNS3) - 호스트 IP 설정 샘플 (Host B 기준, 값은 예시)
# 호스트별 주소는 설계 문서의 테넌트 표를 따른다 (아래 표 참고)
# 확인: ip addr show eth0 / ip route / ping -c 3 <게이트웨이>
#
#   Host A  192.168.10.101/24   gw 192.168.10.1   (bond0, 문서 bond-lacp 참고)
#   Host B  192.168.10.102/24   gw 192.168.10.1
#   Host C  192.168.20.101/24   gw 192.168.20.1
#   Host D  192.168.110.101/24  gw 192.168.110.1  (eth1을 사용: CX1 1/1/7. eth0는 내림 = ip link set eth0 down)
#   Host F  192.168.50.101/24   gw 192.168.50.1  (VRRP VIP)
#   Host G  192.168.60.101/24   gw 192.168.60.1  (VRRP VIP)

# 1. 임시 설정 (노드를 다시 켜면 사라진다)
ip addr flush dev eth0
ip addr add 192.168.10.102/24 dev eth0
ip link set eth0 up
ip route add default via 192.168.10.1

# 2. 영구 설정이 필요하면 GNS3에서 노드 우클릭 > Edit config 로
#    /etc/network/interfaces 를 편집한다 (이미지에 따라 방식이 다를 수 있다)
#
# auto eth0
# iface eth0 inet static
#     address 192.168.10.102
#     netmask 255.255.255.0
#     gateway 192.168.10.1

# 3. 확인
ip addr show eth0
ip route
ping -c 3 192.168.10.1
