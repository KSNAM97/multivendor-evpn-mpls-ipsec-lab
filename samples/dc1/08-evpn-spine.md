# iBGP EVPN Route Reflector (spine)

**목적**: spine이 Route Reflector로 leaf 4대의 EVPN 경로를 모아서 다른 leaf에게 전달

**핵심**

- **EVPN 설정 전에 `service routing protocols model multi-agent`를 설정하고 `write memory` 후 `reload`(재부팅)해야 함.** 재부팅 전에는 `address-family evpn`이 거부됨(`% Routing protocols model multi-agent must be configured for EVPN address-family`).
- DC1 전체가 AS 65100 하나의 iBGP. spine1, spine2는 Route Reflector, leaf1~4는 client
- iBGP는 next-hop을 바꾸지 않으므로 `next-hop-unchanged`와 `ebgp-multihop`이 필요 없음
- 세션은 `loopback0`끼리 맺으므로 `update-source loopback0`이 필요하고, OSPF가 루프백 도달성을 먼저 만들어야 함
- `bgp cluster-id`는 두 spine이 같은 값을 씀. leaf끼리는 BGP 이웃을 맺지 않음
- 빠른 수렴을 위해 타이머는 keepalive 3초, hold 9초임(기본 60초, 180초).
- `neighbor LEAFS route-reflector-client`는 `address-family evpn` 안이 아니라 **`router bgp` 바로 아래**에 씀. 이 vEOS에서 `neighbor LEAFS ?`로 확인했고, address-family 안에서 입력하면 상위 모드로 처리됨

**확인 명령**: `show bgp evpn summary`, `show ip ospf neighbor`

파일: `evpn-spine.eos`

```text
router bgp 65100
   router-id 10.1.2.1
   bgp cluster-id 10.1.0.100
   no bgp default ipv4-unicast
   maximum-paths 4 ecmp 4
   neighbor LEAFS peer group
   neighbor LEAFS remote-as 65100
   neighbor LEAFS update-source loopback0
   neighbor LEAFS route-reflector-client
   neighbor LEAFS timers 3 9
   neighbor LEAFS send-community extended
   neighbor 10.1.0.11 peer group LEAFS
   neighbor 10.1.0.12 peer group LEAFS
   neighbor 10.1.0.13 peer group LEAFS
   neighbor 10.1.0.14 peer group LEAFS
   !
   address-family evpn
      neighbor LEAFS activate
!
```

BGP router-id는 OSPF router-id(loopback0 주소 10.1.0.x)와 **다른 값**(10.1.2.x)을 씀. spine2는 `router-id 10.1.2.2`, `loopback0 10.1.0.2/32`만 다르고 `cluster-id`는 같음. 전체 파일: `evpn-spine.eos`