# Branch 개요

기준 문서: [00-overview](../../00-overview/README.md)

이 문서는 Branch와 IPsec 터널 관련 내용만 발췌한 것. 값이 다르면 00-overview 우선

## 1. 개요

| 항목 | 내용 |
|---|---|
| 역할 | Branch LAN + 스위치단, IPsec 터널로 DC1에 연결 |
| 장비 | Cisco c7200 2대 (BGW1, BGW2), IOSv 3대 (DSW1, DSW2 = IOSvL3, ASW1 = IOSvL2), 호스트 2대 (F, G) |
| 터널 | GRE over IPsec(IKEv1) 2개: Tunnel0(Hub1-BGW1), Tunnel1(Hub2-BGW2) |
| 라우팅 | Branch 내부 OSPF, Hub와는 터널 위 eBGP (Hub AS 65010 ↔ BGW AS 65020) |
| 스위치단 | VLAN 50, 60, MSTP, EtherChannel, VRRP |
| QoS | BGW에서 shaping과 큐잉 집행 |

Hub1, Hub2는 DC1 WAN 출구 장비라서 [dc1](../dc1/01-overview.md)에 있고, 이 문서는 터널 관계만 다룸.

## 2. 포트 매핑

| 노드   | 포트           | 계층                   | 상대 노드  | 상대 포트                        |
| ---- | ------------ | -------------------- | ------ | ---------------------------- |
| BGW1 | Gi0/0        | W (WAN-UL)           | PE3    | Gi2/0                        |
| BGW1 | Gi1/0        | S                    | DSW1   | Gi0/0                        |
| BGW1 | Tunnel0      | T                    | Hub1   | Tunnel0 (GRE over IPsec, 논리) |
| BGW2 | Gi0/0        | W (WAN-UL)           | PE3    | Gi3/0                        |
| BGW2 | Gi1/0        | S                    | DSW2   | Gi0/0                        |
| BGW2 | Tunnel1      | T                    | Hub2   | Tunnel1 (GRE over IPsec, 논리) |
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
| PE3 - BGW1            | 10.0.30.4/31 | PE3 .4  | BGW1 .5 | VRF WAN-UL                            |
| PE3 - BGW2            | 10.0.30.6/31 | PE3 .6  | BGW2 .7 | VRF WAN-UL                            |
| BGW1 - DSW1           | 10.50.0.0/31 | BGW1 .0 | DSW1 .1 | OSPF area 0                           |
| BGW2 - DSW2           | 10.50.0.2/31 | BGW2 .2 | DSW2 .3 | OSPF area 0                           |
| Tunnel0 (Hub1 - BGW1) | 10.0.40.0/31 | Hub1 .0 | BGW1 .1 | 터널 source/dest: 10.0.30.1 ↔ 10.0.30.5 |
| Tunnel1 (Hub2 - BGW2) | 10.0.40.2/31 | Hub2 .2 | BGW2 .3 | 터널 source/dest: 10.0.30.3 ↔ 10.0.30.7 |

## 7. 확인이 필요한 항목

- c7200 이미지의 IPsec: `show crypto ?`에 `isakmp`, `ipsec`이 있고 `ikev2`는 없음이 확인됨(IKEv1 사용).
- IOSvL3의 스위치 기능(SVI, EtherChannel, VRRP): `show vlan`, `show etherchannel`, `show vrrp`
- IOSvL2의 EtherChannel과 MSTP: `show etherchannel summary`, `show spanning-tree mst`
