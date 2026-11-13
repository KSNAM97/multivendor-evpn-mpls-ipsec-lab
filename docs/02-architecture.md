# 구조와 설계 판단

## AS와 VRF

| 영역 | AS | 라우팅 |
|---|---|---|
| 누리데이터 DC1 | 65100 | 언더레이 OSPF, 오버레이 iBGP EVPN(spine이 Route Reflector), border-leaf1·2가 각각 Hub1·Hub2와 eBGP |
| 누리데이터 Hub | 65010 | border leaf와 eBGP, PE1과 eBGP(PE-CE) |
| 누리텔레콤 MPLS 코어 | 65000 | OSPF, LDP, PE1~3 iBGP VPNv4 전체 메시 |
| 청명정밀 DC2 | 65201 | CX1·2가 PE2와 VRF eBGP |
| 청명정밀 BR1(BGW) | 65020 | 고객사 망 끝단(CE). PE3와 eBGP, DSW와 OSPF |

| VRF | RD | RT export | RT import | 용도 |
|---|---|---|---|---|
| TENANT-A (PE1) | 65000:1 | 65000:1 | 65000:1, 65000:3 | DC1 |
| PARTNER (PE2) | 65000:2 | 65000:2 | 65000:2, 65000:3 | DC2 |
| BR1 (PE3) | 65000:3 | 65000:3 | 65000:1, 65000:2, 65000:3 | Branch |

- 타이머는 OSPF hello 1초와 dead 4초, BGP 3초와 9초로 통일해 장애 감지 시간을 맞춤([프로토콜 매트릭스](../00-overview/03-protocol-matrix.md))
- 주소, router-id, VNI는 [IP, AS, VNI 설계](../00-overview/02-ip-addressing.md)

## 설계 판단과 이유

| 판단 | 이유 | 근거 |
|---|---|---|
| leaf 쌍이 VTEP 주소 하나를 공유(leaf1·2 10.1.1.12, leaf3·4 10.1.1.34). 호스트는 각 leaf에 단일 연결 | MLAG로 묶인 두 장비를 EVPN에서 하나의 장비처럼 보이게 함 | [EVPN 검증](../verification/dc1/03-evpn-vxlan.md) |
| 전용 border leaf 2대를 Hub와 1대1로 연결(MLAG 없이 VTEP 각각) | 외부 연결을 서버 접속 leaf와 분리하고, VTEP을 공유하지 않아 한쪽 경로가 끊겨도 블랙홀 없이 반대쪽으로 우회됨. Hub 링크 장애 시험에서 자동 복구 확인 | [DC1 Hub 검증](../verification/dc1/04-dci-hub-ebgp.md) |
| VRF를 TENANT-A, PARTNER, BR1 3개로 분리하고 DC1과 DC2는 서로 import하지 않음 | DC1과 DC2는 서로 통신하지 않고 Branch만 양쪽과 통신. 물리 분리가 아니라 VRF와 RT로 하는 논리적 분리 | [VRF 검증](../verification/core/05-vrf.md) |
| BGW가 자기 대역(192.168.50.0/24, 192.168.60.0/24)만 PE3에 광고(`prefix-list`) | BR1을 거쳐 DC1과 DC2가 서로 통신하는 경로(transit)가 생기지 않게 함 | [PE3 - BGW 검증](../verification/br/07-pe3-bgw-ebgp.md) |
| PE-CE는 모든 구역을 eBGP로 통일하고 `timers 3 9` | 구역마다 방식이 다르면 관리가 복잡하고, 링크 장애를 BGP hold로 감지 | [PE-CE 검증](../verification/core/07-pe-ce-ebgp.md) |
| VRRP master와 MSTP root를 같은 스위치로 일치 | 게이트웨이와 L2 root가 다르면 트래픽이 DSW 사이로 우회함 | [VRRP 검증](../verification/br/05-vrrp-svi.md) |

## 트래픽 경로 예

| 시험 | 경로 |
|---|---|
| Host A → Host F (DC1 → Branch) | leaf → border leaf → Hub → PE1 → MPLS L3VPN(VRF BR1) → PE3 → BGW → DSW → ASW1 → Host F. PE1 - PE3 구간은 VPN 레이블 1개(26) |
| Host E → Host F (DC2 → Branch) | CX → PE2 → MPLS L3VPN → PE3 → BGW → DSW → Host F |
| Host A → Host E (DC1 → DC2) | 경로 없음(정상). DC1과 DC2는 분리 |

## 2026-11-14 설계 변경

| 항목 | 변경 | 이유 |
|---|---|---|
| DC1 VLAN | 10(재무회계), 20(물류·생산·인사), 30(중앙 ERP DB), 99(관리, 고객사 요청 관리용 IP 대역) | 부서·용도별로 서버 영역을 나눔. VNI 10010·10020·10030·10099 |
| DC1 STP | MSTP region DC1, 인스턴스 1 = VLAN 10·20, 인스턴스 2 = VLAN 30·99 | VLAN이 4개로 늘어 인스턴스로 묶어 관리 |
| 개발지사, DC2 STP | 개발지사 rapid-pvst(VLAN 50 root DSW1, VLAN 60 root DSW2), DC2 rpvst | 단순 L2 구조라 RSTP 계열로 충분 |
| 호스트 연결 | Leaf 한 대에 단일 연결(Host A leaf1, B leaf2, C leaf3, D leaf4). 서버 쪽 포트채널·`mlag 10` 제거 | 호스트 구성 단순화. Leaf 장애 시 해당 호스트만 끊기는 것은 T4로 확인 |
| DC2 호스트 | Host D를 Host E로 이름 변경, CX1 `1/1/7` 직결 유지(시나리오: CX3 장비 문제로 임시 연결) | DC1에 Host D를 새로 둠 |
| BGW prefix-list | `PARTNER-TO-BR`에 192.168.30.0/24(seq 20), 192.168.99.0/24(seq 25) 추가 | 개발지사가 새 DC1 대역을 받도록 함. 적용 뒤 `clear ip bgp * soft in` 필요 |
