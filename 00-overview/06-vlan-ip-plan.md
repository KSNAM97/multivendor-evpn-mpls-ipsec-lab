# 06. VLAN과 IP 대역 총괄

VLAN, VNI, IP 대역, AS 번호를 한곳에 정리한 문서

세부 값 우선순위: [02-ip-addressing](02-ip-addressing.md), 지역별 기준 문서

## 1. VLAN

| VLAN | 이름 | 적용 장비 (SVI) | 용도 | 서브넷 | 게이트웨이 | 호스트와 포트 |
|---|---|---|---|---|---|---|
| 10 | APP | **leaf1, leaf2, leaf3, leaf4** (anycast gateway, L2VNI 10010) | DC1 서버 영역 | 192.168.10.0/24 | .1 (anycast, 4대 공유) | Host A .101 (leaf1 Et5 + leaf2 Et5), Host B .102 (leaf3 Et7) |
| 20 | DB | **leaf3, leaf4** (anycast gateway, L2VNI 10020). leaf1, leaf2에는 없음 | DC1 서버 영역 | 192.168.20.0/24 | .1 (anycast, 2대 공유) | Host C .101 (leaf4 Et7) |
| 110 | APP-DC2 | **CX1, CX2** (SVI .2/.3, active gateway), **CX3**(L2) | DC2 서버 영역 | 192.168.110.0/24 | .1 (VSX active gateway) | Host D .101 (CX1 1/1/7, eth1) |
| 50 | BR-LAN50 | **DSW1, DSW2** (SVI .2/.3, VRRP), **ASW1**(L2) | Branch 사용자 LAN | 192.168.50.0/24 | VRRP VIP .1 | Host F .101 (ASW1 Gi1/0) |
| 60 | BR-LAN60 | **DSW1, DSW2** (SVI .2/.3, VRRP), **ASW1**(L2) | Branch 사용자 LAN | 192.168.60.0/24 | VRRP VIP .1 | Host G .101 (ASW1 Gi1/1) |
| 4094 | MLAG-PEER | **leaf1~leaf4** (쌍마다 다른 /31) | MLAG 제어 (trunk group MLAGPEER) | 10.1.254.0/31 (leaf1, leaf2), 10.1.254.2/31 (leaf3, leaf4) | - | - |
| 999 | NATIVE | 트렁크가 있는 모든 장비 (leaf1~4, CX1~3, DSW1·2, ASW1) | 모든 트렁크의 네이티브 VLAN. 호스트와 SVI는 없음 | - | - | - |
- VNI: L2VNI 10010(VLAN 10), 10020(VLAN 20), L3VNI 50001(VRF TENANT-A).
- DC2는 VXLAN이 없어서 VLAN 110의 L2VNI(10110)는 **예약만 하고 쓰지 않음**.
- ASW1은 L2 스위치라 데이터 VLAN(50, 60)에는 SVI가 없고, 관리는 `Gi3/3`(access VLAN 100)의 `Vlan100` SVI(192.168.100.46). VLAN 100은 ASW1에만 있고 트렁크에 넣지 않음
- Host D는 `eth1`을 CX1 `1/1/7`(VLAN 110 access)에 연결. CX3 경유(`eth0`)는 AOS-CX 10.07 가상 이미지에서 `lag10` 위로 VLAN 110 데이터가 전달되지 않아 쓰지 않음 ([DC2 검증](../verification/dc2/05-active-gateway.md))

## 2. 대역별 용도

### 2-1. 테넌트와 관리 (192.168.0.0/16)

| 대역 | 용도 |
|---|---|
| 192.168.10.0/24, 20.0/24 | DC1 서버 VLAN 10, 20 |
| 192.168.110.0/24 | DC2 서버 VLAN 110 |
| 192.168.50.0/24, 60.0/24 | Branch LAN VLAN 50, 60 |
| 192.168.100.0/24 | 장비 관리망 (MGMT-SW) |

관리 주소: spine1 .11, spine2 .12, leaf1 .21, leaf2 .22, leaf3 .23, leaf4 .24, CX1 .41, CX2 .42, CX3 .43. DSW1 .44, DSW2 .45, ASW1 .46. (c7200은 관리 포트가 없어 콘솔로 접속하고 관리망 주소가 없음.)

