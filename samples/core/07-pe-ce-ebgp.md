# PE-CE eBGP

**목적**: VRF 안에서 고객(DC) 장비와 eBGP로 경로를 교환

**핵심**

- PE-CE 세션은 `address-family ipv4 vrf <VRF 이름>` 안에 입력. 이웃 주소는 링크 IP
- DC1 leaf3, leaf4는 AS 65100, DC2 CX1, CX2는 AS 65201
- PE와 CE 양쪽 모두 `timers 3 9`로 통일
- `maximum-paths 2`: 두 CE로 ECMP
- WAN-UL은 구역별로 방식을 나눔. PE1 - Hub는 PE1이 `redistribute connected`만 하고 Hub 쪽에 정적 경로, PE3 - BGW는 eBGP(BGW AS 65020). 이유는 [기준 문서](../../baseline/core/07-pe-ce-ebgp.md)
- CE(leaf) 쪽 설정은 [DC1 PE-CE 샘플](../dc1/09-pe-ce-ebgp.md)

**확인 명령**: `show bgp vpnv4 unicast vrf TENANT-A summary`, `show ip route vrf TENANT-A`

파일: `pe-ce-ebgp.ios`

```text
! Cisco IOS (c7200) - PE-CE eBGP 샘플 (PE1 기준)
! 확인: show bgp vpnv4 unicast vrf TENANT-A summary / show ip route vrf TENANT-A
! PE2는 TENANT-A 이웃 CX1 10.0.20.5, CX2 10.0.20.7 (AS 65201)
! PE3는 TENANT-A가 없고 WAN-UL만 있다 (BGW와 eBGP, 아래 [PE3] 블록)
!
router bgp 65000
    address-family ipv4 vrf TENANT-A
        neighbor 10.0.20.1 remote-as 65100
        neighbor 10.0.20.1 activate
        neighbor 10.0.20.1 timers 3 9
        neighbor 10.0.20.3 remote-as 65100
        neighbor 10.0.20.3 activate
        neighbor 10.0.20.3 timers 3 9
        maximum-paths 2
    exit-address-family
    !
    address-family ipv4 vrf WAN-UL
        redistribute connected
    exit-address-family
!
! [PE2] TENANT-A: CX1, CX2 (AS 65201)
router bgp 65000
    address-family ipv4 vrf TENANT-A
        neighbor 10.0.20.5 remote-as 65201
        neighbor 10.0.20.5 activate
        neighbor 10.0.20.5 timers 3 9
        neighbor 10.0.20.7 remote-as 65201
        neighbor 10.0.20.7 activate
        neighbor 10.0.20.7 timers 3 9
        maximum-paths 2
    exit-address-family
!
! [PE3] WAN-UL: BGW1, BGW2 (AS 65020). 직결 링크를 VPNv4에 싣고 BGW와 eBGP
router bgp 65000
    address-family ipv4 vrf WAN-UL
        redistribute connected
        neighbor 10.0.30.5 remote-as 65020
        neighbor 10.0.30.5 activate
        neighbor 10.0.30.5 timers 3 9
        neighbor 10.0.30.7 remote-as 65020
        neighbor 10.0.30.7 activate
        neighbor 10.0.30.7 timers 3 9
    exit-address-family
!
! [BGW1, BGW2] PE3 쪽 이웃 설정은 Branch 샘플 "PE3 - BGW eBGP"(samples/br/wan-ebgp.ios)에 있다
!
! [Hub1] BGW1 터널 주소로 가는 정적 경로 (Hub2는 10.0.30.7 255.255.255.255 10.0.30.2)
ip route 10.0.30.5 255.255.255.255 10.0.30.0
!
```
