# 06. VLAN과 IP 대역 총괄

VLAN, VNI, IP 대역, AS 번호를 한곳에 정리한 문서

세부 값 우선순위: [02-ip-addressing](02-ip-addressing.md), 지역별 기준 문서

## 1. VLAN

| VLAN | 이름 | 적용 장비 (SVI) | 용도 | 서브넷 | 게이트웨이 | 호스트와 포트 |
|---|---|---|---|---|---|---|
| 10 | FINANCE | **leaf1~leaf4** (anycast gateway, L2VNI 10010) | 재무회계 | 192.168.10.0/24 | .1 (anycast, 4대 공유) | Host A .101 (leaf1 Et5) |
| 20 | LOGISTICS-HR | **leaf1~leaf4** (anycast gateway, L2VNI 10020) | 물류·생산·인사 | 192.168.20.0/24 | .1 (anycast, 4대 공유) | Host B .101 (leaf2 Et5) |
| 30 | ERP-DB | **leaf1~leaf4** (anycast gateway, L2VNI 10030) | 중앙 ERP DB | 192.168.30.0/24 | .1 (anycast, 4대 공유) | Host C .101 (leaf3 Et7) |
| 99 | MGMT | **leaf1~leaf4** (anycast gateway, L2VNI 10099) | 관리(고객사 요청 관리용 IP 대역, 개발지사에서 도달) | 192.168.99.0/24 | .1 (anycast, 4대 공유) | Host D .101 (leaf4 Et7) |
| 110 | APP-DC2 | **CX1, CX2** (SVI .2/.3, active gateway), **CX3**(L2) | DC2 서버 영역 | 192.168.110.0/24 | .1 (VSX active gateway) | Host E .101 (CX1 1/1/7, eth1) |
| 50 | BR-LAN50 | **DSW1, DSW2** (SVI .2/.3, VRRP), **ASW1**(L2) | Branch 사용자 LAN | 192.168.50.0/24 | VRRP VIP .1 | Host F .101 (ASW1 Gi1/0) |
| 60 | BR-LAN60 | **DSW1, DSW2** (SVI .2/.3, VRRP), **ASW1**(L2) | Branch 사용자 LAN | 192.168.60.0/24 | VRRP VIP .1 | Host G .101 (ASW1 Gi1/1) |
| 4094 | MLAG-PEER | **leaf1~leaf4** (쌍마다 다른 /31) | MLAG 제어 (trunk group MLAGPEER) | 10.1.254.0/31 (leaf1, leaf2), 10.1.254.2/31 (leaf3, leaf4) | - | - |
| 999 | NATIVE | 트렁크가 있는 모든 장비 (leaf1~4, CX1~3, DSW1·2, ASW1) | 모든 트렁크의 네이티브 VLAN. 호스트와 SVI는 없음 | - | - | - |
- VNI: L2VNI 10010(VLAN 10), 10020(VLAN 20), 10030(VLAN 30), 10099(VLAN 99), L3VNI 50001(VRF TENANT-A).
- DC1 STP는 MSTP(region DC1): 인스턴스 1 = VLAN 10, 20 / 인스턴스 2 = VLAN 30, 99. BR1과 DC2는 RSTP(BR1은 rapid-pvst, DC2는 rpvst)
- DC2는 VXLAN이 없어서 VLAN 110의 L2VNI(10110)는 **예약만 하고 쓰지 않음**.
- ASW1은 L2 스위치라 데이터 VLAN(50, 60)에는 SVI가 없고, 관리는 `Gi3/3`(access VLAN 100)의 `Vlan100` SVI(192.168.100.46). VLAN 100은 ASW1에만 있고 트렁크에 넣지 않음
- Host E는 `eth1`을 CX1 `1/1/7`(VLAN 110 access)에 연결. CX3 경유(`eth0`)는 AOS-CX 10.07 가상 이미지에서 `lag10` 위로 VLAN 110 데이터가 전달되지 않아 쓰지 않음 ([DC2 검증](../verification/dc2/05-active-gateway.md))

## 2. 대역별 용도

### 2-1. 테넌트와 관리 (192.168.0.0/16)

| 대역 | 용도 |
|---|---|
| 192.168.10.0/24, 20.0/24, 30.0/24, 99.0/24 | DC1 VLAN 10(재무회계), 20(물류·생산·인사), 30(중앙 ERP DB), 99(관리) |
| 192.168.110.0/24 | DC2 서버 VLAN 110 |
| 192.168.50.0/24, 60.0/24 | Branch LAN VLAN 50, 60 |
| 10.9.0.0/24 | DC1 장비 관리망(VLAN 900, 누리데이터 관리 전용, MGMT-SW1) |
| 10.9.1.0/24 | 코어 장비 관리망(VLAN 910, 누리텔레콤 전용, MGMT-SW2) |

관리 주소(DC1, 10.9.0.0/24): MGMT-RTR .1, spine1 .11, spine2 .12, leaf1 .21, leaf2 .22, leaf3 .23, leaf4 .24, border-leaf1 .25, border-leaf2 .26, MGMT-SW1 .2(Vlan900), MGMT-PC1 .10. 관리 주소(코어, 10.9.1.0/24): MGMT-RTR .1, MGMT-SW2 .2(Vlan910), MGMT-PC2 .10, PE1 .11, PE2 .12, PE3 .13. DC2·개발지사(CX, DSW, ASW1)와 Hub·BGW는 별도 관리망이 없어 콘솔로 접속. PE는 c7200의 `Gi6/0`을 관리 인터페이스(VRF MGMT)로 사용

### 2-2. 인프라 (10.0.0.0/8)

| 대역 | 용도 | 비고 |
|---|---|---|
| 10.0.0.0/24 | 코어와 엣지 라우터 Loopback0 | PE1~PE3 .11~.13, Hub1·2 .21·.22, BGW1·2 .31·.32, DSW1·2 .41·.42 |
| 10.0.10.0/24 | PE 코어 링크 | PE 삼각형 /31 3개 |
| 10.0.20.0/24 | DC2 PE-CE 링크 (VRF PARTNER) | PE2-CX1, PE2-CX2 (10.0.20.4~7) |
| 10.0.30.0/24 | PE1-Hub 링크 (VRF TENANT-A) | PE1-Hub1, PE1-Hub2 (10.0.30.0~3) |
| 10.0.31.0/24 | border leaf-Hub 연동 링크 | border-leaf1-Hub1(10.0.31.0/31), border-leaf2-Hub2(10.0.31.2/31) |
| 10.0.60.0/24 | Branch PE-CE 링크 (VRF BR1) | PE3-BGW1, PE3-BGW2 |
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
| Host A | 192.168.10.101 | 192.168.10.1 | 10 |
| Host B | 192.168.20.101 | 192.168.20.1 | 20 |
| Host C | 192.168.30.101 | 192.168.30.1 | 30 |
| Host D | 192.168.99.101 | 192.168.99.1 | 99 |
| Host E | 192.168.110.101 | 192.168.110.1 | 110 |
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

- 192.168.x.0/24 테넌트 대역과 관리망(10.9.0.0/24, 10.9.1.0/24)은 겹치지 않음
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