### 2-2. 인프라 (10.0.0.0/8)

| 대역 | 용도 | 비고 |
|---|---|---|
| 10.0.0.0/24 | 코어와 엣지 라우터 Loopback0 | PE1~PE3 .11~.13, Hub1·2 .21·.22, BGW1·2 .31·.32, DSW1·2 .41·.42 |
| 10.0.10.0/24 | PE 코어 링크 | PE 삼각형 /31 3개 |
| 10.0.20.0/24 | DCI 링크 (VRF TENANT-A) | PE1-leaf3, PE1-leaf4, PE2-CX1, PE2-CX2 |
| 10.0.30.0/24 | WAN 언더레이 링크 (VRF WAN-UL) | PE1-Hub1·2, PE3-BGW1·2. 터널 source, destination |
| 10.0.31.0/24 | leaf-Hub 연동 링크 | leaf3-Hub1, leaf4-Hub2 |
| 10.0.40.0/24 | GRE 터널 주소 | Tunnel0, Tunnel1 |
| 10.50.0.0/24 | Branch 라우티드 링크 | BGW1-DSW1, BGW2-DSW2 |
| 10.1.0.0/24 | DC1 Loopback0 | spine .1·.2, leaf .11~.14 |
| 10.1.1.0/24 | DC1 VTEP (Loopback1) | leaf1·2 10.1.1.12 공유, leaf3·4 10.1.1.34 공유 |
| 10.1.10.0/24 | DC1 spine-leaf 링크 | /31 8개 |
| 10.1.254.0/24 | DC1 MLAG peer (Vlan4094) | /31 2개 |
| 10.2.0.0/24 | DC2 Loopback0 | CX1 .1, CX2 .2 |
| 10.2.254.0/24 | DC2 VSX keepalive | 10.2.254.0/31 |
| 10.2.1.0/24, 10.2.10.0/24 | DC2 VTEP, spine 링크 | **현재 미사용** (DC2에 VXLAN과 spine이 없음) |
| 10.99.0.0/16 | 기능 시험 전용 | 구축 때는 쓰지 않음 |

Juniper를 뺐으므로 10.3.0.0/16은 **비어 있음**(향후 확장용).

## 3. 호스트 주소 요약

| 호스트 | 주소 | 게이트웨이 | VLAN |
|---|---|---|---|
| Host A | 192.168.10.101 (bond0) | 192.168.10.1 | 10 |
| Host B | 192.168.10.102 | 192.168.10.1 | 10 |
| Host C | 192.168.20.101 | 192.168.20.1 | 20 |
| Host D | 192.168.110.101 | 192.168.110.1 | 110 |
| Host F | 192.168.50.101 | 192.168.50.1 | 50 |
| Host G | 192.168.60.101 | 192.168.60.1 | 60 |

## 4. AS 번호

| 도메인 | AS |
|---|---|
| MPLS 코어 (PE1~PE3) | 65000 |
| DC1 (spine1, spine2는 Route Reflector, leaf1~4) | 65100 |
| DC2 VSX 쌍 (CX1, CX2) | 65201 |
| Hub1, Hub2 | 65010 |
| BGW1, BGW2 | 65020 |

## 5. 충돌 점검

- 192.168.x.0/24 테넌트 대역과 관리망(192.168.100.0/24)은 겹치지 않음
- 10.0.x, 10.1.x, 10.2.x 대역은 서로 겹치지 않음
- `10.50.0.0/24`(Branch 링크)와 `192.168.50.0/24`(VLAN 50 LAN)는 번호가 같아 보이지만 **다른 대역**. 혼동하지 않게 문서에서 항상 전체 주소로 적음
- 테넌트 서브넷은 VRF TENANT-A 안에서 모두 달라서 DC 간 경로가 겹치지 않음

## 6. 새로 추가할 때의 규칙

| 필요 | 사용할 대역 |
|---|---|
| 새 서버 VLAN | 192.168.<VLAN 번호>.0/24 (예: VLAN 30 -> 192.168.30.0/24) |
| 새 점대점 링크 | 해당 지역 링크 대역의 다음 /31 |
| 새 루프백 | 해당 지역 Loopback 대역의 다음 주소 |
| 새 지역 | 10.<지역 번호>.0.0/16 (3번 이후: 10.3은 비어 있음) |
