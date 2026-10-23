# 구조와 설계 판단

## AS와 VRF

| 영역 | AS | 라우팅 |
|---|---|---|
| DC1 | 65100 | 언더레이 OSPF, 오버레이 iBGP EVPN(spine이 Route Reflector), leaf3·4가 PE1과 Hub에 eBGP |
| MPLS 코어 | 65000 | OSPF, LDP, PE1~3 iBGP VPNv4 전체 메시 |
| DC2 | 65201 | CX1·2가 PE2와 VRF eBGP |
| Hub | 65010 | leaf와 eBGP, BGW와 터널 위 eBGP |
| Branch BGW | 65020 | PE3와 eBGP(WAN-UL), Hub와 터널 위 eBGP, DSW와 OSPF |

| VRF | RD, RT | 용도 |
|---|---|---|
| TENANT-A | 65000:1 | DC1과 DC2 사용자 경로 |
| WAN-UL | 65000:99 | Hub와 BGW 터널 언더레이 |

- 타이머는 OSPF hello 1초와 dead 4초, BGP 3초와 9초로 통일해 장애 감지 시간을 맞춤([프로토콜 매트릭스](../00-overview/03-protocol-matrix.md))
- 주소, router-id, VNI는 [IP, AS, VNI 설계](../00-overview/02-ip-addressing.md)

## 설계 판단과 이유

| 판단 | 이유 | 근거 |
|---|---|---|
| leaf 쌍이 VTEP 주소 하나를 공유(leaf1·2 10.1.1.12, leaf3·4 10.1.1.34) | MLAG로 묶인 두 장비를 EVPN에서 하나의 장비처럼 보이게 함 | [EVPN 검증](../verification/dc1/03-evpn-vxlan.md) |
| VRF를 TENANT-A와 WAN-UL로 분리 | DC 사용자 경로와 터널 언더레이 경로를 코어에서 섞지 않음 | [VRF 검증](../verification/core/05-vrf.md) |
| WAN-UL을 구역마다 다르게 구성(PE1-Hub 정적 경로, PE3-BGW eBGP) | Hub는 BGW 주소만 알면 되고, BGW는 아무것도 PE3에 광고하지 않아 Branch LAN이 새지 않게 함 | [WAN-UL 검증](../verification/br/07-wan-ebgp.md) |
| 터널 위 eBGP에 `prefix-list NO-UNDERLAY` 적용 | 터널 양 끝 주소(10.0.30.x)가 터널로 광고되면 재귀 라우팅으로 터널이 내려갈 수 있음 | [터널 위 eBGP 검증](../verification/br/10-bgp-over-tunnel.md) |
| IPsec은 IKEv1, AES256, SHA, DH 14, 전송 모드 | c7200 12.4(24)T 지원 범위에서 선택(SHA256 미지원). 전송 모드로 GRE 오버헤드를 줄임 | [GRE over IPsec 검증](../verification/br/09-ipsec-gre.md) |
| 터널 IP MTU 1400, MSS 1360 | GRE와 ESP 오버헤드로 큰 패킷이 잘리는 것을 막음 | [MTU 검증](../verification/br/11-mtu-mss.md) |
| VRRP master와 MSTP root를 같은 스위치로 일치 | 게이트웨이와 L2 root가 다르면 트래픽이 DSW 사이로 우회함 | [VRRP 검증](../verification/br/05-vrrp-svi.md) |
| QoS 분류는 c7200에서 DSCP로 함 | vEOS가 인터페이스 ACL을 지원하지 않음 | [기능 확인](../00-overview/05-feature-check.md) |
| QoS에 제어 트래픽 클래스(NETCTRL) 추가 | 혼잡 시 BGP 유지 패킷이 밀려 세션이 끊긴 적이 있음 | [QoS 검증](../verification/core/08-qos.md) |

## 트래픽 경로 예

| 시험 | 경로 |
|---|---|
| Host A → Host D (DC1 → DC2) | leaf → PE1 → PE2 → CX1·2 → Host D. VRF TENANT-A, MPLS 레이블 교환 |
| Host F → Host A (Branch → DC1) | DSW1 → BGW1 → 터널 0 → Hub1 → leaf3 → Host A |
| Host G → Host A (Branch → DC1) | DSW2 → BGW2 → 터널 1 → Hub2 → leaf4 → Host A |
