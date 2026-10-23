# VSX

**목적**: 두 스위치를 VSX 쌍으로 묶음

**핵심**

- ISL은 `lag 256`(1/1/2-3), keepalive는 별도 링크(1/1/4)를 전용 VRF에 둠
- 두 번째 스위치는 `role secondary`로 하고 keepalive의 peer와 source 주소를 서로 바꿈.

**확인 명령**: `show vsx status`, `show vsx brief`

파일: `vsx.aos`

```text
! Aruba AOS-CX - VSX 샘플 (CX1 = primary 기준, 값은 예시)
! 확인: show vsx status / show vsx brief / show lacp interfaces
! CX2는 role secondary, keepalive peer/source 를 서로 바꾼다
!
vrf KEEPALIVE
!
vlan 999
    name NATIVE
!
interface lag 256
    no shutdown
    description VSX-ISL
    no routing
    vlan trunk native 999
    vlan trunk allowed all
    lacp mode active
!
interface 1/1/2
    no shutdown
    lag 256
!
interface 1/1/3
    no shutdown
    lag 256
!
interface 1/1/4
    no shutdown
    description VSX-KEEPALIVE
    vrf attach KEEPALIVE
    ip address 10.2.254.0/31
!
vsx
    system-mac 02:00:00:00:01:01
    inter-switch-link lag 256
    role primary
    keepalive peer 10.2.254.1 source 10.2.254.0 vrf KEEPALIVE
!
```
