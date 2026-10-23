# Branch VLAN과 IP

장비별 포트와 IP 전체: [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)

Branch의 VLAN, IP 대역, 터널 주소

기준 문서: [00-overview/06-vlan-ip-plan](../../00-overview/06-vlan-ip-plan.md)

## VLAN

| VLAN | 이름       | 서브넷             | VRRP VIP | DSW1              | DSW2              | master | 호스트         |
| ---- | -------- | --------------- | -------- | ----------------- | ----------------- | ------ | ----------- |
| 50   | BR-LAN50 | 192.168.50.0/24 | .1       | .2 (priority 110) | .3 (priority 100) | DSW1   | Host F .101 |
| 60   | BR-LAN60 | 192.168.60.0/24 | .1       | .2 (priority 100) | .3 (priority 110) | DSW2   | Host G .101 |

- ASW1은 L2 스위치라 데이터 VLAN(50, 60)에는 SVI가 없음. 호스트의 게이트웨이는 DSW의 SVI(VRRP VIP .1)
- 관리 VLAN 100(MGMT, 192.168.100.0/24)은 **ASW1에만** 있음. `Gi3/3`을 access VLAN 100에 두고 `Vlan100` SVI(192.168.100.46)로 관리하며, 트렁크 allowed(50,60)에는 넣지 않음. IOSvL2는 물리 포트에 IP를 줄 수 없어서 DSW처럼 VRF MGMT를 쓰지 못함
- VLAN 999는 모든 트렁크의 네이티브 VLAN임(호스트, SVI 없음). 트렁크가 있는 장비마다 `vlan 999`를 만들고 트렁크에 `native vlan 999`를 지정. 10.99.0.0/16 대역은 기능 시험 전용

## Loopback

| 노드   | Loopback0    |
| ---- | ------------ |
| BGW1 | 10.0.0.31/32 |
| BGW2 | 10.0.0.32/32 |
| DSW1 | 10.0.0.41/32 |
| DSW2 | 10.0.0.42/32 |

## 링크와 터널

| 용도                    | 서브넷          | A측      | B측      | 비고                                |
| --------------------- | ------------ | ------- | ------- | --------------------------------- |
| PE3 - BGW1            | 10.0.30.4/31 | PE3 .4  | BGW1 .5 | VRF WAN-UL                        |
| PE3 - BGW2            | 10.0.30.6/31 | PE3 .6  | BGW2 .7 | VRF WAN-UL                        |
| BGW1 - DSW1           | 10.50.0.0/31 | BGW1 .0 | DSW1 .1 | OSPF area 0                       |
| BGW2 - DSW2           | 10.50.0.2/31 | BGW2 .2 | DSW2 .3 | OSPF area 0                       |
| Tunnel0 (Hub1 - BGW1) | 10.0.40.0/31 | Hub1 .0 | BGW1 .1 | source/dest 10.0.30.1 ↔ 10.0.30.5 |
| Tunnel1 (Hub2 - BGW2) | 10.0.40.2/31 | Hub2 .2 | BGW2 .3 | source/dest 10.0.30.3 ↔ 10.0.30.7 |

- `10.50.0.0/24`(링크)와 `192.168.50.0/24`(VLAN 50 LAN)는 번호가 같아 보이지만 다른 대역

## AS

| 노드 | AS |
|---|---|
| Hub1, Hub2 | 65010 |
| BGW1, BGW2 | 65020 |

## VLAN이 있는 장비

| VLAN | 장비 | 역할 |
|---|---|---|
| 50 | DSW1 (SVI .2, master), DSW2 (SVI .3), ASW1 (L2만) | VRRP VIP .1. Host F는 ASW1 Gi1/0 |
| 60 | DSW1 (SVI .2), DSW2 (SVI .3, master), ASW1 (L2만) | VRRP VIP .1. Host G는 ASW1 Gi1/1 |

BGW와 Hub에는 VLAN이 없음(라우티드 링크만 사용).

## 장비별 포트와 IP

| 장비   | 포트                 | IP                           | 상대                      |
| ---- | ------------------ | ---------------------------- | ----------------------- |
| BGW1 | Gi0/0              | 10.0.30.5/31                 | PE3 Gi2/0               |
| BGW1 | Gi1/0              | 10.50.0.0/31                 | DSW1 Gi0/0              |
| BGW1 | Tunnel0            | 10.0.40.1/31                 | Hub1 Tunnel0            |
| BGW2 | Gi0/0              | 10.0.30.7/31                 | PE3 Gi3/0               |
| BGW2 | Gi1/0              | 10.50.0.2/31                 | DSW2 Gi0/0              |
| BGW2 | Tunnel1            | 10.0.40.3/31                 | Hub2 Tunnel1            |
| DSW1 | Gi0/0              | 10.50.0.1/31                 | BGW1 Gi1/0              |
| DSW1 | Po1 (Gi0/1-2)      | L2 trunk                     | DSW2 Po1 (Gi0/2, Gi0/1) |
| DSW1 | Po2 (Gi0/3, Gi1/0) | L2 trunk                     | ASW1 Po2 (Gi0/0-1)      |
| DSW1 | Gi3/3              | 192.168.100.44/24 (VRF MGMT) | MGMT-SW Et10            |
| DSW2 | Gi0/0              | 10.50.0.3/31                 | BGW2 Gi1/0              |
| DSW2 | Po3 (Gi0/3, Gi1/0) | L2 trunk                     | ASW1 Po3 (Gi0/2-3)      |
| DSW2 | Gi3/3              | 192.168.100.45/24 (VRF MGMT) | MGMT-SW Et11            |
| ASW1 | Gi1/0, Gi1/1       | L2 access (VLAN 50, 60)      | Host F, Host G          |
| ASW1 | Gi3/3, Vlan100     | 192.168.100.46/24 (VLAN 100) | MGMT-SW Et12            |

Loopback0만 있고 Loopback1은 없음

Hub의 포트: [DC1 DCI](../dc1/06-dci-hub-ebgp.md)