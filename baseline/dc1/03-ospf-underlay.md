# OSPF underlay

VTEP과 BGP 루프백의 도달성을 만드는 underlay

기준 문서: [00-overview](../../00-overview/README.md)

## 설계값

| 항목 | 값 |
|---|---|
| 프로세스 | OSPF 1, area 0.0.0.0 |
| 네트워크 타입 | point-to-point (/31 링크) |
| hello, dead 타이머 | **1초, 4초** (기본 10초, 40초). 링크 인터페이스 양쪽 같은 값 |
| 광고 대상 | 점대점 링크(spine-leaf /31), `loopback0`, `loopback1`(VTEP, leaf만) |
| passive | `loopback0`(전 장비), `loopback1`(leaf) |
| max-lsa | 12000 |

기본값이라 설정하지 않는 것: `no passive-interface default`(기본이 passive 아님)와 요약(`summary-address`, 요약을 쓰지 않음).

## OSPF router-id (BGP router-id와 다른 값)

| 노드 | OSPF router-id (Loopback0) |
|---|---|
| spine1 | 10.1.0.1 |
| spine2 | 10.1.0.2 |
| leaf1 | 10.1.0.11 |
| leaf2 | 10.1.0.12 |
| leaf3 | 10.1.0.13 |
| leaf4 | 10.1.0.14 |

## OSPF에 넣는 인터페이스

각 인터페이스에 `ip ospf area 0.0.0.0`을 직접 지정함(network 문은 쓰지 않음). 점대점 링크는 `ip ospf network point-to-point`와 타이머(`ip ospf hello-interval 1`, `ip ospf dead-interval 4`)도 같이 줌

| 장비 | 인터페이스 | 용도 | 네트워크 타입 | passive |
|---|---|---|---|---|
| spine1, spine2 | `loopback0` | OSPF router-id, BGP 출발지 | loopback | **passive** |
| spine1, spine2 | `ethernet1` ~ `ethernet4` | leaf1 ~ leaf4 링크 | point-to-point, hello 1 / dead 4 | 아니오 (이웃을 맺음) |
| leaf1 ~ leaf4 | `loopback0` | OSPF router-id, BGP 출발지 | loopback | **passive** |
| leaf1 ~ leaf4 | `loopback1` | VTEP (MLAG 쌍이 같은 주소 공유) | loopback | **passive** |
| leaf1 ~ leaf4 | `ethernet1`, `ethernet2` | spine1, spine2 링크 | point-to-point, hello 1 / dead 4 | 아니오 (이웃을 맺음) |

**OSPF에 넣지 않는 인터페이스**

| 인터페이스 | 이유 |
|---|---|
| `management1` | 관리망(192.168.100.0/24)은 데이터 경로와 분리 |
| `vlan10`, `vlan20` (SVI) | 테넌트 경로는 EVPN으로 전달 (VRF TENANT-A) |
| `vlan4094` | MLAG 제어 전용. 필요 시 우회 경로용으로 추가 검토 |
| `port-channel1`, `ethernet3`, `ethernet4` | MLAG 피어 링크 (L2) |
| leaf3, leaf4의 `ethernet5`, `ethernet6` | DCI, Hub 링크 (VRF TENANT-A, 이후 단계에서 eBGP) |
| `ethernet5`, `ethernet7` (호스트 포트) | L2 access |

passive 인터페이스는 OSPF 광고는 되지만 hello를 보내지 않아서 이웃이 맺어지지 않음. 루프백은 이웃이 없으므로 passive로 두는 것이 맞음

## 링크 (/31, 앞 주소가 A측)

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

## 이중화와 부하 분산

- leaf마다 spine1, spine2로 두 경로가 생겨 ECMP가 됨
- 링크가 끊기면 dead 타이머 4초 안에 이웃이 내려가고 남은 경로로 수렴