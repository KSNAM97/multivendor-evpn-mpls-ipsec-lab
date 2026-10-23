# 연결 확인

**목적**: 같은 VLAN, 다른 VLAN, 다른 지역, Branch 순으로 도달성을 확인

**핵심**

- 확인 순서: 같은 VLAN(L2VNI), 다른 VLAN(L3VNI), DC 간(MPLS L3VPN), Branch(IPsec).
- tcpdump는 설치되어 있지 않을 수 있음(인터넷 필요).

**확인 명령**: `ping -c 3 <대상>`, `traceroute -n <대상>`, `ip neigh`

파일: `connectivity.sh`

```bash
# Ubuntu Docker Guest (GNS3) - 연결 확인 명령 샘플 (값은 예시)
# 같은 VLAN, 다른 VLAN(L3VNI), 다른 지역, Branch 순으로 확인한다

# 1. 인터페이스와 라우팅
ip -br addr
ip route
ip neigh

# 2. 같은 VLAN (L2VNI): Host A <-> Host B
ping -c 3 192.168.10.102

# 3. 다른 VLAN (L3VNI): Host A -> Host C
ping -c 3 192.168.20.101

# 4. 다른 지역 (DC1 -> DC2): Host A -> Host D (MPLS L3VPN)
ping -c 3 192.168.110.101

# 5. Branch (GRE over IPsec): Host A -> Host F
ping -c 3 192.168.50.101

# 6. 경로 확인
traceroute -n 192.168.110.101

# 7. 패킷 캡처로 DSCP(tos) 확인 (tcpdump 설치 필요: apt install tcpdump, 인터넷 필요)
tcpdump -ni eth0 -v icmp
```
