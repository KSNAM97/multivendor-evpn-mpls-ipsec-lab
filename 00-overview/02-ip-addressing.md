# 02. IP / AS / VNI 설계

장비별 포트와 IP 전체: [IP와 포트 매칭표](07-ip-port-matrix.md). Loopback0은 장비 고유(OSPF router-id, BGP 세션 출발지. BGP router-id는 별도 대역, 3-1-1 참고), Loopback1은 leaf의 VTEP이며 MLAG 쌍이 공유. VLAN 10은 leaf1~4, VLAN 20은 leaf3·4에만 있음

## 1. 주소 블록 개요

| 용도 | 블록 |
|---|---|
| 관리망 | 192.168.100.0/24 |
| 코어 루프백 | 10.0.0.0/24 |
| 코어 링크 (PE 삼각형) | 10.0.10.0/24 |
| DC2 PE-CE 링크 (PE2-CX, VRF PARTNER) | 10.0.20.0/24 (10.0.20.4~7만 사용) |
| PE1-Hub 링크 (VRF TENANT-A) | 10.0.30.0/24 (10.0.30.0~3만 사용) |
| Hub-border leaf 연동 링크 | 10.0.31.0/24 (10.0.31.0~3만 사용) |
| Branch PE-CE 링크 (PE3-BGW, VRF BR1) | 10.0.60.0/24 |
| Branch 라우티드 링크 | 10.50.0.0/24 |
| DC1 루프백 / VTEP / 링크 / MLAG | 10.1.0.0/24 / 10.1.1.0/24 / 10.1.10.0/24 / 10.1.254.0/24 |
| DC2 루프백 / VSX keepalive | 10.2.0.0/24 / 10.2.254.0/24 (10.2.1.0/24 VTEP과 10.2.10.0/24 링크는 현재 미사용) |
| 테넌트 서브넷 | 192.168.0.0/16 (아래 4번 표) |

## 2. 라우팅 프로토콜과 AS 번호

사용 프로토콜은 **OSPF, iBGP, eBGP**. 사이트 안은 iBGP(DC1 EVPN은 spine이 Route Reflector, 코어는 PE 간 VPNv4), 사이트 사이는 eBGP

| 도메인 | AS | 구성 |
|---|---|---|
| MPLS 코어 | 65000 | OSPF + LDP. PE1~PE3 iBGP VPNv4(full mesh), PE-CE는 eBGP |
| DC1 (spine1, spine2, leaf1~4, border-leaf1·2) | 65100 | OSPF underlay + iBGP EVPN(루프백 간). spine1·2가 Route Reflector, leaf와 border leaf는 client. border-leaf1·2가 각각 Hub1·Hub2와 eBGP |
| DC2 VSX 쌍 (CX1, CX2) | 65201 | 같은 AS, PE2와 eBGP. CX3(access)은 L2 전용이라 AS 없음 |
| Hub1, Hub2 | 65010 | border leaf, PE1과 eBGP(PE-CE) |
| BGW1, BGW2 | 65020 | 고객사 망 끝단(CE). PE3와 eBGP, Branch 내부는 OSPF |

DC1은 OSPF underlay로 구성. DC2는 VSX 쌍이 단일 VTEP이라 EVPN 대상이 없으므로 VSX LAG, active gateway, eBGP 연동을 시연하고, EVPN-VXLAN은 DC1(Arista)에서 시연

## 3. 장비별 주소

### 3-1. 관리와 루프백

| 노드 | 벤더 | Mgmt | Loopback0 | VTEP |
|---|---|---|---|---|
| spine1 | Arista | 192.168.100.11 | 10.1.0.1/32 | - |
| spine2 | Arista | 192.168.100.12 | 10.1.0.2/32 | - |
| leaf1 | Arista | 192.168.100.21 | 10.1.0.11/32 | Lo1 10.1.1.12/32 (leaf2와 공유) |
| leaf2 | Arista | 192.168.100.22 | 10.1.0.12/32 | Lo1 10.1.1.12/32 (leaf1과 공유) |
| leaf3 | Arista | 192.168.100.23 | 10.1.0.13/32 | Lo1 10.1.1.34/32 (leaf4와 공유) |
| leaf4 | Arista | 192.168.100.24 | 10.1.0.14/32 | Lo1 10.1.1.34/32 (leaf3과 공유) |
| border-leaf1 | Arista | 192.168.100.25 (미연결) | 10.1.0.15/32 | Lo1 10.1.1.15/32 (단독) |
| border-leaf2 | Arista | 192.168.100.26 (미연결) | 10.1.0.16/32 | Lo1 10.1.1.16/32 (단독) |
| PE1 | Cisco | (콘솔) | 10.0.0.11/32 | - |
| PE2 | Cisco | (콘솔) | 10.0.0.12/32 | - |
| PE3 | Cisco | (콘솔) | 10.0.0.13/32 | - |
| Hub1 | Cisco | (콘솔) | 10.0.0.21/32 | - |
| Hub2 | Cisco | (콘솔) | 10.0.0.22/32 | - |
| BGW1 | Cisco | (콘솔) | 10.0.0.31/32 | - |
| BGW2 | Cisco | (콘솔) | 10.0.0.32/32 | - |
| DSW1 | Cisco | 192.168.100.44 (Gi3/3) | Lo0 10.0.0.41/32 | - |
| DSW2 | Cisco | 192.168.100.45 (Gi3/3) | Lo0 10.0.0.42/32 | - |
| ASW1 | Cisco | 192.168.100.46 (Vlan100, Gi3/3은 access VLAN 100) | - | L2 스위치. 데이터 VLAN(50, 60)에는 SVI 없음 |
| CX1 | Aruba | 192.168.100.41 | 10.2.0.1/32 | Lo1 10.2.1.1/32 (VSX 공유) |
| CX2 | Aruba | 192.168.100.42 | 10.2.0.2/32 | Lo1 10.2.1.1/32 (VSX 공유) |
| CX3 | Aruba | 192.168.100.43 | - | - |

