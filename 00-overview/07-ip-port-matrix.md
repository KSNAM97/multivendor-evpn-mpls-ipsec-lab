# 07. 장비별 IP와 포트 매칭표

장비마다 **어느 포트에 어떤 IP를 쓰는지** 한곳에 모은 표. 값은 [포트 매핑](01-port-mapping.md), [IP 설계](02-ip-addressing.md), [VLAN과 IP 총괄](06-vlan-ip-plan.md)과 같고, 이 표를 보면 장비 하나를 설정할 때 필요한 주소가 모두 나옴

## 읽는 법

- 포트 이름은 GNS3 기준. Arista는 `Et1`, Cisco는 `Gi0/0`, Aruba는 `1/1/1`
- `상대`는 반대편 장비와 포트이고, 링크 주소는 /31
- **의도적으로 여러 장비가 같은 주소를 쓰는 경우**는 `공유`로 표시하며, 맨 아래 "같은 주소를 쓰는 곳"에서 별도로 정리

## 루프백의 역할

| 루프백 | 쓰는 곳 | 용도 | 주소 대역 |
|---|---|---|---|
| **Loopback0** | 모든 라우팅 장비 (Arista, Cisco, Aruba CX1·2) | OSPF router-id, BGP 세션의 출발지 주소, 장비 식별. **장비마다 고유**. BGP router-id는 별도 값(아래 표) | DC1 `10.1.0.0/24`, 코어와 엣지 `10.0.0.0/24`, DC2 `10.2.0.0/24` |
| **Loopback1** | Arista leaf만 | **VXLAN VTEP**의 출발지 주소. **MLAG 쌍이 같은 주소를 공유**(anycast VTEP) | DC1 `10.1.1.0/24` |

spine, Cisco 장비, CX에는 Loopback1이 없음(VXLAN이 없음).

## 1. DC1 Arista

### spine1 (관리 192.168.100.11/24)

| 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|
| Management1 | 관리 | 192.168.100.11/24 | MGMT-SW Et1 | |
| Loopback0 | router-id, BGP | 10.1.0.1/32 | - | |
| Et1 | spine-leaf | 10.1.10.0/31 | leaf1 Et1 (.1) | OSPF |
| Et2 | spine-leaf | 10.1.10.2/31 | leaf2 Et1 (.3) | OSPF |
| Et3 | spine-leaf | 10.1.10.4/31 | leaf3 Et1 (.5) | OSPF |
| Et4 | spine-leaf | 10.1.10.6/31 | leaf4 Et1 (.7) | OSPF |

### spine2 (관리 192.168.100.12/24)

| 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|
| Management1 | 관리 | 192.168.100.12/24 | MGMT-SW Et2 | |
| Loopback0 | router-id, BGP | 10.1.0.2/32 | - | |
| Et1 | spine-leaf | 10.1.10.8/31 | leaf1 Et2 (.9) | OSPF |
| Et2 | spine-leaf | 10.1.10.10/31 | leaf2 Et2 (.11) | OSPF |
| Et3 | spine-leaf | 10.1.10.12/31 | leaf3 Et2 (.13) | OSPF |
| Et4 | spine-leaf | 10.1.10.14/31 | leaf4 Et2 (.15) | OSPF |

### leaf1 (MLAG 쌍: leaf2, AS 65100)

| 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|
| Management1 | 관리 | 192.168.100.21/24 | MGMT-SW Et3 | |
| Loopback0 | router-id, BGP | 10.1.0.11/32 | - | |
| **Loopback1** | **VTEP** | **10.1.1.12/32** | - | **공유** (leaf2와 같은 주소) |
| Et1 | spine-leaf | 10.1.10.1/31 | spine1 Et1 (.0) | OSPF |
| Et2 | spine-leaf | 10.1.10.9/31 | spine2 Et1 (.8) | OSPF |
| Et3-4 (Po1) | MLAG peer-link | (L2) | leaf2 Et3-4 | trunk group MLAGPEER |
| Vlan4094 | MLAG 제어 | 10.1.254.0/31 | leaf2 Vlan4094 (.1) | domain MLAG1 |
| Et5 (Po10) | Host A (mlag 10) | (L2, VLAN 10) | Host A eth0 | |
| Vlan10 | anycast gateway | 192.168.10.1/24 | - | VRF TENANT-A, **공유** (leaf1~4) |

