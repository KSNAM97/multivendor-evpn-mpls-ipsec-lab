# MP-BGP VPNv4

**목적**: PE 사이에서 VRF 경로를 iBGP VPNv4로 교환

**핵심**

- PE 3대 full mesh, 이웃 주소는 loopback0(10.0.0.x), `update-source loopback 0`
- BGP router-id(PE1 10.0.1.11, PE2 10.0.1.12, PE3 10.0.1.13)는 OSPF router-id(10.0.0.x)와 다른 값
- `send-community extended`가 없으면 Route Target이 전달되지 않음
- BGP 타이머는 DC1과 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일(기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀
- `no bgp default ipv4-unicast`: 일반 IPv4 주소 패밀리를 자동으로 켜지 않음

**확인 명령**: `show bgp vpnv4 unicast all summary`, `show bgp vpnv4 unicast all`

파일: `mp-bgp-vpnv4.ios`

```text
! Cisco IOS (c7200) - MP-BGP VPNv4 샘플 (PE1 기준)
! 확인: show bgp vpnv4 unicast all summary / show bgp vpnv4 unicast all
! PE2는 router-id 10.0.1.12, 이웃 10.0.0.11과 10.0.0.13
! PE3는 router-id 10.0.1.13, 이웃 10.0.0.11과 10.0.0.12
!
router bgp 65000
    bgp router-id 10.0.1.11
    bgp log-neighbor-changes
    no bgp default ipv4-unicast
    neighbor 10.0.0.12 remote-as 65000
    neighbor 10.0.0.12 update-source loopback 0
    neighbor 10.0.0.12 timers 3 9
    neighbor 10.0.0.13 remote-as 65000
    neighbor 10.0.0.13 update-source loopback 0
    neighbor 10.0.0.13 timers 3 9
    !
    address-family vpnv4
        neighbor 10.0.0.12 activate
        neighbor 10.0.0.12 send-community extended
        neighbor 10.0.0.13 activate
        neighbor 10.0.0.13 send-community extended
    exit-address-family
!
```
