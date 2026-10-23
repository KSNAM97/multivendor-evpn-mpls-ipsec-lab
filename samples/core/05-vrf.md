# VRF

**목적**: 고객별 라우팅 테이블을 분리하고 RD와 RT를 지정

**핵심**

- RD는 같은 prefix를 PE마다 구분하는 값, RT는 어느 VRF가 경로를 가져가고 내보낼지 정하는 값
- 같은 VRF는 모든 PE에서 같은 RD, 같은 RT를 사용(TENANT-A 65000:1, WAN-UL 65000:99)
- TENANT-A는 PE1, PE2에, WAN-UL은 PE1, PE3에만 정의
- RD와 RT는 [MP-BGP VPNv4](06-mp-bgp-vpnv4.md) 단계에서 경로 교환에 쓰임

**확인 명령**: `show ip vrf`, `show ip vrf detail`

파일: `vrf.ios`

```text
! Cisco IOS (c7200) - VRF 샘플 (PE1 기준)
! 확인: show ip vrf / show ip vrf detail / show ip route vrf TENANT-A
! 인터페이스 소속(ip vrf forwarding)은 02 인터페이스 IP 단계에서 이미 입력했다
! IOS 버전에 따라 VRF 선언이 다르다: 12.4는 "ip vrf", 15.x는 "vrf definition"
! PE2는 TENANT-A만, PE3는 WAN-UL만 정의한다
!
ip vrf TENANT-A
    rd 65000:1
    route-target both 65000:1
!
ip vrf WAN-UL
    rd 65000:99
    route-target both 65000:99
!
```