### leaf2 (MLAG 쌍: leaf1, AS 65100)

| 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|
| Management1 | 관리 | 192.168.100.22/24 | MGMT-SW Et4 | |
| Loopback0 | router-id, BGP | 10.1.0.12/32 | - | |
| **Loopback1** | **VTEP** | **10.1.1.12/32** | - | **공유** (leaf1과 같은 주소) |
| Et1 | spine-leaf | 10.1.10.3/31 | spine1 Et2 (.2) | OSPF |
| Et2 | spine-leaf | 10.1.10.11/31 | spine2 Et2 (.10) | OSPF |
| Et3-4 (Po1) | MLAG peer-link | (L2) | leaf1 Et3-4 | |
| Vlan4094 | MLAG 제어 | 10.1.254.1/31 | leaf1 Vlan4094 (.0) | |
| Et5 (Po10) | Host A (mlag 10) | (L2, VLAN 10) | Host A eth1 | |
| Vlan10 | anycast gateway | 192.168.10.1/24 | - | VRF TENANT-A, **공유** |

### leaf3 (MLAG 쌍: leaf4, AS 65100, border)

| 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|
| Management1 | 관리 | 192.168.100.23/24 | MGMT-SW Et5 | |
| Loopback0 | router-id, BGP | 10.1.0.13/32 | - | |
| **Loopback1** | **VTEP** | **10.1.1.34/32** | - | **공유** (leaf4와 같은 주소) |
| Et1 | spine-leaf | 10.1.10.5/31 | spine1 Et3 (.4) | OSPF |
| Et2 | spine-leaf | 10.1.10.13/31 | spine2 Et3 (.12) | OSPF |
| Et3-4 (Po1) | MLAG peer-link | (L2) | leaf4 Et3-4 | |
| Vlan4094 | MLAG 제어 | 10.1.254.2/31 | leaf4 Vlan4094 (.3) | domain **MLAG2** |
| Et5 | DCI | 10.0.20.1/31 | PE1 Gi2/0 (.0) | VRF TENANT-A |
| Et6 | Hub1 연동 | 10.0.31.0/31 | Hub1 Gi1/0 (.1) | VRF TENANT-A |
| Et7 | Host B | (L2, VLAN 10) | Host B eth0 | access 포트 |
| Vlan10 | anycast gateway | 192.168.10.1/24 | - | **공유** |
| Vlan20 | anycast gateway | 192.168.20.1/24 | - | **공유** (leaf3, leaf4) |

### leaf4 (MLAG 쌍: leaf3, AS 65100, border)

| 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|
| Management1 | 관리 | 192.168.100.24/24 | MGMT-SW Et6 | |
| Loopback0 | router-id, BGP | 10.1.0.14/32 | - | |
| **Loopback1** | **VTEP** | **10.1.1.34/32** | - | **공유** (leaf3과 같은 주소) |
| Et1 | spine-leaf | 10.1.10.7/31 | spine1 Et4 (.6) | OSPF |
| Et2 | spine-leaf | 10.1.10.15/31 | spine2 Et4 (.14) | OSPF |
| Et3-4 (Po1) | MLAG peer-link | (L2) | leaf3 Et3-4 | |
| Vlan4094 | MLAG 제어 | 10.1.254.3/31 | leaf3 Vlan4094 (.2) | |
| Et5 | DCI | 10.0.20.3/31 | PE1 Gi3/0 (.2) | VRF TENANT-A |
| Et6 | Hub2 연동 | 10.0.31.2/31 | Hub2 Gi1/0 (.3) | VRF TENANT-A |
| Et7 | Host C | (L2, VLAN 20) | Host C eth0 | access 포트 |
| Vlan10 | anycast gateway | 192.168.10.1/24 | - | **공유** |
| Vlan20 | anycast gateway | 192.168.20.1/24 | - | **공유** |

## 2. MPLS 코어 Cisco c7200

### PE1 (Loopback0 10.0.0.11/32)

