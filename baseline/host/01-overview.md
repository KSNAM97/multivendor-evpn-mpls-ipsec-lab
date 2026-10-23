# 호스트 개요

장비별 포트와 IP 전체: [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)

샘플: [samples/host](../../samples/host/README.md)

## 호스트 목록

| 호스트 | 지역 | VLAN | IP | 게이트웨이 | 연결 장비와 포트 | 어댑터 |
|---|---|---|---|---|---|---|
| Host A | DC1 | 10 | 192.168.10.101/24 (`bond0`) | 192.168.10.1 (anycast) | leaf1 `ethernet5`, leaf2 `ethernet5` (MLAG) | **2** (eth0, eth1) |
| Host B | DC1 | 10 | 192.168.10.102/24 | 192.168.10.1 (anycast) | leaf3 `ethernet7` | 1 |
| Host C | DC1 | 20 | 192.168.20.101/24 | 192.168.20.1 (anycast) | leaf4 `ethernet7` | 1 |
| Host D | DC2 | 110 | 192.168.110.101/24 (`eth1`) | 192.168.110.1 (VSX active gateway) | CX1 `1/1/7` (eth1). CX3 `1/1/5`(eth0)는 미사용 | **2** (eth0, eth1) |
| Host F | Branch | 50 | 192.168.50.101/24 | 192.168.50.1 (VRRP VIP) | ASW1 `Gi1/0` | 1 |
| Host G | Branch | 60 | 192.168.60.101/24 | 192.168.60.1 (VRRP VIP) | ASW1 `Gi1/1` | 1 |

- 호스트 이름은 Host A, B, C, D, F, G임(E는 쓰지 않음).
- 컨피그 파일은 [configs/host](../../configs/host/)에 호스트마다 하나씩(`HOST-A.sh` 등) 둠

## 이미지와 기본 조건

| 항목 | 값 |
|---|---|
| 이미지 | GNS3 Ubuntu Docker Guest |
| 기본 도구 | `iperf3` 3.16, `ip`, `ping`, `traceroute`. `tcpdump`는 설치가 필요할 수 있음(인터넷 필요) |
| bond | `ip link add bond0 type bond`가 동작함을 확인 (Alpine 이미지는 iperf3와 bond 도구가 없어 제외) |
| 관리 접속 | 관리망이 아니라 GNS3 콘솔로 접속 |
| 설정 유지 | `ip` 명령은 임시 설정이라 노드를 다시 켜면 사라지므로, 컨피그 파일(`HOST-*.sh`)에 두고 다시 실행 |

## VLAN과 게이트웨이

| VLAN | 서브넷 | 게이트웨이 방식 | 게이트웨이 장비 |
|---|---|---|---|
| 10 | 192.168.10.0/24 | anycast gateway | leaf1~leaf4 |
| 20 | 192.168.20.0/24 | anycast gateway | leaf3, leaf4 |
| 110 | 192.168.110.0/24 | VSX active gateway | CX1, CX2 |
| 50 | 192.168.50.0/24 | VRRP (DSW1 master) | DSW1, DSW2 |
| 60 | 192.168.60.0/24 | VRRP (DSW2 master) | DSW1, DSW2 |

## 스위치 쪽 호스트 포트 설정

| 장비 | 포트 | STP 설정 | 비고 |
|---|---|---|---|
| leaf1, leaf2 | `port-channel10` (Host A, MLAG) | `spanning-tree portfast`, `spanning-tree bpduguard enable` | 묶인 포트채널에 붙임 (`ethernet5`가 아님) |
| leaf3 | `ethernet7` (Host B) | 같음 | access VLAN 10 |
| leaf4 | `ethernet7` (Host C) | 같음 | access VLAN 20 |
| ASW1 | `Gi1/0`, `Gi1/1` (Host F, G) | `spanning-tree portfast` | IOSv, access 포트. 필요하면 `spanning-tree bpduguard enable` |
| CX1 | `1/1/7` (Host D `eth1`) | `spanning-tree port-type admin-edge` (STP를 켠 경우) | Aruba의 말단 포트 설정. 현재 STP가 꺼져 있어 효과 없음 |
| CX3 | `1/1/5` (Host D `eth0`, 미사용) | 같음 | CX3 경유 연결은 이미지 한계로 쓰지 않음 |

- 호스트 한 대만 연결되는 포트라서 STP 수렴을 기다리지 않게 하고, `bpduguard`로 스위치가 잘못 연결되는 경우를 막음
- **스위치끼리 연결되는 포트에는 쓰지 않음**: MLAG 피어링크, spine-leaf 링크, leaf3·4의 PE1·Hub 링크, DSW-ASW 트렁크.
- `portfast`를 켜면 "portfast should only be enabled on ports connected to a single host" 경고가 나오는데, 정상 출력
- 확인: `show spanning-tree interface <포트> detail`에서 edge 포트로 표시되고 `forwarding`이어야 함. 포트채널은 호스트가 연결되어 멤버가 올라와야 STP 정보가 나옴