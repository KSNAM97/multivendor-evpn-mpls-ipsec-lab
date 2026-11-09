# border leaf와 Hub의 VRF eBGP

**목적**: border leaf(border-leaf1, border-leaf2)가 Hub와 TENANT-A VRF 경로를 교환(Hub가 PE1과 eBGP로 코어에 전달)

**핵심**

- `no bgp default ipv4-unicast`를 쓰므로 VRF 안에서 `address-family ipv4`의 neighbor를 activate해야 함
- BGP 타이머는 DC1과 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일함(기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀
- border-leaf1은 Hub1 `Gi1/0`(ethernet1, 10.0.31.0/31), border-leaf2는 Hub2 `Gi1/0`(ethernet1, 10.0.31.2/31)에 각각 연결(1대1). 두 border leaf는 MLAG 없이 VTEP이 각각이고 EVPN type-5로 외부 경로를 leaf에 광고함
- border leaf는 `vxlan vrf TENANT-A vni 50001`로 L3VNI를 쓰고 VRF의 route-target(50001:50001)을 leaf와 맞춤
- 세션이 안 올라오면 MGMT-ACL을 확인. system control-plane의 ACL은 기본적으로 default VRF에만 적용되므로 VRF TENANT-A의 BGP는 보통 영향이 없음

**확인 명령**: `show ip bgp summary vrf TENANT-A`, `show ip route vrf TENANT-A`, `show bgp evpn summary`

파일: `pe-ce-ebgp.eos`

```text
! Arista EOS - border-leaf1과 Hub1의 VRF eBGP 샘플 (값은 예시)
! 확인: show ip bgp summary vrf TENANT-A / show bgp evpn summary
! border-leaf2는 ethernet1 ip 10.0.31.2/31(neighbor 10.0.31.3), rd 10.1.2.16:50001, loopback1 10.1.1.16
! BGP router-id가 10.1.2.x이므로 rd도 10.1.2.x:50001 형식 (border-leaf1은 10.1.2.15:50001)
!
interface ethernet1
   description Hub1 to Gi1/0
   no switchport
   vrf TENANT-A
   ip address 10.0.31.0/31
   no shutdown
!
interface vxlan1
   vxlan source-interface loopback1
   vxlan udp-port 4789
   vxlan vrf TENANT-A vni 50001
!
router bgp 65100
   vrf TENANT-A
      rd 10.1.2.15:50001
      route-target import evpn 50001:50001
      route-target export evpn 50001:50001
      router-id 10.1.2.15
      neighbor 10.0.31.1 remote-as 65010
      neighbor 10.0.31.1 timers 3 9
      redistribute connected
      !
      address-family ipv4
         neighbor 10.0.31.1 activate
!
```