| 인터페이스 | 역할 | IP | 상대 | VRF |
|---|---|---|---|---|
| Gi0/0 | 코어 | 10.0.10.0/31 | PE2 Gi0/0 (.1) | global |
| Gi1/0 | 코어 | 10.0.10.2/31 | PE3 Gi0/0 (.3) | global |
| Gi2/0 | DCI | 10.0.20.0/31 | leaf3 Et5 (.1) | TENANT-A |
| Gi3/0 | DCI | 10.0.20.2/31 | leaf4 Et5 (.3) | TENANT-A |
| Gi4/0 | WAN 언더레이 | 10.0.30.0/31 | Hub1 Gi0/0 (.1) | WAN-UL |
| Gi5/0 | WAN 언더레이 | 10.0.30.2/31 | Hub2 Gi0/0 (.3) | WAN-UL |

### PE2 (Loopback0 10.0.0.12/32)

| 인터페이스 | 역할 | IP | 상대 | VRF |
|---|---|---|---|---|
| Gi0/0 | 코어 | 10.0.10.1/31 | PE1 Gi0/0 (.0) | global |
| Gi1/0 | 코어 | 10.0.10.4/31 | PE3 Gi1/0 (.5) | global |
| Gi2/0 | DCI | 10.0.20.4/31 | CX1 1/1/1 (.5) | TENANT-A |
| Gi3/0 | DCI | 10.0.20.6/31 | CX2 1/1/1 (.7) | TENANT-A |

### PE3 (Loopback0 10.0.0.13/32)

| 인터페이스 | 역할 | IP | 상대 | VRF |
|---|---|---|---|---|
| Gi0/0 | 코어 | 10.0.10.3/31 | PE1 Gi1/0 (.2) | global |
| Gi1/0 | 코어 | 10.0.10.5/31 | PE2 Gi1/0 (.4) | global |
| Gi2/0 | WAN 언더레이 | 10.0.30.4/31 | BGW1 Gi0/0 (.5) | WAN-UL |
| Gi3/0 | WAN 언더레이 | 10.0.30.6/31 | BGW2 Gi0/0 (.7) | WAN-UL |

## 3. WAN 출구와 Branch

### Hub1, Hub2 (DC1 쪽 IPsec 장비, AS 65010)

| 장비   | 인터페이스     | 역할             | IP                                              | 상대                |
| ---- | --------- | -------------- | ----------------------------------------------- | ----------------- |
| Hub1 | Loopback0 | router-id      | 10.0.0.21/32                                    | -                 |
| Hub1 | Gi0/0     | WAN 언더레이       | 10.0.30.1/31                                    | PE1 Gi4/0 (.0)    |
| Hub1 | Gi1/0     | leaf 연동        | 10.0.31.1/31                                    | leaf3 Et6 (.0)    |
| Hub1 | Tunnel0   | GRE over IPsec | 10.0.40.0/31 (source 10.0.30.1, dest 10.0.30.5) | BGW1 Tunnel0 (.1) |
| Hub2 | Loopback0 | router-id      | 10.0.0.22/32                                    | -                 |
| Hub2 | Gi0/0     | WAN 언더레이       | 10.0.30.3/31                                    | PE1 Gi5/0 (.2)    |
| Hub2 | Gi1/0     | leaf 연동        | 10.0.31.3/31                                    | leaf4 Et6 (.2)    |
| Hub2 | Tunnel1   | GRE over IPsec | 10.0.40.2/31 (source 10.0.30.3, dest 10.0.30.7) | BGW2 Tunnel1 (.3) |

### BGW1, BGW2 (Branch WAN 출구, AS 65020)

| 장비 | 인터페이스 | 역할 | IP | 상대 |
|---|---|---|---|---|
| BGW1 | Loopback0 | router-id | 10.0.0.31/32 | - |
| BGW1 | Gi0/0 | WAN 언더레이 | 10.0.30.5/31 | PE3 Gi2/0 (.4) |
| BGW1 | Gi1/0 | Branch 연동 | 10.50.0.0/31 | DSW1 Gi0/0 (.1) |
| BGW1 | Tunnel0 | GRE over IPsec | 10.0.40.1/31 (source 10.0.30.5, dest 10.0.30.1) | Hub1 Tunnel0 (.0) |
| BGW2 | Loopback0 | router-id | 10.0.0.32/32 | - |
| BGW2 | Gi0/0 | WAN 언더레이 | 10.0.30.7/31 | PE3 Gi3/0 (.6) |
| BGW2 | Gi1/0 | Branch 연동 | 10.50.0.2/31 | DSW2 Gi0/0 (.3) |
| BGW2 | Tunnel1 | GRE over IPsec | 10.0.40.3/31 (source 10.0.30.7, dest 10.0.30.3) | Hub2 Tunnel1 (.2) |

