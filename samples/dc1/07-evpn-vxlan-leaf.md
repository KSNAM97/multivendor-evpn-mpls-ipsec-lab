# iBGP EVPN-VXLAN (leaf)

**목적**: leaf에서 L2VNI, L3VNI(VRF)와 anycast gateway를 구성

**핵심**

- **EVPN 설정 전에 `service routing protocols model multi-agent`를 설정하고 `write memory` 후 `reload`(재부팅)해야 함.** 재부팅 전에는 `address-family evpn`이 거부됨(`% Routing protocols model multi-agent must be configured for EVPN address-family`).
- MLAG 쌍은 같은 VTEP 주소(Loopback1)를 공유. 이때 L3VNI(VRF 간 라우팅)의 안쪽 출발 MAC을 쌍이 같게 하려고 `vxlan virtual-router encapsulation mac-address mlag-system-id`를 `interface vxlan1` 안에 한 줄로 씀
- 게이트웨이는 `ip address virtual`과 공통 virtual MAC으로 모든 leaf에 같은 주소를 둠
- spine(Route Reflector)과는 루프백 간 iBGP로 EVPN 경로를 교환. 모든 DC1 장비가 AS 65100
- 빠른 수렴을 위해 BGP 타이머를 keepalive 3초, hold 9초로 줄임(기본 60초, 180초). 양쪽 중 작은 hold 값으로 협상됨

**확인 명령**: `show bgp evpn summary`, `show vxlan vtep`, `show vxlan vni`, `show bgp evpn route-type mac-ip`

파일: `evpn-vxlan-leaf.eos`

```text
! Arista EOS - iBGP EVPN-VXLAN leaf 샘플 (leaf1 기준, 값은 예시)
! 확인: show bgp evpn summary / show vxlan vtep / show vxlan vni
!       show bgp evpn route-type mac-ip / show vxlan address-table
!
service routing protocols model multi-agent
!
vrf instance TENANT-A
!
ip routing
ip routing vrf TENANT-A
!
ip virtual-router mac-address 00:1c:73:00:00:99
!
vlan 10
   name APP
vlan 20
   name DB
!
! 호스트가 없는 VLAN은 그 leaf에 넣지 않는다 (leaf1, leaf2는 VLAN 10만, leaf3, leaf4는 VLAN 10과 20).
! 단, MLAG 쌍은 두 장비의 VLAN, VNI 설정이 같아야 한다. 아래는 VLAN 10, 20을 모두 가진 형태의 예시
! MLAG 쌍(leaf1, leaf2)은 같은 VTEP 주소(loopback1)를 공유
interface loopback1
   description VTEP
   ip address 10.1.1.12/32
   ip ospf area 0.0.0.0
!
interface vxlan1
   vxlan source-interface loopback1
   vxlan udp-port 4789
   vxlan vlan 10 vni 10010
   vxlan vlan 20 vni 10020
   vxlan vrf TENANT-A vni 50001
   vxlan virtual-router encapsulation mac-address mlag-system-id
!
interface vlan10
   vrf TENANT-A
   ip address virtual 192.168.10.1/24
!
interface vlan20
   vrf TENANT-A
   ip address virtual 192.168.20.1/24
!
! BGP router-id 는 OSPF router-id(loopback0 주소 10.1.0.x)와 다른 값(10.1.2.x)을 쓴다
! leaf2~4는 router-id와 rd의 10.1.2.11을 10.1.2.12 ~ 10.1.2.14로 바꾼다 (RD는 leaf마다 달라야 하고 RT는 모든 leaf가 같다)
! spine(Route Reflector)과 세션만 맺고 leaf끼리는 이웃을 맺지 않는다
router bgp 65100
   router-id 10.1.2.11
   no bgp default ipv4-unicast
   maximum-paths 4 ecmp 4
   neighbor SPINES peer group
   neighbor SPINES remote-as 65100
   neighbor SPINES timers 3 9
   neighbor SPINES update-source loopback0
   neighbor SPINES send-community extended
   neighbor 10.1.0.1 peer group SPINES
   neighbor 10.1.0.2 peer group SPINES
   !
   vlan 10
      rd 10.1.2.11:10010
      route-target both 10010:10010
      redistribute learned
   !
   vlan 20
      rd 10.1.2.11:10020
      route-target both 10020:10020
      redistribute learned
   !
   address-family evpn
      neighbor SPINES activate
   !
   vrf TENANT-A
      rd 10.1.2.11:50001
      route-target import evpn 50001:50001
      route-target export evpn 50001:50001
      redistribute connected
!
```

## 장비별 값 (leaf1 샘플에서 바꿀 것)

| 장비 | BGP router-id | RD 접두 | OSPF router-id (loopback0) | VTEP (`loopback1`) | VLAN, VNI |
|---|---|---|---|---|---|
| leaf1 | 10.1.2.11 | 10.1.2.11 | 10.1.0.11 | 10.1.1.12 | 10 -> 10010 |
| leaf2 | 10.1.2.12 | 10.1.2.12 | 10.1.0.12 | 10.1.1.12 (leaf1과 공유) | 10 -> 10010 |
| leaf3 | 10.1.2.13 | 10.1.2.13 | 10.1.0.13 | 10.1.1.34 | 10 -> 10010, 20 -> 10020 |
| leaf4 | 10.1.2.14 | 10.1.2.14 | 10.1.0.14 | 10.1.1.34 (leaf3과 공유) | 10 -> 10010, 20 -> 10020 |

- **BGP router-id는 OSPF router-id와 다른 값**. RD는 leaf마다 달라야 하고(`<BGP router-id>:<VNI>`), RT(`10010:10010`, `10020:10020`, `50001:50001`)는 모든 leaf가 같음
- leaf1·2는 VLAN 20이 없으므로 `vxlan vlan 20`, `interface vlan20`, `vlan 20`의 BGP 블록을 뺌.