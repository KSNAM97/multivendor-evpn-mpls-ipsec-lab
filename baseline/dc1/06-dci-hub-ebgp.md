# DC1 외부 연결: border leaf - Hub - PE1 (eBGP)

전용 border leaf(border-leaf1, border-leaf2)가 Hub를 거쳐 MPLS 코어(PE1)에 연결되는 부분. 서버 접속 leaf(leaf1~4)는 Hub에 직접 연결하지 않고, 외부 경로는 border leaf가 EVPN type-5로 leaf에 전달함

기준 문서: [00-overview](../../00-overview/README.md)

## 구조

- border-leaf1은 Hub1에, border-leaf2는 Hub2에 1대1로 연결(교차 연결 없음)
- 두 border leaf는 MLAG 없이 VTEP(10.1.1.15, 10.1.1.16)을 각각 가짐. 같은 VTEP을 공유하지 않으므로 한쪽 Hub 경로가 끊겨도 반대쪽 border leaf로 경로가 이어지고 블랙홀이 생기지 않음
- leaf에서는 같은 외부 경로가 두 VTEP(border-leaf1, border-leaf2)에서 오는 ECMP로 보임

## 링크

| 링크                            | 서브넷          | A측              | B측       | VRF                                      | 방식   |
| ----------------------------- | ------------ | --------------- | -------- | ---------------------------------------- | ---- |
| PE1 Gi2/0 - Hub1 Gi0/0        | 10.0.30.0/31 | PE1 .0          | Hub1 .1  | PE1 쪽 TENANT-A (Hub는 VRF 없음)            | eBGP |
| PE1 Gi5/0 - Hub2 Gi0/0        | 10.0.30.2/31 | PE1 .2          | Hub2 .3  | PE1 쪽 TENANT-A (Hub는 VRF 없음)            | eBGP |
| border-leaf1 Et1 - Hub1 Gi1/0 | 10.0.31.0/31 | border-leaf1 .0 | Hub1 .1  | TENANT-A (border leaf 쪽만, Hub는 VRF 없음)   | eBGP |
| border-leaf2 Et1 - Hub2 Gi1/0 | 10.0.31.2/31 | border-leaf2 .2 | Hub2 .3  | TENANT-A (border leaf 쪽만, Hub는 VRF 없음)   | eBGP |

## eBGP

| 세션                             | 로컬 AS | 상대 AS | VRF      |
| ------------------------------ | ----- | ----- | -------- |
| border-leaf1, 2 - Hub (border leaf 쪽) | 65100 | 65010 | TENANT-A |
| Hub - border-leaf1, 2 (Hub 쪽)        | 65010 | 65100 | 없음 (전역)  |
| Hub1, Hub2 - PE1 (Hub 쪽)          | 65010 | 65000 | 없음 (전역)  |
| PE1 - Hub1, Hub2 (PE 쪽)          | 65000 | 65010 | TENANT-A |

## border leaf EVPN

| 항목 | 값 |
|---|---|
| iBGP EVPN | spine1·2(Route Reflector)와 iBGP(AS 65100), `send-community extended` |
| VRF TENANT-A | RD 10.1.2.15:50001(border-leaf1), 10.1.2.16:50001(border-leaf2), route-target 50001:50001 import·export |
| VXLAN | `vxlan vrf TENANT-A vni 50001`, VTEP `loopback1` (10.1.1.15, 10.1.1.16) |
| 역할 | Hub에서 받은 Branch·DC2 방향 경로를 EVPN type-5로 leaf에 광고, leaf의 TENANT-A 경로를 Hub에 광고 |

## Hub 주소 정리

| 장비 | 인터페이스 | 주소 | 상대 |
| ---- | ---------- | ---- | ---- |
| Hub1 | `gigabitethernet 0/0` | 10.0.30.1/31 | PE1 `Gi2/0` |
| Hub1 | `gigabitethernet 1/0` | 10.0.31.1/31 | border-leaf1 `ethernet1` |
| Hub2 | `gigabitethernet 0/0` | 10.0.30.3/31 | PE1 `Gi5/0` |
| Hub2 | `gigabitethernet 1/0` | 10.0.31.3/31 | border-leaf2 `ethernet1` |
| Hub1, Hub2 | BGP router-id | 10.0.1.21, 10.0.1.22 | loopback0(10.0.0.21, 10.0.0.22)과 다른 대역 |

## 이중화

- DC1 외부 출구는 border-leaf1-Hub1 경로와 border-leaf2-Hub2 경로 두 개이고, PE1에서 두 Hub로 ECMP
- Hub와 PE1 링크 한쪽이 끊기면 반대쪽 경로로 자동 우회. 측정 결과는 [검증](../../verification/dc1/04-dci-hub-ebgp.md) 참고: PE1 `Gi2/0`(Hub1 링크) 차단 시 300/300 응답, `Gi5/0`(Hub2 링크) 차단 시 47개(약 9.4초) 손실 후 자동 복구
- BGP 타이머는 DC1 iBGP와 같은 **keepalive 30초, hold 90초**(`timers 30 90`)로 통일. border leaf와 Hub, PE1과 Hub 양쪽에 같은 값을 줌
