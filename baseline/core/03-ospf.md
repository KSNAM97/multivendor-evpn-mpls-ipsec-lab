# OSPF

PE 3대가 삼각형으로 연결된 MPLS 코어의 IGP. 루프백(LDP, iBGP 출발지) 도달성을 만드는 단계

기준 문서: [00-overview](../../00-overview/README.md)

## 설계값

| 항목 | 값 |
|---|---|
| IGP | OSPF 1, area 0 |
| router-id | Loopback0 주소 (PE1 10.0.0.11, PE2 10.0.0.12, PE3 10.0.0.13). BGP router-id(10.0.1.x)와 다름 |
| 네트워크 타입 | point-to-point (/31 링크) |
| hello, dead 타이머 | **1초, 4초** (기본 10초, 40초). 링크 양쪽 같은 값 |
| passive | `loopback 0` |
| 광고 대상 | Loopback0, 코어 링크(Gi0/0, Gi1/0) |

## OSPF에 넣는 인터페이스

각 인터페이스에 `ip ospf 1 area 0`을 직접 지정. 코어 링크는 `ip ospf network point-to-point`와 타이머(`ip ospf hello-interval 1`, `ip ospf dead-interval 4`)도 같이 줌

| 장비 | 인터페이스 | 용도 | passive |
|---|---|---|---|
| PE1 | `loopback 0` | router-id, LDP, BGP 출발지 | **passive** |
| PE1 | `gigabitethernet 0/0`, `gigabitethernet 1/0` | PE2, PE3 링크 | 아니오 (이웃을 맺음) |
| PE2 | `loopback 0` | 같음 | **passive** |
| PE2 | `gigabitethernet 0/0`, `gigabitethernet 1/0` | PE1, PE3 링크 | 아니오 |
| PE3 | `loopback 0` | 같음 | **passive** |
| PE3 | `gigabitethernet 0/0`, `gigabitethernet 1/0` | PE1, PE2 링크 | 아니오 |

**OSPF에 넣지 않는 인터페이스**: PE1의 `gigabitethernet 2/0`, `3/0`(DC1 leaf, VRF TENANT-A), `4/0`, `5/0`(Hub, VRF WAN-UL), PE2의 `2/0`, `3/0`(CX1·2, VRF TENANT-A), PE3의 `2/0`, `3/0`(BGW, VRF WAN-UL). 고객과 WAN 쪽 링크는 VRF 안에 있고 코어 OSPF에 광고하지 않음

## 루프백과 링크

| 노드 | Loopback0 |
|---|---|
| PE1 | 10.0.0.11/32 |
| PE2 | 10.0.0.12/32 |
| PE3 | 10.0.0.13/32 |

| 링크 | 서브넷 | A측 | B측 |
|---|---|---|---|
| PE1 - PE2 | 10.0.10.0/31 | .0 | .1 |
| PE1 - PE3 | 10.0.10.2/31 | .2 | .3 |
| PE2 - PE3 | 10.0.10.4/31 | .4 | .5 |

## 이중화와 경로

- PE 3대가 전부 서로 연결된 삼각형이라 코어 링크 하나가 끊겨도 다른 PE를 거쳐 우회
- 평상시 경로는 직결 링크(OSPF cost 1), 우회 경로(cost 2)는 장애 때만 사용. cost가 모든 링크에서 같아 ECMP는 생기지 않음
- 우회는 코어 링크 장애에만 해당. PE 장비 자체가 꺼지면 그 PE에 붙은 구간(PE1: DC1과 Hub, PE2: DC2, PE3: Branch)은 끊김
- 경로를 일부러 바꿔야 할 때만 해당 인터페이스에 `ip ospf cost <값>`을 사용 (지금은 불필요)

## 다음 단계

[MPLS와 LDP](04-mpls-ldp.md): OSPF로 loopback0 경로가 생긴 뒤에 레이블을 배포
