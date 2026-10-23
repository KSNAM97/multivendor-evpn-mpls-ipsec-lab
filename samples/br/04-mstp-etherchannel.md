# MSTP + EtherChannel

**목적**: DSW 쌍과 ASW 사이를 EtherChannel로 이중화하고 MSTP 인스턴스별로 root를 나눔.

**핵심**

- 인스턴스 1(VLAN 50)은 DSW1, 인스턴스 2(VLAN 60)는 DSW2가 root
- ASW1은 각 DSW에 2링크 EtherChannel을 하나씩 갖고, 인스턴스별로 blocking이 갈림
- 번들마다 번호가 다름: Po1(DSW1-DSW2), Po2(DSW1-ASW1), Po3(DSW2-ASW1). DSW2의 ASW1 방향 번들은 **Po3**(DSW1은 Po2). DSW2의 MST priority는 DSW1과 반대(mst 1 = 8192, mst 2 = 4096)
- **멤버 포트에도 port-channel과 같은 trunk 설정**(`switchport trunk encapsulation dot1q`, `mode trunk`, `native vlan 999`, `allowed vlan 50,60`)을 넣고 `channel-group`을 넣음. 멤버에 encapsulation이 auto로 남으면 `%EC-5-CANNOT_BUNDLE2 ... trunk encap of Gi0/1 is auto, Po1 is dot1q`로 번들이 suspended됨 (장비에서 확인)
- MSTP는 DSW1, DSW2, ASW1이 **같은 region**(name `LAB`, revision 1, instance 매핑)이어야 하나의 토폴로지로 동작. ASW1에도 같은 `spanning-tree mst configuration`과 VLAN 50, 60, 999가 필요
- 호스트 포트는 ASW1 `Gi1/0`(VLAN 50, Host F), `Gi1/1`(VLAN 60, Host G). `portfast`와 `bpduguard`를 줌
- ASW1은 L2 스위치라 **SVI와 `ip routing`이 없음**. 관리는 `gigabitethernet 3/3`(access VLAN 100)의 `Vlan100` SVI(192.168.100.46)로만 하고([관리망](03-mgmt-access.md)), 호스트의 게이트웨이는 DSW의 SVI(VRRP VIP)
- ASW1은 MST priority를 따로 주지 않음(기본값). root는 DSW가 맡음
- LACP는 **기본(30초 간격)**을 씀. 이 IOSvL3 이미지는 `lacp rate fast`를 받지 않음(`% Invalid input`). DC1에서 쓰는 fast(1초)와 달리 Branch EtherChannel은 기본값. ASW1(IOSvL2)에서 되는지는 `?`로 확인

**확인 명령**: `show spanning-tree mst`, `show etherchannel summary`, `show interfaces trunk`

파일: `mstp-etherchannel.ios`

```text
! Cisco IOSv - MSTP + EtherChannel(LACP) 샘플 (DSW1, DSW2, ASW1)
! 확인: show spanning-tree mst / show etherchannel summary / show interfaces trunk
! IOSvL2/L3의 지원 명령은 이미지에 따라 다를 수 있다 (먼저 ? 로 확인)
! 멤버 포트에도 port-channel과 같은 trunk 설정(encapsulation, mode, native, allowed)을 넣는다
!   (멤버가 auto encapsulation이면 "%EC-5-CANNOT_BUNDLE2 ... trunk encap of Gi0/1 is auto, Po1 is dot1q"로 suspended)
! 이 IOSvL3 이미지는 lacp rate fast 를 받지 않는다 (% Invalid input). 기본(30초 간격)을 쓴다
!
! 번들: Po1 DSW1-DSW2 (Gi0/1-2), Po2 DSW1-ASW1 (DSW1 Gi0/3, Gi1/0 / ASW1 Gi0/0-1),
!       Po3 DSW2-ASW1 (DSW2 Gi0/3, Gi1/0 / ASW1 Gi0/2-3)
!
! [공통] VLAN과 MSTP region은 DSW1, DSW2, ASW1 모두 같은 값 (name, revision, instance가 같아야 한 region)
vlan 50
    name BR-LAN50
vlan 60
    name BR-LAN60
vlan 999
    name NATIVE
!
spanning-tree mode mst
spanning-tree mst configuration
    name LAB
    revision 1
    instance 1 vlan 50
    instance 2 vlan 60
!
! [DSW1] MST root 분담: 인스턴스 1(VLAN 50)은 DSW1, 인스턴스 2(VLAN 60)는 DSW2
spanning-tree mst 1 priority 4096
spanning-tree mst 2 priority 8192
! (DSW2는 priority 값을 서로 바꾼다: mst 1 = 8192, mst 2 = 4096. ASW1은 기본값)
!
! [DSW1] Po1 (DSW2 방향). 멤버 포트에 trunk 설정을 먼저 넣고 channel-group을 넣는다
interface range gigabitethernet 0/1 - 2
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
    channel-group 1 mode active
!
interface port-channel 1
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
!
! [DSW1] Po2 (ASW1 방향)
interface range gigabitethernet 0/3 , gigabitethernet 1/0
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
    channel-group 2 mode active
!
interface port-channel 2
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
!
! [DSW2] Po1 (DSW1 방향): DSW1의 Po1과 같은 설정, 멤버 Gi0/1-2
! [DSW2] Po3 (ASW1 방향): Po2와 같은 설정에서 번호만 3, 멤버 Gi0/3, Gi1/0
interface range gigabitethernet 0/3 , gigabitethernet 1/0
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
    channel-group 3 mode active
!
interface port-channel 3
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
!
! [ASW1] 두 DSW로 향하는 EtherChannel (Po2: DSW1, Po3: DSW2). IOSvL2도 encapsulation을 dot1q로 먼저 지정해야 trunk가 받아진다 (auto에서는 "Command rejected ... Auto can not be configured to trunk mode")
vtp mode transparent
!
interface range gigabitethernet 0/0 - 1
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
    channel-group 2 mode active
!
interface port-channel 2
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
!
interface range gigabitethernet 0/2 - 3
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
    channel-group 3 mode active
!
interface port-channel 3
    switchport trunk encapsulation dot1q
    switchport mode trunk
    switchport trunk native vlan 999
    switchport trunk allowed vlan 50,60
!
! [ASW1] 호스트 포트: Gi1/0 = VLAN 50 (Host F), Gi1/1 = VLAN 60 (Host G)
interface gigabitethernet 1/0
    description Host F
    switchport mode access
    switchport access vlan 50
    spanning-tree portfast
    spanning-tree bpduguard enable
!
interface gigabitethernet 1/1
    description Host G
    switchport mode access
    switchport access vlan 60
    spanning-tree portfast
    spanning-tree bpduguard enable
!
```