### 3-1-1. router-id (OSPF와 BGP는 서로 다른 값)

OSPF router-id는 `loopback0` 주소를 쓰고, **BGP router-id는 별도 대역**(끝자리는 loopback0과 같게)을 씀. 출력과 와이어샤크에서 어느 프로토콜의 ID인지 바로 구분되고, EVPN의 RD는 BGP router-id를 기준으로 만듦

| 사이트 | 장비 | OSPF router-id | BGP router-id | 비고 |
|---|---|---|---|---|
| DC1 | spine1, spine2 | 10.1.0.1, 10.1.0.2 | **10.1.2.1, 10.1.2.2** | iBGP Route Reflector |
| DC1 | leaf1 ~ leaf4 | 10.1.0.11 ~ 10.1.0.14 | **10.1.2.11 ~ 10.1.2.14** | EVPN RD 접두 |
| DC1 | border-leaf1, border-leaf2 | 10.1.0.15, 10.1.0.16 | **10.1.2.15, 10.1.2.16** | EVPN RD 접두 |
| 코어 | PE1 ~ PE3 | 10.0.0.11 ~ 10.0.0.13 | **10.0.1.11 ~ 10.0.1.13** | LDP router-id는 loopback0 |
| DC1 외부 연결 | Hub1, Hub2 | (OSPF 없음) | **10.0.1.21, 10.0.1.22** | border leaf, PE1과 eBGP |
| Branch | BGW1, BGW2 | 10.0.0.31, 10.0.0.32 | **10.0.1.31, 10.0.1.32** | |
| Branch | DSW1, DSW2 | 10.0.0.41, 10.0.0.42 | (BGP 없음) | |
| DC2 | CX1, CX2 | (OSPF 없음) | **10.2.2.1, 10.2.2.2** | PE2와 eBGP |

- BGP router-id 대역(`10.1.2.0/24`, `10.0.1.0/24`, `10.2.2.0/24`)은 장비에 실제로 설정하는 주소가 아니라 ID 값만 쓰는 예약 대역. BGP 이웃 주소(`update-source`)는 계속 `loopback0`
### 3-2. 점대점 링크 (/31, 앞 주소가 A측)

**DC1 underlay (global)**

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| spine1 - leaf1 | 10.1.10.0/31 | .0 | .1 |
| spine1 - leaf2 | 10.1.10.2/31 | .2 | .3 |
| spine1 - leaf3 | 10.1.10.4/31 | .4 | .5 |
| spine1 - leaf4 | 10.1.10.6/31 | .6 | .7 |
| spine1 - border-leaf1 | 10.1.10.16/31 | .16 | .17 |
| spine1 - border-leaf2 | 10.1.10.18/31 | .18 | .19 |
| spine2 - leaf1 | 10.1.10.8/31 | .8 | .9 |
| spine2 - leaf2 | 10.1.10.10/31 | .10 | .11 |
| spine2 - leaf3 | 10.1.10.12/31 | .12 | .13 |
| spine2 - leaf4 | 10.1.10.14/31 | .14 | .15 |
| spine2 - border-leaf1 | 10.1.10.20/31 | .20 | .21 |
| spine2 - border-leaf2 | 10.1.10.22/31 | .22 | .23 |
| leaf1 - leaf2 (MLAG, Vlan4094) | 10.1.254.0/31 | .0 | .1 |
| leaf3 - leaf4 (MLAG, Vlan4094) | 10.1.254.2/31 | .2 | .3 |

**MPLS 코어 (global, PE 삼각형)**

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| PE1 - PE2 | 10.0.10.0/31 | PE1 .0 | PE2 .1 |
| PE1 - PE3 | 10.0.10.2/31 | PE1 .2 | PE3 .3 |
| PE2 - PE3 | 10.0.10.4/31 | PE2 .4 | PE3 .5 |

