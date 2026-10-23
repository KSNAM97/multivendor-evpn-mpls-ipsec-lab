# Ubuntu Docker Guest (GNS3) - LACP bond 샘플 (Host A, 값은 예시)
# Host A는 eth0, eth1로 leaf1, leaf2(MLAG 쌍)에 이중 연결한다. GNS3에서 어댑터를 2개로 설정
# 순서: bond 생성 > 옵션 지정 > 인터페이스를 내리고 slave 지정 > bond를 올림
# 확인: cat /proc/net/bonding/bond0 / ip -br link
# 스위치 쪽 확인: Arista "show mlag interfaces", "show port-channel dense"

# 1. bond 생성과 옵션 (802.3ad = LACP)
ip link add bond0 type bond mode 802.3ad
ip link set bond0 type bond miimon 100 lacp_rate fast xmit_hash_policy layer3+4

# 2. 인터페이스를 bond에 편입
ip link set eth0 down
ip link set eth1 down
ip link set eth0 master bond0
ip link set eth1 master bond0

# 3. 올리고 주소 지정
ip link set bond0 up
ip addr add 192.168.10.101/24 dev bond0
ip route add default via 192.168.10.1

# 4. 확인 (Aggregator ID가 두 slave에서 같고 LACP가 협상되었는지)
cat /proc/net/bonding/bond0
ip -br link
ping -c 3 192.168.10.1
