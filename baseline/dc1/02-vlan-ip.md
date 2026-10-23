# DC1 VLAN과 IP

DC1(Arista)의 VLAN, VNI, IP 대역

기준 문서: [00-overview/06-vlan-ip-plan](../../00-overview/06-vlan-ip-plan.md)

## VLAN과 VNI

| VLAN | 이름        | 적용 장비                                | L2VNI | 서브넷                                              | 게이트웨이                | 호스트                                        |
| ---- | --------- | ------------------------------------ | ----- | ------------------------------------------------ | -------------------- | ------------------------------------------ |
| 10   | APP       | **leaf1, leaf2, leaf3, leaf4**       | 10010 | 192.168.10.0/24                                  | .1 (anycast gateway) | Host A .101 (leaf1·2), Host B .102 (leaf3) |
| 20   | DB        | **leaf3, leaf4** (leaf1, leaf2에는 없음) | 10020 | 192.168.20.0/24                                  | .1 (anycast gateway) | Host C .101 (leaf4)                        |
| 4094 | MLAG-PEER | leaf1~leaf4 (쌍마다 다른 /31)             | -     | 10.1.254.0/31 (leaf1·2), 10.1.254.2/31 (leaf3·4) | -                    | -                                          |

- VRF `TENANT-A`, L3VNI **50001**
- VLAN 999는 모든 트렁크의 네이티브 VLAN임(호스트, SVI 없음). 트렁크가 있는 장비마다 `vlan 999`를 만들고 트렁크에 `native vlan 999`를 지정. 10.99.0.0/16 대역은 기능 시험 전용

## 관리와 루프백

- **Loopback0**: OSPF router-id와 BGP 세션 출발지. 장비마다 고유. **BGP router-id는 별도 값**임(spine 10.1.2.1, 10.1.2.2, leaf 10.1.2.11 ~ 10.1.2.14).
- **Loopback1**: VTEP 출발지(leaf만). MLAG 쌍이 같은 주소를 공유하는 것은 의도된 설정임(leaf1·2 10.1.1.12, leaf3·4 10.1.1.34).
- 장비별 전체 주소와 포트: [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)

| 노드     | Mgmt (192.168.100.0/24) | Loopback0    | VTEP (Loopback1)         |
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
| DCI (VRF TENANT-A) | 10.0.20.0/24 | PE1-leaf3 10.0.20.0/31, PE1-leaf4 10.0.20.2/31 |
| leaf-Hub (VRF TENANT-A) | 10.0.31.0/24 | leaf3-Hub1 10.0.31.0/31, leaf4-Hub2 10.0.31.2/31 |
| WAN 언더레이 (VRF WAN-UL) | 10.0.30.0/24 | PE1-Hub1 10.0.30.0/31, PE1-Hub2 10.0.30.2/31 |

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
| leaf1, leaf2 | Et5 (Po10)            | L2 VLAN 10                               | Host A eth0, eth1                   |
| leaf3        | Et5 / Et6 / Et7       | 10.0.20.1/31 / 10.0.31.0/31 / L2 VLAN 10 | PE1 Gi2/0 / Hub1 Gi1/0 / Host B     |
| leaf4        | Et5 / Et6 / Et7       | 10.0.20.3/31 / 10.0.31.2/31 / L2 VLAN 20 | PE1 Gi3/0 / Hub2 Gi1/0 / Host C     |

한곳에 모은 전체 표는 [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)