**DC2 PE-CE (PE 측은 VRF PARTNER)**

| 링크 | 서브넷 | PE측 | DC측 |
|---|---|---|---|
| PE2 - CX1 | 10.0.20.4/31 | .4 | .5 |
| PE2 - CX2 | 10.0.20.6/31 | .6 | .7 |

**DC1 PE-CE (PE1 측은 VRF TENANT-A)**

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| PE1 Gi2/0 - Hub1 Gi0/0 | 10.0.30.0/31 | PE1 .0 | Hub1 .1 |
| PE1 Gi5/0 - Hub2 Gi0/0 | 10.0.30.2/31 | PE1 .2 | Hub2 .3 |

**Branch PE-CE (PE 측은 VRF BR1, .100 서브인터페이스, dot1q 100)**

| 링크 | 서브넷 | PE측 | BGW측 |
|---|---|---|---|
| PE3 Gi2/0.100 - BGW1 Gi0/0.100 | 10.0.60.0/31 | .0 | .1 |
| PE3 Gi3/0.100 - BGW2 Gi0/0.100 | 10.0.60.2/31 | .2 | .3 |

**Hub 연동 (border leaf 측은 VRF TENANT-A, 1대1 연결)**

| 링크 | 서브넷 | border leaf측 | Hub측 |
|---|---|---|---|
| border-leaf1 Et1 - Hub1 Gi1/0 | 10.0.31.0/31 | .0 | .1 |
| border-leaf2 Et1 - Hub2 Gi1/0 | 10.0.31.2/31 | .2 | .3 |

**Branch 라우티드 링크 (OSPF area 0)**

| 링크 | 서브넷 | BGW측 | DSW측 |
|---|---|---|---|
| BGW1 - DSW1 | 10.50.0.0/31 | .0 | .1 |
| BGW2 - DSW2 | 10.50.0.2/31 | .2 | .3 |

**DC2 (VSX)**

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| CX1 - CX2 (VSX keepalive) | 10.2.254.0/31 | CX1 .0 | CX2 .1 |

## 4. 테넌트(오버레이) 설계

| 위치 | VLAN | L2VNI | 서브넷 | 게이트웨이 | 호스트 |
|---|---|---|---|---|---|
| DC1 | 10 | 10010 | 192.168.10.0/24 | .1 (anycast gateway) | Host A .101, Host B .102 |
| DC1 | 20 | 10020 | 192.168.20.0/24 | .1 (anycast gateway) | Host C .101 |
| DC2 | 110 | 10110 | 192.168.110.0/24 | .1 (VSX active gateway) | Host E .101 |
| Branch | 50 | - | 192.168.50.0/24 | VRRP VIP .1 (DSW1 .2, DSW2 .3) | Host F .101 |
| Branch | 60 | - | 192.168.60.0/24 | VRRP VIP .1 (DSW1 .2, DSW2 .3) | Host G .101 |

- VRF 이름: DC1 **TENANT-A**(PE1), DC2 **PARTNER**(PE2), Branch **BR1**(PE3). L3VNI는 **50001**(DC1)
- anycast gateway virtual MAC: `00:1c:73:00:00:99` (Arista)
- VRRP: VLAN 50은 DSW1이 master, VLAN 60은 DSW2가 master (부하 분산)

## 5. Route Distinguisher / Route Target

| 용도 | RD | RT |
|---|---|---|
| MPLS L3VPN TENANT-A (PE1, DC1) | 65000:1 | export 65000:1, import 65000:1·65000:3 |
| MPLS L3VPN PARTNER (PE2, DC2) | 65000:2 | export 65000:2, import 65000:2·65000:3 |
| MPLS L3VPN BR1 (PE3, Branch) | 65000:3 | export 65000:3, import 65000:1·65000:2·65000:3 |
| EVPN L2VNI VLAN 10 (DC1) | `<BGP router-id>:10010` | 10010:10010 |
| EVPN L2VNI VLAN 20 (DC1) | `<BGP router-id>:10020` | 10020:10020 |
| EVPN L3VNI TENANT-A (DC1) | `<BGP router-id>:50001` | 50001:50001 |

## 6. DC1과 DC2의 논리적 분리

DC1(TENANT-A)과 DC2(PARTNER)는 서로의 RT를 import하지 않아 경로가 섞이지 않음. BR1 VRF만 양쪽을 import해 Branch가 두 DC와 통신. BGW는 자기 대역(192.168.50.0/24, 192.168.60.0/24)만 PE3로 내보내서 BR1을 거쳐 DC1과 DC2가 서로 통신하지 않게 함. 물리 분리가 아니라 VRF와 RT, BGW prefix-list로 하는 논리적 분리

이중화와 부하 분산 설계: [03-protocol-matrix.md](03-protocol-matrix.md) 3번 표
