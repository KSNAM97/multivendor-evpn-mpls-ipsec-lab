# SVI + VRRP

**목적**: Branch LAN의 기본 게이트웨이를 DSW 두 대로 이중화

**핵심**

- VLAN 50은 DSW1, VLAN 60은 DSW2가 master가 되도록 priority를 반대로 둠
- **VLAN을 먼저 만들어야** SVI가 올라옴. 포트가 아직 없으면 SVI가 down일 수 있고, 이때 `no autostate`(지원 여부는 `?`로 확인)로 올릴 수 있음. EtherChannel이 올라온 뒤에는 필요 없음
- DSW1은 `vlan 50`이 .2(priority 110), `vlan 60`이 .2(priority 100). DSW2는 `vlan 50`이 .3(priority 100), `vlan 60`이 .3(priority 110)
- DSW는 `ip routing`이 켜져 있어야 SVI끼리 라우팅됨 ([기본 설정](01-base.md))
- SVI는 OSPF에 passive로 넣어 Branch LAN을 BGW로 광고 ([Branch OSPF](06-ospf-branch.md))

**확인 명령**: `show vrrp brief`, `show ip interface brief`, `show vlan brief`

파일: `vrrp-svi.ios`

```text
! Cisco IOSvL3 - VLAN, SVI + VRRP 샘플 (DSW1, DSW2)
! VLAN 50은 DSW1이 master(priority 110), VLAN 60은 DSW2가 master(priority 110)
! 확인: show vrrp brief / show ip interface brief / show vlan brief
! VLAN이 먼저 있어야 SVI가 올라온다 (포트가 없어도 올리려면 no autostate, ? 로 지원 확인)
! MSTP root와 VRRP master를 같은 DSW로 맞춘다 (MSTP 샘플 참고)
!
ip routing
!
vlan 50
    name BR-LAN50
vlan 60
    name BR-LAN60
vlan 999
    name NATIVE
!
! [DSW1]
interface vlan 50
    description BR-LAN50
    ip address 192.168.50.2 255.255.255.0
    vrrp 50 ip 192.168.50.1
    vrrp 50 priority 110
    vrrp 50 preempt
    no shutdown
!
interface vlan 60
    description BR-LAN60
    ip address 192.168.60.2 255.255.255.0
    vrrp 60 ip 192.168.60.1
    vrrp 60 priority 100
    vrrp 60 preempt
    no shutdown
!
! [DSW2] 주소와 priority가 다르고 나머지는 같다
interface vlan 50
    description BR-LAN50
    ip address 192.168.50.3 255.255.255.0
    vrrp 50 ip 192.168.50.1
    vrrp 50 priority 100
    vrrp 50 preempt
    no shutdown
!
interface vlan 60
    description BR-LAN60
    ip address 192.168.60.3 255.255.255.0
    vrrp 60 ip 192.168.60.1
    vrrp 60 priority 110
    vrrp 60 preempt
    no shutdown
!
```
