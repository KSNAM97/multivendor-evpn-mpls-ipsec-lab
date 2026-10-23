# 01. 포트 매핑 (벤더별 / 계층별)

토폴로지: [GNS3 최종 토폴로지](images/gns3-topology.png) (설계 수정안: [topology-revised.png](topology-revised.png), 초기안: [topology.png](topology.png))

![GNS3 최종 토폴로지](images/gns3-topology.png)

## 표기 규칙

- 인터페이스 이름은 GNS3 템플릿 기준. 템플릿이 다르면 이름만 바꿔 읽음
- c7200 슬롯 구성 가정: `slot0 = C7200-IO-GE-E (Gi0/0)`, `slot1~5 = PA-GE (Gi1/0 ~ Gi5/0)`. PE1은 6포트를 씀. (GNS3에서는 `g0/0`처럼 소문자로 표시됨.)
- vEOS: `Management1`(관리) + `Ethernet1~`(데이터). GNS3 어댑터 0번이 Management1. GNS3 화면의 포트 이름은 템플릿의 Name format을 `Et{port1}`로 바꾸면 `Et1`로 표시됨
- ArubaOS-CX: 어댑터 0번이 관리, 이후 `1/1/1~`
- IOSv: 포트 이름이 4개 단위로 번호가 매겨짐(`Gi0/0 ~ Gi0/3`, `Gi1/0 ~ Gi1/3`, ...). DSW는 `Gi0/0 ~ Gi0/3`, `Gi1/0`(5포트), ASW1은 `Gi0/0 ~ Gi0/3`, `Gi1/0`, `Gi1/1`(6포트)를 씀
- 계층 표기: **U** Underlay, **O** Overlay/DCI, **A** Access(호스트), **W** WAN, **T** IPsec 터널, **S** 스위치단(Branch, DC2), **M** 관리
- 모든 QEMU 노드는 vCPU 1개로 시작하고, 불안정한 이미지만 2개로 올림
- 벤더는 **Cisco, Arista, Aruba 3개**. Juniper(vQFX)는 이 환경에서 PFE 등록이 되지 않아 토폴로지에서 제외됨(문서 03의 멀티호밍 대응표에는 비교용으로만 남아 있음).
- 라우터(c7200) 7대는 PE 3대(삼각형), Hub 2대, BGW 2대. 이중화와 부하 분산은 라우터 이중화와 스위치단(MLAG, VSX, EtherChannel)에서 처리

---

## 1. Arista vEOS 4.29.2F (DC1 패브릭, 6대)

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

GNS3 어댑터 수(관리 포함): spine 5, leaf1/leaf2 6, leaf3/leaf4 8

## 2. Cisco

### 2-1. c7200 라우터 (7대)

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
| Hub1 | Gi1/0 | O | leaf3 (Arista) | Et6 |
| Hub1 | Tunnel0 | T | BGW1 | Tunnel0 (GRE over IPsec, 논리) |
| Hub2 | Gi1/0 | O | leaf4 (Arista) | Et6 |
| Hub2 | Tunnel1 | T | BGW2 | Tunnel1 (GRE over IPsec, 논리) |
| BGW1 | Gi1/0 | S | DSW1 | Gi0/0 |
| BGW2 | Gi1/0 | S | DSW2 | Gi0/0 |

PE1, PE2, PE3는 서로 삼각형으로 연결되어 별도의 P 라우터 없이 코어 경로가 이중화됨. 관리 포트가 없는 c7200은 GNS3 콘솔(telnet)로 접속하고 관리망에는 연결하지 않음

### 2-2. IOSv 스위치 (Branch 스위치단, 3대)

| 노드 | 종류 | 포트 | 계층 | 상대 노드 | 상대 포트 |
|---|---|---|---|---|---|
| DSW1 | IOSvL3 | Gi0/0 | S (라우티드 업링크) | BGW1 | Gi1/0 |
| DSW1 | IOSvL3 | Gi0/1-2 | S (EtherChannel Po1) | DSW2 | Gi0/1-2 |
| DSW1 | IOSvL3 | Gi0/3, Gi1/0 | S (EtherChannel Po2) | ASW1 | Gi0/0-1 |
| DSW2 | IOSvL3 | Gi0/0 | S (라우티드 업링크) | BGW2 | Gi1/0 |
| DSW2 | IOSvL3 | Gi0/3, Gi1/0 | S (EtherChannel Po3) | ASW1 | Gi0/2-3 |
| ASW1 | IOSvL2 | Gi1/0 | A | Host F | eth0 |
| ASW1 | IOSvL2 | Gi1/1 | A | Host G | eth0 |

ASW1은 DSW1과 DSW2에 각각 2링크 EtherChannel로 연결됨. IOSv에는 MLAG(vPC, StackWise Virtual)가 없어서, 두 번들 중 하나는 MSTP 인스턴스별로 blocking되고 이것이 VLAN 단위 부하 분산이 됨

## 3. Aruba ArubaOS-CX 10.07 (DC2, 3대: VSX 쌍 + access)

| 노드  | 포트      | 계층                | 상대 노드  | 상대 포트   |
| --- | ------- | ----------------- | ------ | ------- |
| CX1 | 1/1/1   | O (DCI)           | PE2    | Gi2/0   |
| CX1 | 1/1/2-3 | U (VSX ISL)       | CX2    | 1/1/2-3 |
| CX1 | 1/1/4   | U (VSX keepalive) | CX2    | 1/1/4   |
| CX1 | 1/1/5-6 | S (VSX LAG)       | CX3    | 1/1/1-2 |
| CX2 | 1/1/1   | O (DCI)           | PE2    | Gi3/0   |
| CX2 | 1/1/5-6 | S (VSX LAG)       | CX3    | 1/1/3-4 |
| CX1 | 1/1/7   | A                 | Host D | eth1    |
| CX3 | 1/1/5   | A (미사용)          | Host D | eth0    |

