# PE3 - BGW eBGP (VRF BR1)

**목적**: BGW가 고객사 망 끝단(CE)으로 PE3와 eBGP를 맺어 자기 대역을 광고하고 DC 경로를 받으며, Branch 안으로 default route를 내려보냄

**핵심**

- PE3와 BGW 사이는 `.100` 서브인터페이스(dot1q 100). BGW1은 PE3 `10.0.60.0`, BGW2는 PE3 `10.0.60.2`와 이웃(AS 65000). BGW AS는 65020, BGP router-id는 10.0.1.31, 10.0.1.32(OSPF router-id와 다름)
- PE3 쪽 설정은 [코어 PE-CE 샘플](../core/07-pe-ce-ebgp.md)의 `[PE3]` 블록(VRF BR1). 양쪽 모두 `timers 30 90`
- BGW는 PE3로 **자기 대역(192.168.50.0/24, 192.168.60.0/24)만** 광고함. `prefix-list BR-TO-PARTNER out`으로 막아 DC1과 DC2가 BR1을 거쳐 서로 통신하는 경로가 생기지 않게 함
- PE3에서 받는 경로는 DC1(192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24, 192.168.99.0/24)과 DC2(192.168.110.0/24). `prefix-list PARTNER-TO-BR in`으로 이 다섯 개만 허용
- OSPF에 `default-information originate always`: DC 경로는 BGP로 BGW까지만 오므로 DSW가 default로 BGW를 향하게 함

**확인 명령**: `show ip bgp summary`, `show ip bgp neighbors 10.0.60.0 | include hold`, `show ip bgp neighbors 10.0.60.0 advertised-routes`, DSW에서 `show ip route ospf`

파일: `pe3-bgw-ebgp.ios`

```text
! Cisco IOS (c7200) - PE3 - BGW eBGP (VRF BR1) 샘플 (BGW1, BGW2)
! 확인: show ip bgp summary / show ip bgp neighbors 10.0.60.0 | include hold / show ip bgp neighbors 10.0.60.0 advertised-routes
! 장비마다 값만 다르다
!   BGW1 router-id 10.0.1.31, Gi0/0.100 10.0.60.1/31, PE3 이웃 10.0.60.0 (PE3 Gi2/0.100)
!   BGW2 router-id 10.0.1.32, Gi0/0.100 10.0.60.3/31, PE3 이웃 10.0.60.2 (PE3 Gi3/0.100)
! BGW는 자기 대역(192.168.50.0/24, 60.0/24)만 PE3로 광고한다 (DC1과 DC2가 BR1을 거쳐 서로 통신하지 않게 함)
!
! [BGW1] (BGW2는 router-id 10.0.1.32, 주소 10.0.60.3, 이웃 10.0.60.2)
interface gigabitethernet 0/0
    no ip address
    no shutdown
!
interface gigabitethernet 0/0.100
    encapsulation dot1q 100
    ip address 10.0.60.1 255.255.255.254
!
ip prefix-list BR-TO-PARTNER seq 5 permit 192.168.50.0/24
ip prefix-list BR-TO-PARTNER seq 10 permit 192.168.60.0/24
ip prefix-list PARTNER-TO-BR seq 5 permit 192.168.110.0/24
ip prefix-list PARTNER-TO-BR seq 10 permit 192.168.10.0/24
ip prefix-list PARTNER-TO-BR seq 15 permit 192.168.20.0/24
ip prefix-list PARTNER-TO-BR seq 20 permit 192.168.30.0/24
ip prefix-list PARTNER-TO-BR seq 25 permit 192.168.99.0/24
!
router bgp 65020
    bgp router-id 10.0.1.31
    bgp log-neighbor-changes
    no bgp default ipv4-unicast
    neighbor 10.0.60.0 remote-as 65000
    neighbor 10.0.60.0 timers 30 90
    !
    address-family ipv4
        neighbor 10.0.60.0 activate
        neighbor 10.0.60.0 prefix-list BR-TO-PARTNER out
        neighbor 10.0.60.0 prefix-list PARTNER-TO-BR in
        network 192.168.50.0 mask 255.255.255.0
        network 192.168.60.0 mask 255.255.255.0
    exit-address-family
!
! [BGW1, BGW2 공통] DSW가 DC 방향 경로를 default route로 받는다
! (DC 경로는 BGP로 BGW까지만 오고 OSPF로 내려가지 않기 때문. BGW에 default가 없어도 always로 항상 광고)
router ospf 1
    default-information originate always
!
```
