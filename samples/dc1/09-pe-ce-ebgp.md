# border leaf와 PE의 VRF eBGP

**목적**: border leaf가 MPLS 코어(PE1)와 TENANT-A VRF 경로를 교환

**핵심**

- `no bgp default ipv4-unicast`를 쓰므로 VRF 안에서 `address-family ipv4`의 neighbor를 activate해야 함

- BGP 타이머는 DC1과 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일함(기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀

- leaf3은 PE1 Gi2/0(10.0.20.0)과, leaf4는 PE1 Gi3/0(10.0.20.2)과 연결. leaf3 ethernet5 10.0.20.1/31, leaf4 ethernet5 10.0.20.3/31
- 세션이 안 올라오면 MGMT-ACL을 확인. system control-plane의 ACL은 기본적으로 default VRF에만 적용되므로 VRF TENANT-A의 BGP는 보통 영향이 없지만, 막히면 permit tcp 10.0.20.0/24 any eq bgp와 permit tcp 10.0.20.0/24 eq bgp any를 추가

**확인 명령**: `show ip bgp summary vrf TENANT-A`, `show ip route vrf TENANT-A`

파일: `pe-ce-ebgp.eos`

```text
! Arista EOS - border leaf(leaf3)와 PE1의 VRF eBGP 샘플 (값은 예시)
! 확인: show ip bgp summary vrf TENANT-A / show ip route vrf TENANT-A
! leaf4는 ethernet5 ip 10.0.20.3/31, rd 10.1.2.14:50001, neighbor 10.0.20.2 (PE1 Gi3/0)
! BGP router-id가 10.1.2.x이므로 rd도 10.1.2.x:50001 형식 (leaf3은 10.1.2.13:50001)
!
interface ethernet5
   description to-PE1
   no switchport
   vrf TENANT-A
   ip address 10.0.20.1/31
!
router bgp 65100
   vrf TENANT-A
      router-id 10.1.2.13
      rd 10.1.2.13:50001
      route-target import evpn 50001:50001
      route-target export evpn 50001:50001
      neighbor 10.0.20.0 remote-as 65000
      neighbor 10.0.20.0 timers 3 9
      redistribute connected
      !
      address-family ipv4
         neighbor 10.0.20.0 activate
!
```
