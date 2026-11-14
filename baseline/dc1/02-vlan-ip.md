# DC1 VLAN과 IP

DC1(Arista)의 VLAN, VNI, IP 대역

기준 문서: [00-overview/06-vlan-ip-plan](../../00-overview/06-vlan-ip-plan.md)

## VLAN과 VNI

| VLAN | 이름 | 적용 장비 | L2VNI | 서브넷 | 게이트웨이 | 호스트 |
| ---- | --------- | ---- | ----- | ---- | ---- | ---- |
| 10 | FINANCE | **leaf1~leaf4** | 10010 | 192.168.10.0/24 | .1 (anycast gateway) | Host A .101 (leaf1 Et5) |
| 20 | LOGISTICS-HR | **leaf1~leaf4** | 10020 | 192.168.20.0/24 | .1 (anycast gateway) | Host B .101 (leaf2 Et5) |
| 30 | ERP-DB | **leaf1~leaf4** | 10030 | 192.168.30.0/24 | .1 (anycast gateway) | Host C .101 (leaf3 Et7) |
| 99 | MGMT | **leaf1~leaf4** | 10099 | 192.168.99.0/24 (고객사 요청 관리용 대역) | .1 (anycast gateway) | Host D .101 (leaf4 Et7) |
| 4094 | MLAG-PEER | leaf1~leaf4 (쌍마다 다른 /31) | - | 10.1.254.0/31 (leaf1·2), 10.1.254.2/31 (leaf3·4) | - | - |

- STP: `spanning-tree mode mstp`, region **DC1**(revision 1), 인스턴스 1 = VLAN 10, 20 / 인스턴스 2 = VLAN 30, 99, 인스턴스 1·2 priority 4096. 지정하지 않은 VLAN은 MST0(CIST)에 자동 매핑
- VLAN 99는 개발지사(BGW prefix-list `PARTNER-TO-BR` seq 25)에서도 도달 가능
- VRF `TENANT-A`, L3VNI **50001**
- VLAN 999는 모든 트렁크의 네이티브 VLAN임(호스트, SVI 없음). 트렁크가 있는 장비마다 `vlan 999`를 만들고 트렁크에 `native vlan 999`를 지정. 10.99.0.0/16 대역은 기능 시험 전용

## 관리와 루프백

- **Loopback0**: OSPF router-id와 BGP 세션 출발지. 장비마다 고유. **BGP router-id는 별도 값**임(spine 10.1.2.1, 10.1.2.2, leaf 10.1.2.11 ~ 10.1.2.14).
- **Loopback1**: VTEP 출발지(leaf만). MLAG 쌍이 같은 주소를 공유하는 것은 의도된 설정임(leaf1·2 10.1.1.12, leaf3·4 10.1.1.34).
- 장비별 전체 주소와 포트: [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)

| 노드     | Mgmt (10.9.0.0/24) | Loopback0    | VTEP (Loopback1)         |
| ------ | ----------------------- | ------------ | ------------------------ |
| spine1 | .11                     | 10.1.0.1/32  | -                        |
| spine2 | .12                     | 10.1.0.2/32  | -                        |
| leaf1  | .21                     | 10.1.0.11/32 | 10.1.1.12/32 (leaf2와 공유) |
| leaf2  | .22                     | 10.1.0.12/32 | 10.1.1.12/32 (leaf1과 공유) |
| leaf3  | .23                     | 10.1.0.13/32 | 10.1.1.34/32 (leaf4와 공유) |
| leaf4  | .24                     | 10.1.0.14/32 | 10.1.1.34/32 (leaf3과 공유) |
| Hub1   | (콘솔)                    | 10.0.0.21/32 | -                        |
| Hub2   | (콘솔)                    | 10.0.0.22/32 | -                        |

## 링크 주소 요약

| 용도 | 대역 | 비고 |
|---|---|---|
| spine-leaf | 10.1.10.0/24 | /31 8개 ([OSPF underlay](03-ospf-underlay.md)) |
| MLAG peer | 10.1.254.0/24 | leaf1-2 10.1.254.0/31, leaf3-4 10.1.254.2/31 ([MLAG](04-mlag.md)) |
| border leaf-Hub (VRF TENANT-A) | 10.0.31.0/24 | border-leaf1-Hub1 10.0.31.0/31, border-leaf2-Hub2 10.0.31.2/31 |
| PE1-Hub (PE1 쪽 VRF TENANT-A) | 10.0.30.0/24 | PE1-Hub1 10.0.30.0/31, PE1-Hub2 10.0.30.2/31 |

## AS

| 노드 | AS |
|---|---|
| spine1, spine2, leaf1~leaf4 | 65100 |
| Hub1, Hub2 | 65010 |

## VLAN이 있는 장비

| VLAN | 장비 |
|---|---|
| 10 | leaf1, leaf2, leaf3, leaf4 |
| 20 | leaf3, leaf4 |
| 4094 | leaf1~leaf4 (MLAG 제어) |

spine에는 VLAN이 없음(라우티드 링크만 사용).

## 장비별 포트와 IP

| 장비           | 포트                    | IP                                       | 상대                                  |
| ------------ | --------------------- | ---------------------------------------- | ----------------------------------- |
| spine1       | Et1 / Et2 / Et3 / Et4 | 10.1.10.0 / .2 / .4 / .6 (/31)           | leaf1 / leaf2 / leaf3 / leaf4 의 Et1 |
| spine2       | Et1 / Et2 / Et3 / Et4 | 10.1.10.8 / .10 / .12 / .14 (/31)        | leaf1 / leaf2 / leaf3 / leaf4 의 Et2 |
| leaf1        | Et1 / Et2             | 10.1.10.1/31 / 10.1.10.9/31              | spine1 Et1 / spine2 Et1             |
| leaf2        | Et1 / Et2             | 10.1.10.3/31 / 10.1.10.11/31             | spine1 Et2 / spine2 Et2             |
| leaf3        | Et1 / Et2             | 10.1.10.5/31 / 10.1.10.13/31             | spine1 Et3 / spine2 Et3             |
| leaf4        | Et1 / Et2             | 10.1.10.7/31 / 10.1.10.15/31             | spine1 Et4 / spine2 Et4             |
| leaf1, leaf2 | Et3-4 (Po1), Vlan4094 | 10.1.254.0/31, 10.1.254.1/31             | 서로                                  |
| leaf3, leaf4 | Et3-4 (Po1), Vlan4094 | 10.1.254.2/31, 10.1.254.3/31             | 서로                                  |
| leaf1        | Et5                   | L2 VLAN 10 (access)                      | Host A eth0                         |
| leaf2        | Et5                   | L2 VLAN 20 (access)                      | Host B eth0                         |
| leaf3        | Et7                   | L2 VLAN 30 (access)                      | Host C eth0                         |
| leaf4        | Et7                   | L2 VLAN 99 (access)                      | Host D eth0                         |
| border-leaf1 | Et1 / Et2 / Et3       | 10.0.31.0/31 / 10.1.10.17/31 / 10.1.10.21/31 | Hub1 Gi1/0 / spine1 Et5 / spine2 Et5 |
| border-leaf2 | Et1 / Et2 / Et3       | 10.0.31.2/31 / 10.1.10.19/31 / 10.1.10.23/31 | Hub2 Gi1/0 / spine1 Et6 / spine2 Et6 |

한곳에 모은 전체 표는 [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)