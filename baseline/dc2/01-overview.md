# DC2 개요

기준 문서: [00-overview](../../00-overview/README.md)

이 문서는 DC2 관련 내용만 발췌한 것. 값이 다르면 00-overview 우선

## 1. 개요

| 항목 | 내용 |
|---|---|
| 역할 | VSX 쌍(분배, border 겸용) + access 스위치 구조의 데이터센터 |
| 장비 | ArubaOS-CX 10.07 시뮬레이터 3대 (CX1, CX2, CX3), 호스트 1대 (D) |
| 멀티호밍 | VSX (ISL 2링크 + keepalive 1링크), CX3은 VSX LAG(4링크)로 연결 |
| 게이트웨이 | VSX active gateway |
| 라우팅 | CX1, CX2가 PE2와 eBGP (AS 65201 ↔ AS 65000) |
| 참고 | VSX 쌍은 단일 VTEP이라 EVPN-VXLAN 대상이 없음. EVPN-VXLAN은 DC1에서 시연 |

## 2. 포트 매핑

| 노드 | 포트 | 계층 | 상대 노드 | 상대 포트 |
|---|---|---|---|---|
| CX1 | 1/1/1 | O (DCI) | PE2 | Gi2/0 |
| CX1 | 1/1/2-3 | U (VSX ISL) | CX2 | 1/1/2-3 |
| CX1 | 1/1/4 | U (VSX keepalive) | CX2 | 1/1/4 |
| CX1 | 1/1/5-6 | S (VSX LAG) | CX3 | 1/1/1-2 |
| CX2 | 1/1/1 | O (DCI) | PE2 | Gi3/0 |
| CX2 | 1/1/5-6 | S (VSX LAG) | CX3 | 1/1/3-4 |
| CX1 | 1/1/7 | A | Host D | eth1 |
| CX3 | 1/1/5 | A (미사용) | Host D | eth0 |

관리 포트는 MGMT-SW Et7 ~ Et9에 연결

- Host D는 `eth1`을 CX1 `1/1/7`에 연결해 사용. CX3 경유(`eth0`)는 이 이미지(AOS-CX Virtual 10.07)에서 `lag10` 위로 VLAN 110 데이터가 전달되지 않아 쓰지 않음 ([active gateway 검증](../../verification/dc2/05-active-gateway.md))

## 3. IP 주소

| 노드 | Mgmt | Loopback0 | 비고 |
|---|---|---|---|
| CX1 | 192.168.100.41 | 10.2.0.1/32 | VSX 쌍 |
| CX2 | 192.168.100.42 | 10.2.0.2/32 | VSX 쌍 |
| CX3 | 192.168.100.43 | - | L2 전용 (access) |

| 링크 | 서브넷 | A측 | B측 | VRF |
|---|---|---|---|---|
| PE2 - CX1 (DCI) | 10.0.20.4/31 | PE2 .4 | CX1 .5 | TENANT-A |
| PE2 - CX2 (DCI) | 10.0.20.6/31 | PE2 .6 | CX2 .7 | TENANT-A |
| CX1 - CX2 (VSX keepalive) | 10.2.254.0/31 | CX1 .0 | CX2 .1 | 전용 |

## 7. 확인이 필요한 항목

- Aruba CX 시뮬레이터에서 vCPU 1개와 RAM 축소의 안정성 (기본 2 vCPU, 4096MB)
- 시뮬레이터에서 VSX, QoS 기능 범위
