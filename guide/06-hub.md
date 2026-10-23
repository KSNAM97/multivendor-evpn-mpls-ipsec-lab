# Hub 설정 가이드 (Hub1, Hub2)

Hub는 DC1의 WAN 출구. leaf3·4(border)에서 받은 TENANT-A 경로를 IPsec 터널로 Branch(BGW)에 전달하고, 반대 방향도 전달. Hub 설정을 여러 문서에서 모아 Hub 기준 순서로 정리한 문서

값 우선순위: [IP와 포트 매칭표](../00-overview/07-ip-port-matrix.md), 각 기준 문서

## 역할과 위치

| 항목 | Hub1 | Hub2 |
|---|---|---|
| 장비 | Cisco c7200 (콘솔로만 접속, 관리망 없음) | 같음 |
| 호스트 이름 | `HUB1` | `HUB2` |
| 설정 파일 | `configs/dc1/Hub1.ios` | `configs/dc1/Hub2.ios` |
| AS | 65010 | 65010 |
| loopback0 주소 | 10.0.0.21 | 10.0.0.22 |
| OSPF | 사용하지 않음 (OSPF 없음) | 사용하지 않음 (OSPF 없음) |
| BGP router-id | 10.0.1.21 | 10.0.1.22 |
| 연결하는 leaf | leaf3 | leaf4 |
| 터널 상대 | BGW1 | BGW2 |

## 연결 (포트, IP)

| 장비 | 포트 | IP | 상대 | 용도 |
|---|---|---|---|---|
| Hub1 | `gigabitethernet0/0` | 10.0.30.1/31 | PE1 `Gi4/0` (.0) | WAN 언더레이 (PE1의 VRF WAN-UL 쪽). 터널의 출발 주소 |
| Hub1 | `gigabitethernet1/0` | 10.0.31.1/31 | leaf3 `ethernet6` (.0) | leaf 연동 (leaf 쪽은 VRF TENANT-A) |
| Hub1 | `tunnel0` | 10.0.40.0/31 | BGW1 `tunnel0` (.1) | GRE over IPsec. source 10.0.30.1, destination 10.0.30.5 |
| Hub2 | `gigabitethernet0/0` | 10.0.30.3/31 | PE1 `Gi5/0` (.2) | WAN 언더레이 |
| Hub2 | `gigabitethernet1/0` | 10.0.31.3/31 | leaf4 `ethernet6` (.2) | leaf 연동 |
| Hub2 | `tunnel1` | 10.0.40.2/31 | BGW2 `tunnel1` (.3) | GRE over IPsec. source 10.0.30.3, destination 10.0.30.7 |

## 정적 경로 (IP 매핑)

Hub는 PE1 방향 기본(default) 경로를 쓰지 않고 BGW 터널 주소 하나로 가는 경로만 둠

| 장비 | 목적지 | 마스크 | next-hop | 나가는 인터페이스 | 용도 |
|---|---|---|---|---|---|
| Hub1 | 10.0.30.5 (BGW1 `Gi0/0`) | 255.255.255.255 | 10.0.30.0 (PE1 `Gi4/0`) | `gigabitethernet 0/0` | Tunnel0의 destination |
| Hub2 | 10.0.30.7 (BGW2 `Gi0/0`) | 255.255.255.255 | 10.0.30.2 (PE1 `Gi5/0`) | `gigabitethernet 0/0` | Tunnel1의 destination |

- next-hop은 항상 **PE1의 Hub 쪽 인터페이스 주소**임. Hub 자신의 주소(Hub1 10.0.30.1, Hub2 10.0.30.3)를 next-hop으로 쓰면 안 됨
- Hub1은 BGW1(10.0.30.5), Hub2는 BGW2(10.0.30.7)만 가짐. 서로 바꿔 쓰면 터널이 올라오지 않음
- default 경로를 쓰지 않는 이유: 터널 목적지 외에는 PE1 방향 경로가 필요 없고, default를 두면 오버레이(TENANT-A, Branch) 경로와 섞일 수 있음

## 설정 순서

Hub는 PE1, leaf3·4, BGW의 설정이 어느 정도 되어 있어야 상대 쪽을 확인할 수 있음. 아래 순서대로 진행

