# DC1 개요

기준 문서: [00-overview](../../00-overview/README.md)

이 문서는 DC1 관련 내용만 발췌한 것. 값이 다르면 00-overview 우선

## 1. 개요

| 항목 | 내용 |
|---|---|
| 역할 | EVPN-VXLAN 패브릭(L2VNI, L3VNI), MLAG 이중화, WAN 출구(Hub) 연동 |
| 장비 | Arista vEOS 6대 (spine1, spine2, leaf1~leaf4), Cisco c7200 2대 (Hub1, Hub2), 호스트 3대 (A, B, C) |
| Underlay | OSPF process 1, area 0, 점대점 /31 |
| Overlay | iBGP EVPN (DC1 전체 AS 65100, spine1·2가 Route Reflector, leaf는 client), 루프백 간 |
| 멀티호밍 | MLAG 2쌍: leaf1/leaf2(서버 leaf), leaf3/leaf4(border leaf) |
| 게이트웨이 | anycast gateway (virtual MAC `00:1c:73:00:00:99`) |

## 2. 포트 매핑

| 노드 | 포트 | 계층 | 상대 노드 | 상대 포트 |
|---|---|---|---|---|
| spine1 | Et1 | U | leaf1 | Et1 |
| spine1 | Et2 | U | leaf2 | Et1 |
| spine1 | Et3 | U | leaf3 | Et1 |
| spine1 | Et4 | U | leaf4 | Et1 |
| spine2 | Et1 | U | leaf1 | Et2 |
| spine2 | Et2 | U | leaf2 | Et2 |
| spine2 | Et3 | U | leaf3 | Et2 |
| spine2 | Et4 | U | leaf4 | Et2 |
| leaf1 | Et3-4 | U (MLAG peer-link) | leaf2 | Et3-4 |
| leaf1 | Et5 | A | Host A | eth0 |
| leaf2 | Et5 | A | Host A | eth1 |
| leaf3 | Et3-4 | U (MLAG peer-link) | leaf4 | Et3-4 |
| leaf3 | Et5 | O (DCI, VRF TENANT-A) | PE1 | Gi2/0 |
| leaf3 | Et6 | O (Hub1 연동, VRF TENANT-A) | Hub1 | Gi1/0 |
| leaf3 | Et7 | A | Host B | eth0 |
| leaf4 | Et5 | O (DCI, VRF TENANT-A) | PE1 | Gi3/0 |
| leaf4 | Et6 | O (Hub2 연동, VRF TENANT-A) | Hub2 | Gi1/0 |
| leaf4 | Et7 | A | Host C | eth0 |
| Hub1 | Gi0/0 | W (WAN-UL) | PE1 | Gi4/0 |
| Hub2 | Gi0/0 | W (WAN-UL) | PE1 | Gi5/0 |

GNS3 어댑터 수(관리 포함): spine 5, leaf1/leaf2 6, leaf3/leaf4 8. 관리 포트는 MGMT-SW Et1 ~ Et6에 연결

## 3. IP 주소

### 3-1. 관리와 루프백

| 노드 | Mgmt | Loopback0 | VTEP (Loopback1) |
|---|---|---|---|
| spine1 | 192.168.100.11 | 10.1.0.1/32 | - |
| spine2 | 192.168.100.12 | 10.1.0.2/32 | - |
| leaf1 | 192.168.100.21 | 10.1.0.11/32 | 10.1.1.12/32 (leaf2와 공유) |
| leaf2 | 192.168.100.22 | 10.1.0.12/32 | 10.1.1.12/32 (leaf1과 공유) |
| leaf3 | 192.168.100.23 | 10.1.0.13/32 | 10.1.1.34/32 (leaf4와 공유) |
| leaf4 | 192.168.100.24 | 10.1.0.14/32 | 10.1.1.34/32 (leaf3과 공유) |
| Hub1 | (콘솔) | 10.0.0.21/32 | - |
| Hub2 | (콘솔) | 10.0.0.22/32 | - |

## 7. 제약

- Arista vEOS는 ACL은 만들 수 있지만 `ip access-group ... in/out`이 `% Unavailable command (not supported on this hardware platform)`로 거부됨(확인됨). QoS 분류와 패킷 필터에는 쓰지 않고, 이런 시연은 Cisco나 Aruba에서 함
- vEOS RAM 축소의 안정성은 설정 투입 후에도 확인이 필요
