# PE와 VRF eBGP

**목적**: VSX 쌍이 MPLS 코어(PE2)와 VRF 경로를 교환

**핵심**

- 인터페이스를 `vrf attach`하고 `router bgp` 아래 VRF 블록에서 neighbor를 activate함

- BGP router-id(CX1 10.2.2.1, CX2 10.2.2.2)는 loopback0 주소(10.2.0.1, 10.2.0.2)와 다른 값을 씀
- BGP 타이머는 DC1과 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일함(기본 60초, 180초). 양쪽이 협상해 작은 hold 값을 씀. AOS-CX의 `neighbor ... timers` 문법은 이미지에서 `?`로 확인

**확인 명령**: `show bgp vrf TENANT-A all summary`, `show ip route vrf TENANT-A`

파일: `ebgp-pe.aos`

```text
! Aruba AOS-CX - PE2와 VRF eBGP 샘플 (CX1 기준, 값은 예시)
! 확인: show bgp vrf TENANT-A all summary / show ip route vrf TENANT-A
! CX2는 bgp router-id 10.2.2.2, neighbor 10.0.20.6 (PE2 Gi3/0 방향)
!
! VRF, loopback 0, 1/1/1 IP는 02 인터페이스 IP 단계에서 이미 입력
!
router bgp 65201
    bgp router-id 10.2.2.1
    vrf TENANT-A
        neighbor 10.0.20.4 remote-as 65000
        neighbor 10.0.20.4 timers 3 9
        address-family ipv4 unicast
            neighbor 10.0.20.4 activate
            redistribute connected
        exit-address-family
!
```
