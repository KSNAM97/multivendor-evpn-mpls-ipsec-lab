# Branch 개요

기준 문서: [00-overview](../../00-overview/README.md)

이 문서는 Branch 관련 내용만 발췌한 것. 값이 다르면 00-overview 우선

## 1. 개요

| 항목 | 내용 |
|---|---|
| 역할 | Branch LAN + 스위치단. BGW가 고객사 망 끝단(CE)으로 PE3의 VRF BR1에 연결 |
| 장비 | Cisco c7200 2대 (BGW1, BGW2), IOSv 3대 (DSW1, DSW2 = IOSvL3, ASW1 = IOSvL2), 호스트 2대 (F, G) |
| 라우팅 | Branch 내부 OSPF, PE3와는 eBGP (PE3 AS 65000 ↔ BGW AS 65020). DC1과 DC2 경로는 MPLS L3VPN(VRF BR1)으로 받음 |
| 스위치단 | VLAN 50, 60, RSTP(rapid-pvst), EtherChannel, VRRP |

Hub1, Hub2는 DC1 외부 연결 장비라서 [dc1](../dc1/01-overview.md)에 있음. Branch는 Hub와 직접 연결되지 않고 MPLS 코어(PE3)를 거쳐 통신함.

## 2. 포트 매핑

| 노드   | 포트           | 계층                   | 상대 노드  | 상대 포트                        |
| ---- | ------------ | -------------------- | ------ | ---------------------------- |
| BGW1 | Gi0/0 (.100) | O (PE-CE, VRF BR1)   | PE3    | Gi2/0 (.100)                 |
| BGW1 | Gi1/0        | S                    | DSW1   | Gi0/0                        |
| BGW2 | Gi0/0 (.100) | O (PE-CE, VRF BR1)   | PE3    | Gi3/0 (.100)                 |
| BGW2 | Gi1/0        | S                    | DSW2   | Gi0/0                        |
| DSW1 | Gi0/1-2      | S (EtherChannel Po1) | DSW2   | Gi0/1-2                      |
| DSW1 | Gi0/3, Gi1/0 | S (EtherChannel Po2) | ASW1   | Gi0/0-1                      |
| DSW2 | Gi0/3, Gi1/0 | S (EtherChannel Po3) | ASW1   | Gi0/2-3                      |
| ASW1 | Gi1/0        | A                    | Host F | eth0                         |
| ASW1 | Gi1/1        | A                    | Host G | eth0                         |

IOSv의 포트 이름은 4개 단위로 번호가 매겨짐(`Gi0/0 ~ Gi0/3`, `Gi1/0 ~`). DSW는 5개, ASW1은 6개 어댑터가 필요

## 3. IP 주소

| 노드 | Loopback0 | 비고 |
|---|---|---|
| BGW1 | 10.0.0.31/32 | |
| BGW2 | 10.0.0.32/32 | |
| DSW1 | 10.0.0.41/32 | |
| DSW2 | 10.0.0.42/32 | |
| ASW1 | - | L2 스위치(데이터 VLAN SVI 없음). 관리는 `Gi3/3`(access VLAN 100)의 `Vlan100` 192.168.100.46 |

| 링크                    | 서브넷          | A측      | B측      | 비고                                    |
| --------------------- | ------------ | ------- | ------- | ------------------------------------- |
| PE3 - BGW1            | 10.0.60.0/31 | PE3 .0  | BGW1 .1 | VRF BR1, .100 서브인터페이스          |
| PE3 - BGW2            | 10.0.60.2/31 | PE3 .2  | BGW2 .3 | VRF BR1, .100 서브인터페이스          |
| BGW1 - DSW1           | 10.50.0.0/31 | BGW1 .0 | DSW1 .1 | OSPF area 0                           |
| BGW2 - DSW2           | 10.50.0.2/31 | BGW2 .2 | DSW2 .3 | OSPF area 0                           |

## 7. 확인이 필요한 항목

- IOSvL3의 스위치 기능(SVI, EtherChannel, VRRP): `show vlan`, `show etherchannel`, `show vrrp`
- IOSvL2의 EtherChannel과 RSTP: `show etherchannel summary`, `show spanning-tree vlan 50`