### DSW1, DSW2, ASW1 (Branch 스위치)

| 장비 | 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|---|
| DSW1 | Loopback0 | router-id | 10.0.0.41/32 | - | |
| DSW1 | Gi3/3 | 관리 (VRF MGMT) | 192.168.100.44/24 | MGMT-SW Et10 | |
| DSW1 | Gi0/0 | BGW 연동 | 10.50.0.1/31 | BGW1 Gi1/0 (.0) | OSPF |
| DSW1 | Po1 (Gi0/1-2) | DSW 간 | (L2 trunk) | DSW2 Po1 | |
| DSW1 | Po2 (Gi0/3, Gi1/0) | ASW1 연결 | (L2 trunk) | ASW1 Po2 | |
| DSW1 | Vlan50 / Vlan60 | SVI | 192.168.50.2/24 / 192.168.60.2/24 | - | VRRP VIP .1 (VLAN 50 master) |
| DSW2 | Loopback0 | router-id | 10.0.0.42/32 | - | |
| DSW2 | Gi3/3 | 관리 (VRF MGMT) | 192.168.100.45/24 | MGMT-SW Et11 | |
| DSW2 | Gi0/0 | BGW 연동 | 10.50.0.3/31 | BGW2 Gi1/0 (.2) | OSPF |
| DSW2 | Po1 (Gi0/1-2) | DSW 간 | (L2 trunk) | DSW1 Po1 | |
| DSW2 | Po3 (Gi0/3, Gi1/0) | ASW1 연결 | (L2 trunk) | ASW1 Po3 | |
| DSW2 | Vlan50 / Vlan60 | SVI | 192.168.50.3/24 / 192.168.60.3/24 | - | VRRP VIP .1 (VLAN 60 master) |
| ASW1 | Gi3/3 | 관리 포트 (L2 access VLAN 100) | (L2) | MGMT-SW Et12 | IOSvL2는 물리 포트에 IP를 줄 수 없음 |
| ASW1 | Vlan100 | 관리 SVI | 192.168.100.46/24 | - | VRF 없음, VLAN 100은 트렁크 allowed(50,60)에 넣지 않음 |
| ASW1 | Po2 (Gi0/0-1) | DSW1 연결 | (L2 trunk) | DSW1 Po2 | |
| ASW1 | Po3 (Gi0/2-3) | DSW2 연결 | (L2 trunk) | DSW2 Po3 | |
| ASW1 | Gi1/0, Gi1/1 | Host F, Host G | (L2, VLAN 50 / 60) | Host F, G | access 포트 |

## 4. DC2 Aruba

| 장비 | 인터페이스 | 역할 | IP | 상대 | 비고 |
|---|---|---|---|---|---|
| CX1 | mgmt | 관리 | 192.168.100.41/24 | MGMT-SW Et7 | |
| CX1 | Loopback0 | router-id | 10.2.0.1/32 | - | |
| CX1 | 1/1/1 | DCI | 10.0.20.5/31 | PE2 Gi2/0 (.4) | VRF TENANT-A |
| CX1 | lag 256 (1/1/2-3) | VSX ISL | (L2) | CX2 lag 256 | |
| CX1 | 1/1/4 | VSX keepalive | 10.2.254.0/31 | CX2 1/1/4 (.1) | VRF KEEPALIVE |
| CX1 | lag 10 (1/1/5-6) | CX3 연결 | (L2 trunk, VLAN 110) | CX3 lag 10 | multi-chassis |
| CX1 | vlan 110 | SVI | 192.168.110.2/24 | - | active gateway .1 (**공유**) |
| CX1 | 1/1/7 | Host D 연결 | (L2, VLAN 110 access) | Host D eth1 | CX3 경유가 이미지 한계로 안 되어 직접 연결 |
| CX2 | mgmt | 관리 | 192.168.100.42/24 | MGMT-SW Et8 | |
| CX2 | Loopback0 | router-id | 10.2.0.2/32 | - | |
| CX2 | 1/1/1 | DCI | 10.0.20.7/31 | PE2 Gi3/0 (.6) | VRF TENANT-A |
| CX2 | lag 256 (1/1/2-3) | VSX ISL | (L2) | CX1 lag 256 | |
| CX2 | 1/1/4 | VSX keepalive | 10.2.254.1/31 | CX1 1/1/4 (.0) | VRF KEEPALIVE |
| CX2 | lag 10 (1/1/5-6) | CX3 연결 | (L2 trunk, VLAN 110) | CX3 lag 10 | multi-chassis |
| CX2 | vlan 110 | SVI | 192.168.110.3/24 | - | active gateway .1 (**공유**) |
| CX3 | mgmt | 관리 | 192.168.100.43/24 | MGMT-SW Et9 | |
| CX3 | lag 10 (1/1/1-4) | VSX 쌍 연결 | (L2 trunk, VLAN 110) | CX1, CX2 lag 10 | |
| CX3 | 1/1/5 | Host D | (L2, VLAN 110) | Host D eth0 | access 포트. 사용하지 않음(이미지 한계로 `lag10` 데이터 경로 불가) |

