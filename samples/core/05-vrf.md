# VRF

**목적**: 고객별 라우팅 테이블을 분리하고 RD와 RT를 지정

**핵심**

- RD는 같은 prefix를 PE마다 구분하는 값, RT는 어느 VRF가 경로를 가져가고 내보낼지 정하는 값
- TENANT-A(DC1)는 PE1, PARTNER(DC2)는 PE2, BR1(Branch)은 PE3에 정의. RD는 각각 65000:1, 65000:2, 65000:3
- DC1과 DC2는 서로의 RT를 import하지 않음. BR1만 65000:1과 65000:2를 import하고, TENANT-A와 PARTNER는 65000:3(BR1)을 import
- RD와 RT는 [MP-BGP VPNv4](06-mp-bgp-vpnv4.md) 단계에서 경로 교환에 쓰임

**확인 명령**: `show ip vrf`, `show ip vrf detail`

파일: `vrf.ios`

```text
! Cisco IOS (c7200) - VRF 샘플
! 확인: show ip vrf / show ip vrf detail / show ip route vrf TENANT-A
! 인터페이스 소속(ip vrf forwarding)은 02 인터페이스 IP 단계에서 이미 입력했다
! IOS 버전에 따라 VRF 선언이 다르다: 12.4는 "ip vrf", 15.x는 "vrf definition"
! PE마다 자기 VRF 하나만 정의한다 (PE1 TENANT-A, PE2 PARTNER, PE3 BR1)
!
! [PE1] DC1
ip vrf TENANT-A
    rd 65000:1
    route-target export 65000:1
    route-target import 65000:1
    route-target import 65000:3
!
! [PE2] DC2
ip vrf PARTNER
    rd 65000:2
    route-target export 65000:2
    route-target import 65000:2
    route-target import 65000:3
!
! [PE3] Branch: DC1(65000:1)과 DC2(65000:2)를 모두 import
ip vrf BR1
    rd 65000:3
    route-target export 65000:3
    route-target import 65000:1
    route-target import 65000:2
    route-target import 65000:3
!
```
