# PE-CE eBGP

**목적**: VRF 안에서 고객(DC, Branch) 장비와 eBGP로 경로를 교환

**핵심**

- PE-CE 세션은 `address-family ipv4 vrf <VRF 이름>` 안에 입력. 이웃 주소는 링크 IP
- PE1은 DC1 Hub 2대(AS 65010), PE2는 DC2 CX1, CX2(AS 65201), PE3는 Branch BGW1, BGW2(AS 65020)와 접속
- PE와 CE 양쪽 모두 `timers 3 9`로 통일
- `maximum-paths 2`: 두 CE로 ECMP
- 모든 구역이 같은 방식(eBGP). 구역별 경로 흐름은 [기준 문서](../../baseline/core/07-pe-ce-ebgp.md)
- CE 쪽 설정: Hub는 [Hub 가이드](../../guide/06-hub.md), leaf는 [DC1 PE-CE 샘플](../dc1/09-pe-ce-ebgp.md), BGW는 [Branch 샘플](../br/07-pe3-bgw-ebgp.md)

**확인 명령**: `show bgp vpnv4 unicast vrf TENANT-A summary`(PE2는 PARTNER, PE3는 BR1), `show ip route vrf TENANT-A`

파일: `pe-ce-ebgp.ios`

```text
! Cisco IOS (c7200) - PE-CE eBGP 샘플
! 확인: show bgp vpnv4 unicast vrf TENANT-A summary / show ip route vrf TENANT-A
! PE마다 자기 VRF 블록만 쓴다 (PE1 TENANT-A, PE2 PARTNER, PE3 BR1)
!
! [PE1] TENANT-A: Hub1, Hub2 (AS 65010)
router bgp 65000
    address-family ipv4 vrf TENANT-A
        neighbor 10.0.30.1 remote-as 65010
        neighbor 10.0.30.1 activate
        neighbor 10.0.30.1 timers 3 9
        neighbor 10.0.30.3 remote-as 65010
        neighbor 10.0.30.3 activate
        neighbor 10.0.30.3 timers 3 9
        maximum-paths 2
    exit-address-family
!
! [PE2] PARTNER: CX1, CX2 (AS 65201)
router bgp 65000
    address-family ipv4 vrf PARTNER
        neighbor 10.0.20.5 remote-as 65201
        neighbor 10.0.20.5 activate
        neighbor 10.0.20.5 timers 3 9
        neighbor 10.0.20.7 remote-as 65201
        neighbor 10.0.20.7 activate
        neighbor 10.0.20.7 timers 3 9
        maximum-paths 2
    exit-address-family
!
! [PE3] BR1: BGW1, BGW2 (AS 65020)
router bgp 65000
    address-family ipv4 vrf BR1
        neighbor 10.0.60.1 remote-as 65020
        neighbor 10.0.60.1 activate
        neighbor 10.0.60.1 timers 3 9
        neighbor 10.0.60.3 remote-as 65020
        neighbor 10.0.60.3 activate
        neighbor 10.0.60.3 timers 3 9
        maximum-paths 2
    exit-address-family
!
! [Hub, BGW, CX] CE 쪽 설정은 각 샘플에 있다
!   Hub: guide/06-hub.md, BGW: samples/br/pe3-bgw-ebgp.ios, leaf: samples/dc1/pe-ce-ebgp.eos
!
```
