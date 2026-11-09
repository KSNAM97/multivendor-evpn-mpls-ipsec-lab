# Hub 설정 가이드 (Hub1, Hub2)

Hub는 DC1의 외부 연결 장비. border leaf(border-leaf1, border-leaf2)에서 받은 TENANT-A 경로를 PE1에 전달하고, PE1에서 받은 다른 구역 경로를 border leaf에 전달함. Hub 설정을 여러 문서에서 모아 Hub 기준 순서로 정리한 문서

값 우선순위: [IP와 포트 매칭표](../00-overview/07-ip-port-matrix.md), 각 기준 문서

## 역할과 위치

| 항목 | Hub1 | Hub2 |
|---|---|---|
| 장비 | Cisco c7200 (콘솔로만 접속, 관리망 없음) | 같음 |
| 호스트 이름 | `HUB1` | `HUB2` |
| 설정 파일 | `configs/dc1/Hub1.ios` | `configs/dc1/Hub2.ios` |
| AS | 65010 | 65010 |
| loopback0 주소 | 10.0.0.21 | 10.0.0.22 |
| OSPF | 사용하지 않음 | 사용하지 않음 |
| BGP router-id | 10.0.1.21 | 10.0.1.22 |
| 연결하는 border leaf | border-leaf1(`Gi1/0`) | border-leaf2(`Gi1/0`) |

border leaf는 Hub와 1대1로 연결됨(교차 연결 없음). 두 border leaf가 VTEP을 각각 가지므로 한쪽 Hub 경로가 끊겨도 반대쪽 border leaf와 Hub로 경로가 이어짐

## 연결 (포트, IP)

| 장비 | 포트 | IP | 상대 | 용도 |
|---|---|---|---|---|
| Hub1 | `gigabitethernet0/0` | 10.0.30.1/31 | PE1 `Gi2/0` (.0) | PE-CE (PE1 쪽은 VRF TENANT-A) |
| Hub1 | `gigabitethernet1/0` | 10.0.31.1/31 | border-leaf1 `ethernet1` (.0) | border leaf 연동 (border leaf 쪽은 VRF TENANT-A) |
| Hub2 | `gigabitethernet0/0` | 10.0.30.3/31 | PE1 `Gi5/0` (.2) | PE-CE |
| Hub2 | `gigabitethernet1/0` | 10.0.31.3/31 | border-leaf2 `ethernet1` (.2) | border leaf 연동 |

## 설정 순서

Hub는 PE1, border leaf의 설정이 어느 정도 되어 있어야 상대 쪽을 확인할 수 있음. 아래 순서대로 진행

| 순서 | 할 일 | 값 | 참조 문서 | 확인 명령 |
|---|---|---|---|---|
| 1 | 기본 설정 | `hostname HUB1`, 권한 모드, domain-lookup 끄기, 콘솔 세션 | [Hub 기본 설정 샘플](../samples/dc1/03-base-hub.md) | 콘솔 로그인 |
| 2 | 인터페이스 IP | 위 연결 표의 `gigabitethernet0/0`, `1/0`, `loopback0` | [IP와 포트 매칭표](../00-overview/07-ip-port-matrix.md) | `show ip interface brief` (PE1, border leaf 쪽으로 ping) |
| 3 | PE1, border leaf와 eBGP | Hub AS 65010. PE1(AS 65000), border leaf(AS 65100). Hub1 이웃 `10.0.30.0`(PE1), `10.0.31.0`(border-leaf1). Hub2 이웃 `10.0.30.2`(PE1), `10.0.31.2`(border-leaf2) | [기준](../baseline/dc1/06-dci-hub-ebgp.md), [PE1 쪽 기준](../baseline/core/07-pe-ce-ebgp.md) | `show ip bgp summary` |
| 4 | 협상 조건 통일 | BGP `timers 3 9`, BGP router-id는 OSPF(loopback0)와 다른 값 | [협상 조건 통일](../00-overview/03-protocol-matrix.md) | `show ip bgp neighbors` |
| 5 | 저장 | `write memory`, 컨피그를 `configs/dc1/`에 보관 | | |

## 확인 (완료 기준)

| 확인 | 기대 결과 |
|---|---|
| PE1과 eBGP | PE1(Hub1은 `10.0.30.0`, Hub2는 `10.0.30.2`)과의 세션이 **Established** |
| border leaf와 eBGP | border leaf 1개(Hub1은 `10.0.31.0`, Hub2는 `10.0.31.2`)와의 세션이 **Established**이고 TENANT-A 경로(192.168.10.0/24 등)를 받음 |
| 이중 경로 | Hub 한쪽 링크(PE1 `Gi2/0` 또는 `Gi5/0`)를 내려도 반대쪽 Hub로 통신이 유지(복구 시험은 [장애 시험](../verification/dc1/04-dci-hub-ebgp.md) 참고) |
| 통신 | Host A -> Host F `ping`이 되고 `traceroute`가 border leaf와 Hub를 지남 |

## 결정된 항목

1. **전용 border leaf를 Hub와 1대1로 연결**: border-leaf1·2가 MLAG 없이 VTEP을 각각 가지므로 교차 연결 없이도 한쪽 경로 장애 시 반대쪽으로 우회됨. 서버 접속 leaf(leaf1~4)에는 Hub 연결이 없음
2. **PE1 - Hub는 eBGP(PE-CE)**: Hub가 PE1의 VRF TENANT-A와 eBGP를 맺고 DC1 경로를 전달. Hub에 VRF가 없고 정적 경로나 터널은 쓰지 않음
