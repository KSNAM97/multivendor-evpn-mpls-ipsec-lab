# EVPN-VXLAN

장비별 포트와 IP 전체: [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)

iBGP EVPN(spine이 Route Reflector)으로 MAC/IP 경로를 교환하는 오버레이

기준 문서: [00-overview](../../00-overview/README.md)

> **EVPN 설정 전 필수: 저장 후 재부팅**
> `service routing protocols model multi-agent`는 설정만으로는 적용되지 않음. **`write memory` 후 `reload`(재부팅)** 해야 적용되고, 적용 전에는 `address-family evpn`이 `% Routing protocols model multi-agent must be configured for EVPN address-family`로 거부됨. EVPN(BGP)을 넣기 **전에** 모든 spine, leaf에서 먼저 적용. 재부팅 뒤 `address-family evpn`이 에러 없이 받아들여지면 적용된 것. 이 랩은 RAM이 빠듯하니 한 대씩(또는 spine -> leaf1·2 -> leaf3·4 순서로) 재부팅

## iBGP 설계값

| 항목 | 값 |
|---|---|
| AS | **65100** (DC1 전체, spine1·2와 leaf1~4가 모두 같은 AS) |
| 종류 | iBGP, spine1·2가 **Route Reflector**(RR), leaf1~4가 RR client |
| `bgp cluster-id` | 10.1.0.100 (spine1, spine2가 같은 값) |
| 이웃 주소 | 양쪽 `loopback0`, `update-source loopback0` (OSPF가 루프백 도달성을 먼저 만들어야 함) |
| **keepalive(hello), hold 타이머** | **3초, 9초** (기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀 |
| 주소 패밀리 | `evpn`만 활성 (`no bgp default ipv4-unicast`). 언더레이 주소(loopback 등)는 OSPF가 전달 |
| `send-community extended` | 모든 이웃 (route-target 전달에 필요) |
| `maximum-paths` | 4 ecmp 4 |
| TCP 포트 | 179. 관리 ACL(`MGMT-ACL`)의 규칙 40, 50이 `10.1.0.0/24`끼리의 BGP를 허용 |

- iBGP는 next-hop을 바꾸지 않으므로 spine에 `next-hop-unchanged`가 필요 없고, 루프백 간 세션이지만 `ebgp-multihop`도 필요 없음
- keepalive(상대에게 살아 있음을 알리는 주기)가 3초이고, hold(이 시간 동안 keepalive가 없으면 이웃을 끊는 한도)가 9초. 링크가 끊겨도 BGP 이웃은 최대 9초 뒤에 내려가므로, 평소에는 OSPF(dead 4초)가 먼저 경로를 바꿈.
- 사이트 밖(leaf3·4와 PE1, Hub)과는 별도 단계(DCI와 Hub 연동)에서 eBGP를 맺음. 이때 DC1은 AS 65100으로 보임

## 장비별 iBGP 이웃

| 장비 | BGP router-id | 이웃 (loopback0) | peer group | 역할 |
|---|---|---|---|---|
| spine1 | 10.1.2.1 | leaf1 10.1.0.11, leaf2 10.1.0.12, leaf3 10.1.0.13, leaf4 10.1.0.14 | `LEAFS` | **RR** (client 4대) |
| spine2 | 10.1.2.2 | leaf1 ~ leaf4 (spine1과 같음) | `LEAFS` | **RR** (client 4대) |
| leaf1 | 10.1.2.11 | spine1 10.1.0.1, spine2 10.1.0.2 | `SPINES` | RR client |
| leaf2 | 10.1.2.12 | spine1, spine2 | `SPINES` | RR client |
| leaf3 | 10.1.2.13 | spine1, spine2 | `SPINES` | RR client |
| leaf4 | 10.1.2.14 | spine1, spine2 | `SPINES` | RR client |

- **OSPF router-id(loopback0 주소 10.1.0.x)와 BGP router-id(10.1.2.x)는 다름.** BGP 이웃 주소는 loopback0(10.1.0.x)이고, router-id는 `show bgp neighbors`와 와이어샤크 BGP OPEN의 BGP Identifier에서 보임
- 세션은 모두 8개임(leaf 4대 x spine 2대). 각 leaf가 같은 경로를 spine 두 대로부터 받으므로 경로가 이중화됨
- **BGP 이웃을 맺지 않는 것**: leaf끼리(MLAG 쌍도 포함), 호스트, MGMT-SW. MLAG 쌍도 spine(RR)을 통해 서로의 경로를 받음
- leaf는 EVPN 경로(Type 2 MAC/IP, Type 3 IMET, Type 5 IP prefix)를 spine에게 광고하고, spine은 이를 다른 leaf에게 reflect함

## VTEP

| 노드 | VTEP (Loopback1) |
|---|---|
| leaf1, leaf2 | 10.1.1.12/32 (공유) |
| leaf3, leaf4 | 10.1.1.34/32 (공유) |

## VLAN과 VNI

| VLAN | L2VNI | 서브넷 | 게이트웨이 | 호스트 |
|---|---|---|---|---|
| 10 | 10010 | 192.168.10.0/24 | .1 (anycast) | Host A .101, Host B .102 |
| 20 | 10020 | 192.168.20.0/24 | .1 (anycast) | Host C .101 |

## VRF와 RD/RT

| 항목 | 값 |
|---|---|
| VRF | TENANT-A |
| L3VNI | 50001 |
| L2 RD | `<BGP router-id>:VNI` (예: 10.1.2.11:10010). leaf마다 달라야 함 |
| L2 RT | 10010:10010, 10020:10020 |
| L3 RD / RT | `<BGP router-id>:50001` (예: 10.1.2.11:50001) / 50001:50001 |

## 게이트웨이

- anycast gateway: 모든 leaf에 같은 주소(.1)와 virtual MAC `00:1c:73:00:00:99`

## leaf 쌍별 VLAN

호스트가 없는 VLAN은 그 leaf에 넣지 않음(symmetric IRB: 다른 VLAN 사이 라우팅은 출발 leaf에서 VRF로 올리고 도착 leaf에서 내림). 단, **MLAG 쌍은 VTEP을 공유하므로 두 장비의 VLAN과 VNI 설정이 같아야 함**(`show mlag config-sanity`로 확인).

| leaf 쌍 | VTEP | 넣을 VLAN (L2VNI) | 호스트 |
|---|---|---|---|
| leaf1, leaf2 | 10.1.1.12 | VLAN 10 (10010) | Host A |
| leaf3, leaf4 | 10.1.1.34 | VLAN 10 (10010), VLAN 20 (10020) | Host B (leaf3, VLAN 10), Host C (leaf4, VLAN 20) |

- 모든 leaf에 VRF `TENANT-A`와 L3VNI 50001이 있음