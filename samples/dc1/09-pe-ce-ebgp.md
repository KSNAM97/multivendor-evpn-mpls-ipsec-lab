# border leaf와 Hub의 VRF eBGP

**목적**: border leaf(leaf3, leaf4)가 Hub 2대와 TENANT-A VRF 경로를 교환(Hub가 PE1과 eBGP로 코어에 전달)

**핵심**

- `no bgp default ipv4-unicast`를 쓰므로 VRF 안에서 `address-family ipv4`의 neighbor를 activate해야 함
- BGP 타이머는 DC1과 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일함(기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀
- leaf3·4는 VTEP을 공유하므로 두 leaf 모두 Hub 2대에 연결(교차 연결). leaf3은 Hub1 `Gi1/0`(ethernet6, 10.0.31.0/31)과 Hub2 `Gi2/0`(ethernet8, 10.0.32.0/31), leaf4는 Hub2 `Gi1/0`(ethernet6, 10.0.31.2/31)과 Hub1 `Gi2/0`(ethernet8, 10.0.32.2/31)
- 세션이 안 올라오면 MGMT-ACL을 확인. system control-plane의 ACL은 기본적으로 default VRF에만 적용되므로 VRF TENANT-A의 BGP는 보통 영향이 없지만, 막히면 permit tcp 10.0.30.0/24 any eq bgp와 permit tcp 10.0.30.0/24 eq bgp any를 추가

**확인 명령**: `show ip bgp summary vrf TENANT-A`, `show ip route vrf TENANT-A`

파일: `pe-ce-ebgp.eos`

```text
! Arista EOS - border leaf(leaf3)와 Hub의 VRF eBGP 샘플 (값은 예시)
! 확인: show ip bgp summary vrf TENANT-A / show ip route vrf TENANT-A
! leaf3은 Hub1(ethernet6)과 Hub2(ethernet8) 둘 다에 연결한다 (교차 연결)
! leaf4는 Hub2 ethernet6 ip 10.0.31.2/31(neighbor 10.0.31.3), Hub1 ethernet8 ip 10.0.32.2/31(neighbor 10.0.32.3), rd 10.1.2.14:50001
! BGP router-id가 10.1.2.x이므로 rd도 10.1.2.x:50001 형식 (leaf3은 10.1.2.13:50001)
!
interface ethernet6
   description Hub1 to Gi1/0
   no switchport
   vrf TENANT-A
   ip address 10.0.31.0/31
   no shutdown
!
interface ethernet8
   description Hub2 to Gi2/0
   no switchport
   vrf TENANT-A
   ip address 10.0.32.0/31
   no shutdown
!
router bgp 65100
   vrf TENANT-A
      router-id 10.1.2.13
      rd 10.1.2.13:50001
      route-target import evpn 50001:50001
      route-target export evpn 50001:50001
      neighbor 10.0.31.1 remote-as 65010
      neighbor 10.0.31.1 timers 3 9
      neighbor 10.0.32.1 remote-as 65010
      neighbor 10.0.32.1 timers 3 9
      redistribute connected
      !
      address-family ipv4
         neighbor 10.0.31.1 activate
         neighbor 10.0.32.1 activate
!
```
