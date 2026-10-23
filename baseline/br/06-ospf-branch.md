# Branch OSPF

BGW와 DSW 사이 라우팅

기준 문서: [00-overview](../../00-overview/README.md)

## 설계값

| 항목 | 값 |
|---|---|
| 프로세스 | OSPF 1, area 0 |
| 네트워크 타입 | point-to-point (/31) |
| hello, dead 타이머 | **1초, 4초** (기본 10초, 40초). BGW-DSW 링크 양쪽 같은 값 |
| passive | `loopback0` (BGW, DSW), DSW의 `vlan50`, `vlan60` |

## OSPF에 넣는 인터페이스

| 장비 | 인터페이스 | 용도 | passive |
|---|---|---|---|
| BGW1, BGW2 | `loopback0` | router-id | **passive** |
| BGW1, BGW2 | `gigabitethernet1/0` | DSW1, DSW2 링크 (point-to-point, hello 1 / dead 4) | 아니오 (이웃을 맺음) |
| DSW1, DSW2 | `loopback0` | router-id | **passive** |
| DSW1, DSW2 | `gigabitethernet0/0` | BGW1, BGW2 링크 (point-to-point, hello 1 / dead 4) | 아니오 (이웃을 맺음) |
| DSW1, DSW2 | `vlan50`, `vlan60` (SVI) | Branch LAN(192.168.50.0/24, 192.168.60.0/24)을 광고 | **passive** (설계안, 확인 필요) |

**OSPF에 넣지 않는 인터페이스**: BGW의 `gigabitethernet0/0`(PE3 방향, VRF WAN-UL)과 터널(`tunnel0`, `tunnel1`), DSW의 L2 포트(`port-channel1~3`, `gigabitethernet0/1~3`, `1/0`), ASW1 전체(L2 스위치, 데이터 VLAN SVI 없음, 관리는 `Vlan100`). Branch LAN을 BGW가 Hub로 광고하려면 DSW의 SVI 서브넷이 OSPF에 들어 있어야 하므로 SVI를 passive로 포함하는 것이 설계안이며, 구현할 때 확인
| 노드 | OSPF router-id (Loopback0) |
|---|---|
| BGW1 | 10.0.0.31 |
| BGW2 | 10.0.0.32 |
| DSW1 | 10.0.0.41 |
| DSW2 | 10.0.0.42 |

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| BGW1 - DSW1 | 10.50.0.0/31 | .0 | .1 |
| BGW2 - DSW2 | 10.50.0.2/31 | .2 | .3 |