## 5. 호스트

| 호스트 | IP | 게이트웨이 | 연결 포트 | VLAN |
|---|---|---|---|---|
| Host A | 192.168.10.101/24 (bond0) | 192.168.10.1 | leaf1 Et5, leaf2 Et5 (eth0, eth1) | 10 |
| Host B | 192.168.10.102/24 | 192.168.10.1 | leaf3 Et7 | 10 |
| Host C | 192.168.20.101/24 | 192.168.20.1 | leaf4 Et7 | 20 |
| Host D | 192.168.110.101/24 (eth1) | 192.168.110.1 | CX1 1/1/7 (eth1) | 110 |
| Host F | 192.168.50.101/24 | 192.168.50.1 (VRRP) | ASW1 Gi1/0 | 50 |
| Host G | 192.168.60.101/24 | 192.168.60.1 (VRRP) | ASW1 Gi1/1 | 60 |

## router-id (OSPF와 BGP는 다른 값)

| 장비 | OSPF router-id (= Loopback0) | BGP router-id |
|---|---|---|
| spine1, spine2 | 10.1.0.1, 10.1.0.2 | 10.1.2.1, 10.1.2.2 |
| leaf1 ~ leaf4 | 10.1.0.11 ~ 10.1.0.14 | 10.1.2.11 ~ 10.1.2.14 |
| PE1 ~ PE3 | 10.0.0.11 ~ 10.0.0.13 | 10.0.1.11 ~ 10.0.1.13 |
| Hub1, Hub2 | - | 10.0.1.21, 10.0.1.22 |
| BGW1, BGW2 | 10.0.0.31, 10.0.0.32 | 10.0.1.31, 10.0.1.32 |
| DSW1, DSW2 | 10.0.0.41, 10.0.0.42 | - |
| CX1, CX2 | - | 10.2.2.1, 10.2.2.2 |

BGP router-id는 인터페이스에 설정하는 주소가 아니라 ID 값

상세 설명: [IP 설계](02-ip-addressing.md)의 3-1-1
## 같은 주소를 쓰는 곳 (의도된 중복)

| 주소 | 쓰는 장비 | 이유 |
|---|---|---|
| 10.1.1.12/32 (Loopback1) | leaf1, leaf2 | MLAG 쌍이 하나의 VTEP으로 보이게 하는 **anycast VTEP** |
| 10.1.1.34/32 (Loopback1) | leaf3, leaf4 | 같은 이유 (border leaf 쌍) |
| 192.168.10.1 (Vlan10) | leaf1~leaf4 | VLAN 10의 anycast gateway (모든 leaf가 같은 주소와 가상 MAC) |
| 192.168.20.1 (Vlan20) | leaf3, leaf4 | VLAN 20의 anycast gateway |
| 192.168.110.1 | CX1, CX2 | VSX active gateway |
| 192.168.50.1, 192.168.60.1 | DSW1, DSW2 | VRRP 가상 주소 |

이 표 밖에서 같은 주소가 보이면 설정 실수임(예: Vlan4094는 쌍마다 /31이 달라야 하고 leaf1, leaf2가 같은 `.0`을 쓰면 안 됨).
