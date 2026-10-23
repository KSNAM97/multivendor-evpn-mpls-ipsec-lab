# VSX active gateway

**목적**: VSX 쌍이 같은 게이트웨이 주소를 active-active로 제공

**핵심**

- 각 스위치는 자기 SVI 주소(.2, .3)를 가지고, `active-gateway ip`와 MAC은 양쪽에 같게 설정

**확인 명령**: `show ip interface vlan110`, `show vsx configuration`

파일: `active-gateway.aos`

```text
! Aruba AOS-CX - VSX active gateway 샘플 (값은 예시)
! 확인: show ip interface vlan110 / show vsx configuration
! CX1은 ip address .2, CX2는 .3, active gateway(.1)와 MAC은 양쪽에 같게 설정
!
interface vlan 110
    description APP-DC2
    vrf attach TENANT-A
    ip address 192.168.110.2/24
    active-gateway ip mac 12:00:00:00:01:10
    active-gateway ip 192.168.110.1
!
```
