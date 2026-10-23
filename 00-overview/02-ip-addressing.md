# 02. IP / AS / VNI 설계

장비별 포트와 IP 전체: [IP와 포트 매칭표](07-ip-port-matrix.md). Loopback0은 장비 고유(OSPF router-id, BGP 세션 출발지. BGP router-id는 별도 대역, 3-1-1 참고), Loopback1은 leaf의 VTEP이며 MLAG 쌍이 공유. VLAN 10은 leaf1~4, VLAN 20은 leaf3·4에만 있음

## 1. 주소 블록 개요

| 용도 | 블록 |
|---|---|
| 관리망 | 192.168.100.0/24 |
| 코어 루프백 | 10.0.0.0/24 |
| 코어 링크 (PE 삼각형) | 10.0.10.0/24 |
| DCI 링크 (PE-DC, VRF TENANT-A) | 10.0.20.0/24 |
| WAN 언더레이 링크 (VRF WAN-UL) | 10.0.30.0/24 |
| Hub-leaf 연동 링크 | 10.0.31.0/24 |
| GRE 터널 | 10.0.40.0/24 |
| Branch 라우티드 링크 | 10.50.0.0/24 |
| DC1 루프백 / VTEP / 링크 / MLAG | 10.1.0.0/24 / 10.1.1.0/24 / 10.1.10.0/24 / 10.1.254.0/24 |
| DC2 루프백 / VSX keepalive | 10.2.0.0/24 / 10.2.254.0/24 (10.2.1.0/24 VTEP과 10.2.10.0/24 링크는 현재 미사용) |
| 테넌트 서브넷 | 192.168.0.0/16 (아래 4번 표) |

## 2. 라우팅 프로토콜과 AS 번호

사용 프로토콜은 **OSPF, iBGP, eBGP**. 사이트 안은 iBGP(DC1 EVPN은 spine이 Route Reflector, 코어는 PE 간 VPNv4), 사이트 사이는 eBGP

| 도메인 | AS | 구성 |
|---|---|---|
| MPLS 코어 | 65000 | OSPF + LDP. PE1~PE3 iBGP VPNv4(full mesh), PE-CE는 eBGP |
| DC1 (spine1, spine2, leaf1~4) | 65100 | OSPF underlay + iBGP EVPN(루프백 간). spine1·2가 Route Reflector, leaf는 client. leaf3·4는 PE, Hub와 eBGP |
| DC2 VSX 쌍 (CX1, CX2) | 65201 | 같은 AS, PE2와 eBGP. CX3(access)은 L2 전용이라 AS 없음 |
| Hub1, Hub2 | 65010 | leaf3/leaf4와 eBGP, BGW와 터널 위 eBGP |
| BGW1, BGW2 | 65020 | Hub와 터널 위 eBGP, Branch 내부는 OSPF |

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
| 코어 | PE1 ~ PE3 | 10.0.0.11 ~ 10.0.0.13 | **10.0.1.11 ~ 10.0.1.13** | LDP router-id는 loopback0 |
| WAN | Hub1, Hub2 | (OSPF 없음) | **10.0.1.21, 10.0.1.22** | 터널 위 eBGP |
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
| spine2 - leaf1 | 10.1.10.8/31 | .8 | .9 |
| spine2 - leaf2 | 10.1.10.10/31 | .10 | .11 |
| spine2 - leaf3 | 10.1.10.12/31 | .12 | .13 |
| spine2 - leaf4 | 10.1.10.14/31 | .14 | .15 |
| leaf1 - leaf2 (MLAG, Vlan4094) | 10.1.254.0/31 | .0 | .1 |
| leaf3 - leaf4 (MLAG, Vlan4094) | 10.1.254.2/31 | .2 | .3 |

**MPLS 코어 (global, PE 삼각형)**

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| PE1 - PE2 | 10.0.10.0/31 | PE1 .0 | PE2 .1 |
| PE1 - PE3 | 10.0.10.2/31 | PE1 .2 | PE3 .3 |
| PE2 - PE3 | 10.0.10.4/31 | PE2 .4 | PE3 .5 |

**DCI (PE 측은 VRF TENANT-A)**

| 링크 | 서브넷 | PE측 | DC측 |
|---|---|---|---|
| PE1 - leaf3 | 10.0.20.0/31 | .0 | .1 |
| PE1 - leaf4 | 10.0.20.2/31 | .2 | .3 |
| PE2 - CX1 | 10.0.20.4/31 | .4 | .5 |
| PE2 - CX2 | 10.0.20.6/31 | .6 | .7 |

