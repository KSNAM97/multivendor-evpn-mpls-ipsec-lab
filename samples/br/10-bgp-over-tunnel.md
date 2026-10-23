# 터널 위 eBGP

**목적**: Hub와 BGW가 GRE over IPsec 터널 위에서 eBGP로 DC1과 Branch 경로를 교환

**핵심**

- Hub AS 65010, BGW AS 65020. 이웃은 터널 주소: Hub1 ↔ BGW1은 10.0.40.0 ↔ 10.0.40.1, Hub2 ↔ BGW2는 10.0.40.2 ↔ 10.0.40.3
- BGP router-id는 Hub1 10.0.1.21, Hub2 10.0.1.22, BGW1 10.0.1.31, BGW2 10.0.1.32. OSPF router-id(loopback0 주소)와 다른 값
- BGP 타이머는 DC1과 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일(기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀
- **재귀 경로 방지**: BGW는 PE3에서 언더레이 경로(10.0.30.0/31, 10.0.30.2/31)를 BGP로 받음. 이 경로를 터널 위로 Hub에 다시 내보내면 터널 목적지를 터널 안에서 배워 터널이 내려갈 수 있으므로, `prefix-list NO-UNDERLAY`로 `10.0.30.0/24`를 터널 쪽 out에서 막음(Hub, BGW 양쪽)
- BGW는 Branch LAN(192.168.50.0/24, 192.168.60.0/24)을 `network` 문으로 광고. DSW에서 OSPF로 받은 경로가 라우팅 테이블에 있어야 광고됨 ([Branch OSPF](06-ospf-branch.md)). PE3 방향에는 광고하지 않음 ([PE3 - BGW eBGP](07-wan-ebgp.md)의 `prefix-list NONE out`)
- Hub의 leaf 쪽 eBGP(이웃 leaf3 10.0.31.0 또는 leaf4 10.0.31.2, AS 65100)는 같은 `router bgp 65010`에 있음

**확인 명령**: `show ip bgp summary`, `show ip route 192.168.50.0`, `show ip bgp neighbors 10.0.40.1 | include hold`

파일: `bgp-over-tunnel.ios`

```text
! Cisco IOS (c7200) - 터널 위 eBGP 샘플 (Hub1, Hub2, BGW1, BGW2)
! 확인: show ip bgp summary / show ip route 192.168.50.0 / show ip bgp neighbors 10.0.40.1 | include hold
! 장비마다 값만 다르다
!   Hub1 router-id 10.0.1.21, 터널 이웃 10.0.40.1 (BGW1, AS 65020). Hub2는 10.0.1.22, 10.0.40.3
!   BGW1 router-id 10.0.1.31, 터널 이웃 10.0.40.0 (Hub1, AS 65010). BGW2는 10.0.1.32, 10.0.40.2
! 터널 위로 언더레이(10.0.30.0/24)를 광고하지 않기 위한 필터 (재귀 경로 방지)
! BGW는 PE3에서 10.0.30.0/31, 10.0.30.2/31을 BGP로 받으므로 Hub로 다시 내보내지 않게 막는다
!
ip prefix-list NO-UNDERLAY seq 5 deny 10.0.30.0/24 le 32
ip prefix-list NO-UNDERLAY seq 10 permit 0.0.0.0/0 le 32
!
! [Hub1] leaf와의 eBGP(이웃 10.0.31.0, AS 65100)는 같은 router bgp 65010에 이미 있다
router bgp 65010
    bgp router-id 10.0.1.21
    neighbor 10.0.40.1 remote-as 65020
    neighbor 10.0.40.1 timers 3 9
    !
    address-family ipv4
        neighbor 10.0.40.1 activate
        neighbor 10.0.40.1 prefix-list NO-UNDERLAY out
    exit-address-family
!
! [BGW1] PE3 이웃(10.0.30.4)은 PE3 - BGW eBGP 샘플에 있다. 같은 router bgp 65020에 터널 이웃과 Branch LAN 광고를 더한다
router bgp 65020
    neighbor 10.0.40.0 remote-as 65010
    neighbor 10.0.40.0 timers 3 9
    !
    address-family ipv4
        neighbor 10.0.40.0 activate
        neighbor 10.0.40.0 prefix-list NO-UNDERLAY out
        network 192.168.50.0 mask 255.255.255.0
        network 192.168.60.0 mask 255.255.255.0
    exit-address-family
!
```