CX1/CX2는 VSX 쌍(분배 계층과 border 겸용)이고, CX3은 access 스위치. CX3의 4개 링크(CX1 2개, CX2 2개)는 VSX LAG 하나로 묶임

Host D는 어댑터를 2개로 두고 `eth1`을 CX1 `1/1/7`(VLAN 110 access)에 연결해 사용. CX3 `1/1/5`(`eth0`)는 AOS-CX Virtual 10.07 이미지에서 `lag10`을 통과하는 VLAN 110 데이터 프레임이 전달되지 않아 쓰지 않음 ([DC2 active gateway 검증](../verification/dc2/05-active-gateway.md))

## 4. 호스트 (Ubuntu Docker Guest, 6대)

| 호스트 | 포트 | 연결 | VLAN | 비고 |
|---|---|---|---|---|
| Host A | eth0 / eth1 | leaf1 Et5 / leaf2 Et5 | 10 | LACP(bond0), MLAG |
| Host B | eth0 | leaf3 Et7 | 10 | |
| Host C | eth0 | leaf4 Et7 | 20 | |
| Host D | eth1 | CX1 1/1/7 | 110 | 사용 (eth0는 내림) |
| Host D | eth0 | CX3 1/1/5 | 110 | 미사용 (lag10 데이터 경로 한계) |
| Host F | eth0 | ASW1 Gi1/0 | 50 | |
| Host G | eth0 | ASW1 Gi1/1 | 60 | |

호스트는 GNS3의 Ubuntu Docker Guest 템플릿을 씀. iperf3 3.16이 기본 포함되어 있고 `ip link add bond0 type bond`가 동작함이 확인됨(Alpine 이미지는 iperf3와 bond 도구가 없어 제외). 호스트는 iperf3의 DSCP 옵션으로 트래픽을 마킹. Host A는 MLAG 쌍에 이중 연결하므로 어댑터를 2개로 설정

## 5. 관리망 (M)

MGMT-SW는 Arista vEOS 1대이고, 설정 없이 기본 L2 스위치(VLAN 1)로 씀. 장비의 관리 포트를 한곳에 모으고, 마지막 Et13을 Cloud1(PC 연결)에 연결. 어댑터는 20개(Management1 + Et1~Et19)이고 Et14~Et19는 비어 있음. 그림에는 데이터 평면만 표시됨. c7200(PE, Hub, BGW)은 관리 포트가 없어 콘솔로만 접속

| MGMT-SW 포트 | 연결 | 관리 IP |
|---|---|---|
| Et1 | spine1 Management1 | 192.168.100.11 |
| Et2 | spine2 Management1 | 192.168.100.12 |
| Et3 | leaf1 Management1 | 192.168.100.21 |
| Et4 | leaf2 Management1 | 192.168.100.22 |
| Et5 | leaf3 Management1 | 192.168.100.23 |
| Et6 | leaf4 Management1 | 192.168.100.24 |
| Et7 | CX1 mgmt | 192.168.100.41 |
| Et8 | CX2 mgmt | 192.168.100.42 |
| Et9 | CX3 mgmt | 192.168.100.43 |
| Et10 | DSW1 Gi3/3 | 192.168.100.44 |
| Et11 | DSW2 Gi3/3 | 192.168.100.45 |
| Et12 | ASW1 Gi3/3 | 192.168.100.46 |
| Et13 | Cloud1 eth0 (PC 연결) | PC 쪽 192.168.100.1 |

DSW1, DSW2의 Gi3/3은 관리 전용 VRF(MGMT)에 넣어 데이터 라우팅에 섞이지 않게 함. ASW1(IOSvL2)은 물리 포트에 IP를 줄 수 없어서 Gi3/3을 access VLAN 100에 두고 `Vlan100` SVI(192.168.100.46)로 관리

---
## 6. 링크 요약 (데이터 링크 47개 + 관리 13개)

| 구간 | 링크 수 |
|---|---|
| DC1 spine-leaf | 8 |
| DC1 MLAG peer-link | 4 (leaf1-2 쌍, leaf3-4 쌍 각 2) |
| 호스트 연결 | 7 (A 2, B, C, D, F, G) |
| 코어(PE 삼각형) | 3 |
| DCI (PE-DC) | 4 (leaf3, leaf4, CX1, CX2) |
| Hub 구간 | 4 (PE1-Hub1, PE1-Hub2, leaf3-Hub1, leaf4-Hub2) |
| Branch WAN과 라우티드 업링크 | 4 (PE3-BGW1, PE3-BGW2, BGW1-DSW1, BGW2-DSW2) |
| Branch 스위치 | 6 (DSW 간 2, DSW1-ASW1 2, DSW2-ASW1 2) |
| VSX ISL와 keepalive | 3 |
| DC2 VSX LAG (CX3 연결) | 4 |
| 관리망 | 13 (MGMT-SW, 장비 12 + Cloud 1) |

## 7. 노드 수

| 구분 | 수 |
|---|---|
| Arista vEOS | 7 (spine, leaf 6 + MGMT-SW 1) |
| Cloud | 1 |
| Aruba CX | 3 |
| Cisco IOSv | 3 |
| Cisco c7200 | 7 |
| 네트워크 장비 합계 | 20 |
| 호스트 | 6 |
| 전체 (Cloud 포함) | 27 |

QEMU 노드: 12개(Arista 6, Aruba 3, IOSv 3)

메모리 계획: [04-resource-plan.md](04-resource-plan.md)