**WAN 언더레이 (VRF WAN-UL)와 터널**

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| PE1 - Hub1 | 10.0.30.0/31 | PE1 .0 | Hub1 .1 |
| PE1 - Hub2 | 10.0.30.2/31 | PE1 .2 | Hub2 .3 |
| PE3 - BGW1 | 10.0.30.4/31 | PE3 .4 | BGW1 .5 |
| PE3 - BGW2 | 10.0.30.6/31 | PE3 .6 | BGW2 .7 |
| Tunnel0 (Hub1 - BGW1) | 10.0.40.0/31 | Hub1 .0 | BGW1 .1 |
| Tunnel1 (Hub2 - BGW2) | 10.0.40.2/31 | Hub2 .2 | BGW2 .3 |

터널 source와 destination은 Tunnel0이 `10.0.30.1` ↔ `10.0.30.5`, Tunnel1이 `10.0.30.3` ↔ `10.0.30.7`

**Hub 내부 연동 (VRF TENANT-A, leaf 측)**

| 링크 | 서브넷 | leaf측 | Hub측 |
|---|---|---|---|
| leaf3 - Hub1 | 10.0.31.0/31 | .0 | .1 |
| leaf4 - Hub2 | 10.0.31.2/31 | .2 | .3 |

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
| DC2 | 110 | 10110 | 192.168.110.0/24 | .1 (VSX active gateway) | Host D .101 |
| Branch | 50 | - | 192.168.50.0/24 | VRRP VIP .1 (DSW1 .2, DSW2 .3) | Host F .101 |
| Branch | 60 | - | 192.168.60.0/24 | VRRP VIP .1 (DSW1 .2, DSW2 .3) | Host G .101 |

- VRF 이름: **TENANT-A** (DC1, DC2, PE 공통). L3VNI는 **50001**
- anycast gateway virtual MAC: `00:1c:73:00:00:99` (Arista)
- VRRP: VLAN 50은 DSW1이 master, VLAN 60은 DSW2가 master (부하 분산)

## 5. Route Distinguisher / Route Target

| 용도 | RD | RT |
|---|---|---|
| MPLS L3VPN TENANT-A (PE) | 65000:1 | import/export 65000:1 |
| MPLS L3VPN WAN-UL (PE1, PE3) | 65000:99 | import/export 65000:99 |
| EVPN L2VNI VLAN 10 (DC1) | `<BGP router-id>:10010` | 10010:10010 |
| EVPN L2VNI VLAN 20 (DC1) | `<BGP router-id>:10020` | 10020:10020 |
| EVPN L3VNI TENANT-A (DC1) | `<BGP router-id>:50001` | 50001:50001 |

## 6. IPsec 파라미터 (설계값)

| 항목 | 값 |
|---|---|
| IKE | IKEv1 (ISAKMP). c7200 이미지에 IKEv2가 없음 |
| 암호화 / 해시 / DH | AES-256 / SHA-1 (이 c7200 이미지의 ISAKMP는 sha256 미지원) / group 14 |
| IPsec 모드 | GRE를 보호하는 transport 모드 |
| 인증 | 사전 공유 키 (터널마다 1개, 실습 랩 전용 값은 [IPsec 키 관리](../baseline/br/08-ipsec-keys.md)) |
| 터널 | Tunnel0(Hub1-BGW1), Tunnel1(Hub2-BGW2). 터널 위 eBGP, ECMP |

## 7. QoS 클래스 (설계값)

| 클래스 | DSCP | 처리 |
|---|---|---|
| Voice | EF (46) | 우선 큐(LLQ) |
| Critical | AF31 | 최소 대역폭 보장 |
| Business | AF21 | 최소 대역폭 보장 |
| Best-effort | 0 | 나머지 |
| Scavenger | CS1 | 혼잡 시 먼저 폐기 |

- 마킹: **호스트**가 iperf3의 DSCP 옵션으로 마킹. (Arista vEOS는 ACL의 interface 적용이 되지 않아 분류에 쓰지 않음.)
- 집행: **c7200**(PE1~PE3, Hub1, Hub2, BGW1, BGW2)의 class-map과 policy-map, shaping
- MPLS 구간은 DSCP를 MPLS TC(EXP)로 매핑해 코어에서 큐잉

이중화와 부하 분산 설계: [03-protocol-matrix.md](03-protocol-matrix.md) 3번 표
