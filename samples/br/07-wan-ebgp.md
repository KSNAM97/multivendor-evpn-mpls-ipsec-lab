# PE3 - BGW eBGP (WAN-UL)

**목적**: BGW가 PE3와 eBGP로 WAN 언더레이 경로를 받고, Branch 안으로 default route를 내려보냄

**핵심**

- BGW1은 PE3 `10.0.30.4`, BGW2는 PE3 `10.0.30.6`과 이웃(AS 65000). BGW AS는 65020, BGP router-id는 10.0.1.31, 10.0.1.32(OSPF router-id와 다름)
- PE3 쪽 설정은 [코어 PE-CE 샘플](../core/07-pe-ce-ebgp.md)의 `[PE3]` 블록. 양쪽 모두 `timers 3 9`
- BGW는 PE3로 **광고하는 경로가 없음**. `network` 문은 Hub 쪽 터널 단계([터널 위 eBGP](10-bgp-over-tunnel.md))에서 넣고, 이때 PE3 이웃에는 `prefix-list NONE out`을 걸어 Branch LAN이 WAN-UL VRF로 새지 않게 함
- PE3에서 받는 경로는 PE1 쪽 언더레이(10.0.30.0/31, 10.0.30.2/31). Hub 터널 주소(10.0.30.1, 10.0.30.3)에 도달하는 데 씀
- OSPF에 `default-information originate always`: DC 경로는 터널 위 eBGP로 BGW까지만 오므로 DSW가 default로 BGW를 향하게 함

**확인 명령**: `show ip bgp summary`, `show ip route 10.0.30.1`, `show ip bgp neighbors 10.0.30.4 | include hold`, DSW에서 `show ip route ospf`

파일: `wan-ebgp.ios`

```text
! Cisco IOS (c7200) - PE3 - BGW eBGP (WAN-UL) 샘플 (BGW1, BGW2)
! 확인: show ip bgp summary / show ip route 10.0.30.1 / show ip bgp neighbors 10.0.30.4 | include hold
! 장비마다 값만 다르다
!   BGW1 router-id 10.0.1.31, PE3 이웃 10.0.30.4 (PE3 Gi2/0)
!   BGW2 router-id 10.0.1.32, PE3 이웃 10.0.30.6 (PE3 Gi3/0)
! BGW가 PE3로 광고하는 경로는 없다 (Branch LAN을 WAN-UL VRF로 흘리지 않는다)
!
! [BGW1] (BGW2는 router-id 10.0.1.32, 이웃 10.0.30.6)
ip prefix-list NONE seq 5 deny 0.0.0.0/0 le 32
!
router bgp 65020
    bgp router-id 10.0.1.31
    bgp log-neighbor-changes
    no bgp default ipv4-unicast
    neighbor 10.0.30.4 remote-as 65000
    neighbor 10.0.30.4 timers 3 9
    !
    address-family ipv4
        neighbor 10.0.30.4 activate
        neighbor 10.0.30.4 prefix-list NONE out
    exit-address-family
!
! [BGW1, BGW2 공통] DSW가 DC 방향 경로를 default route로 받는다
! (DC 경로는 BGP로 BGW까지만 오고 OSPF로 내려가지 않기 때문. BGW에 default가 없어도 always로 항상 광고)
router ospf 1
    default-information originate always
!
```
