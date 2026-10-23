# MPLS 코어 개요

기준 문서: [00-overview](../../00-overview/README.md)

이 문서는 코어(PE1~PE3) 관련 내용만 발췌한 것. 값이 다르면 00-overview 우선

## 1. 개요

| 항목 | 내용 |
|---|---|
| 역할 | DC1, DC2, Branch를 잇는 MPLS L3VPN 코어 |
| 장비 | Cisco c7200 3대 (PE1, PE2, PE3), P 라우터 없이 삼각형으로 연결 |
| IGP | OSPF area 0 |
| 레이블 | MPLS, LDP (코어 링크) |
| VPN | MP-BGP VPNv4 (PE 간 iBGP full mesh, AS 65000) |
| PE-CE | eBGP (AS 65000 ↔ DC1 AS 65100, DC2 AS 65201, WAN-UL은 고정 경로 또는 eBGP) |
| QoS | DSCP를 MPLS TC로 매핑, PE에서 집행 |

## 2. 포트 매핑

| 노드 | 포트 | 계층 | 상대 노드 | 상대 포트 |
|---|---|---|---|---|
| PE1 | Gi0/0 | W (코어) | PE2 | Gi0/0 |
| PE1 | Gi1/0 | W (코어) | PE3 | Gi0/0 |
| PE1 | Gi2/0 | O (DCI) | leaf3 (Arista) | Et5 |
| PE1 | Gi3/0 | O (DCI) | leaf4 (Arista) | Et5 |
| PE1 | Gi4/0 | W (WAN-UL) | Hub1 | Gi0/0 |
| PE1 | Gi5/0 | W (WAN-UL) | Hub2 | Gi0/0 |
| PE2 | Gi1/0 | W (코어) | PE3 | Gi1/0 |
| PE2 | Gi2/0 | O (DCI) | CX1 (Aruba) | 1/1/1 |
| PE2 | Gi3/0 | O (DCI) | CX2 (Aruba) | 1/1/1 |
| PE3 | Gi2/0 | W (WAN-UL) | BGW1 | Gi0/0 |
| PE3 | Gi3/0 | W (WAN-UL) | BGW2 | Gi0/0 |

c7200 슬롯 구성: `slot0 = C7200-IO-GE-E (Gi0/0)`, `slot1~5 = PA-GE`. 관리 포트가 없으므로 GNS3 콘솔로 접속

## 3. IP 주소

| 노드 | Loopback0 |
|---|---|
| PE1 | 10.0.0.11/32 |
| PE2 | 10.0.0.12/32 |
| PE3 | 10.0.0.13/32 |

| 링크 | 서브넷 | A측 | B측 | VRF |
|---|---|---|---|---|
| PE1 - PE2 | 10.0.10.0/31 | PE1 .0 | PE2 .1 | global |
| PE1 - PE3 | 10.0.10.2/31 | PE1 .2 | PE3 .3 | global |
| PE2 - PE3 | 10.0.10.4/31 | PE2 .4 | PE3 .5 | global |
| PE1 - leaf3 | 10.0.20.0/31 | PE1 .0 | leaf3 .1 | TENANT-A |
| PE1 - leaf4 | 10.0.20.2/31 | PE1 .2 | leaf4 .3 | TENANT-A |
| PE2 - CX1 | 10.0.20.4/31 | PE2 .4 | CX1 .5 | TENANT-A |
| PE2 - CX2 | 10.0.20.6/31 | PE2 .6 | CX2 .7 | TENANT-A |
| PE1 - Hub1 | 10.0.30.0/31 | PE1 .0 | Hub1 .1 | WAN-UL |
| PE1 - Hub2 | 10.0.30.2/31 | PE1 .2 | Hub2 .3 | WAN-UL |
| PE3 - BGW1 | 10.0.30.4/31 | PE3 .4 | BGW1 .5 | WAN-UL |
| PE3 - BGW2 | 10.0.30.6/31 | PE3 .6 | BGW2 .7 | WAN-UL |

## 7. 확인이 필요한 항목

- c7200 이미지의 MPLS/LDP, VRF 지원: 확인됨(IOS 12.4(24)T5, `ip vrf` 사용)
- c7200 슬롯 구성: PE1, PE2는 최대 6포트가 필요
- Dynamips Idle-PC 설정 여부(미설정 시 CPU 부담이 큼).