| 순서 | 할 일 | 값 | 참조 문서 | 확인 명령 |
|---|---|---|---|---|
| 1 | 기본 설정 | `hostname HUB1`, 권한 모드, domain-lookup 끄기, 콘솔 세션 | [Hub 기본 설정 샘플](../samples/dc1/03-base-hub.md) | 콘솔 로그인 |
| 2 | 인터페이스 IP | 위 연결 표의 `gigabitethernet0/0`, `1/0`, `loopback0` | [IP와 포트 매칭표](../00-overview/07-ip-port-matrix.md) | `show ip interface brief` (PE1, leaf3 쪽으로 ping) |
| 3 | 언더레이 도달성 | 정적 경로: Hub1 `ip route 10.0.30.5 255.255.255.255 10.0.30.0`, Hub2 `ip route 10.0.30.7 255.255.255.255 10.0.30.2`. PE1은 직결 링크를 VPNv4에 실어 PE3로 전달 | [기준](../baseline/core/07-pe-ce-ebgp.md), [샘플](../samples/core/07-pe-ce-ebgp.md) | `ping 10.0.30.5 source gigabitethernet0/0` (Hub2는 `10.0.30.7`) |
| 4 | leaf와 eBGP | Hub AS 65010, leaf3·4 AS 65100, 이웃 `10.0.31.0`(Hub1), `10.0.31.2`(Hub2) | [기준](../baseline/dc1/06-dci-hub-ebgp.md) | `show ip bgp summary` |
| 5 | 사전 공유 키 입력 | Hub1은 PSK-T0, Hub2는 PSK-T1 (실습 랩 전용 값은 키 관리 문서), 양쪽 같은 값 | [IPsec 키 관리](../baseline/br/08-ipsec-keys.md) | 양쪽 같은 값 |
| 6 | IPsec과 GRE 터널 | IKEv1 AES-256/SHA-1/group 14, transport 모드, MTU 1400, MSS 1360 | [기준](../baseline/br/09-ipsec-gre.md), [샘플](../samples/br/09-ipsec-gre.md) | `show crypto isakmp sa`, `show crypto ipsec sa`, `show interface tunnel0` |
| 7 | 터널 위 eBGP | Hub AS 65010, BGW AS 65020, 이웃 `10.0.40.1`(Hub1), `10.0.40.3`(Hub2) | 위와 같음 | `show ip bgp summary` |
| 8 | 협상 조건 통일 | BGP `timers 3 9`, BGP router-id는 OSPF(loopback0)와 다른 값 | [협상 조건 통일](../00-overview/03-protocol-matrix.md) | `show ip bgp neighbors` |
| 9 | 저장 | `write memory`, 컨피그를 `configs/dc1/`에 보관 (키는 자리표시자로) | | |

## 확인 (완료 기준)

| 확인 | 기대 결과 |
|---|---|
| leaf와 eBGP | leaf3(Hub1), leaf4(Hub2)와의 세션이 **Established**이고 TENANT-A 경로(192.168.10.0/24 등)를 받음 |
| IKE와 IPsec | `show crypto isakmp sa`가 `QM_IDLE`, `show crypto ipsec sa`에 encaps, decaps 카운터가 올라감 |
| 터널 | `tunnel0`(Hub1), `tunnel1`(Hub2)이 up/up |
| 터널 위 eBGP | BGW와의 세션이 **Established**이고 Branch 경로(192.168.50.0/24, 192.168.60.0/24)를 받음 |
| 통신 | Host A -> Host F `ping`이 되고 `traceroute`가 Hub를 지남 |

## 결정된 항목

1. **언더레이 도달성 (확정)**: PE1 - Hub는 **정적**, PE3 - BGW는 **eBGP**(BGW AS 65020). Hub는 BGW 터널 주소로 가는 정적 경로만 추가하고 PE1은 직결 링크를 VRF WAN-UL에서 `redistribute connected`로 PE3에 전달. 이유와 경로 흐름은 [기준 문서](../baseline/core/07-pe-ce-ebgp.md)

## 결정이 필요한 항목 (미정)

2. **라우팅 테이블 분리**: Hub는 VRF가 없어서 터널의 출발 주소(언더레이)와 TENANT-A 경로(오버레이)가 같은 테이블에 섞임. 터널 목적지가 터널을 통해 학습되는 재귀 경로(recursive routing)를 피하려면 언더레이를 별도 VRF로 두는 방법이 있음
3. **터널 위 광고 범위**: Hub가 leaf에서 받은 경로를 어디까지 BGW에 전달할지(전체 또는 TENANT-A만)와 BGW가 Branch LAN(192.168.50.0/24, 192.168.60.0/24)을 어떻게 광고할지(OSPF 재분배 또는 network 문)를 정함

- 2번 항목은 언더레이를 정적 경로로 정한 덕분에 터널 목적지(10.0.30.x)가 터널 밖에서만 학습되므로, 터널 위 eBGP에서 10.0.30.0/24를 광고하지 않으면 재귀 경로는 생기지 않음. 별도 VRF가 꼭 필요하지는 않음
- 2, 3번이 정해지면 기준 문서(`baseline/dc1/06`, `baseline/br/06`)에 값으로 반영