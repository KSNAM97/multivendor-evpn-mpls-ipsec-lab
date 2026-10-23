# Branch OSPF

**목적**: BGW와 DSW 사이를 OSPF area 0으로 연결

**핵심**

- OSPF router-id는 `loopback0` 주소(10.0.0.x)이고, BGP router-id(BGW 10.0.1.31, 10.0.1.32)와 다른 값
- 점대점 링크는 `ip ospf network point-to-point`, 루프백은 passive로 둠
- 인터페이스 방식(`ip ospf 1 area 0`)으로 넣음. 코어 PE와 같은 형식이고 BGW에서 검증됨. 이미지가 이 방식을 받지 않으면 `network` 문으로 바꿈
- 빠른 수렴을 위해 BGW-DSW 링크마다 `ip ospf hello-interval 1`, `ip ospf dead-interval 4`로 타이머를 줄임(양쪽 같은 값)
- BGW의 `gigabitethernet 0/0`(PE3 방향 WAN 링크)과 터널은 OSPF에 **넣지 않음**. PE3와는 eBGP, Hub와는 터널 위 eBGP
- BGW는 `default-information originate always`로 DSW에 **default route**를 내려보냄. DC1, DC2 경로는 터널 위 eBGP로 BGW까지만 오므로, Host F, G가 DC로 가려면 DSW에 default가 있어야 함(BGW에 default가 없어도 `always`로 항상 광고)
- DSW는 `vlan 50`, `vlan 60`(Branch LAN)을 passive로 OSPF에 포함. BGW가 이 서브넷을 Hub로 광고하려면 필요. SVI가 올라와 있어야(VLAN과 SVI 주소 입력 뒤) 광고됨

**확인 명령**: `show ip ospf neighbor`, `show ip route ospf`, `show ip protocols`(passive 확인)

파일: `ospf-branch.ios`

```text
! Cisco IOS - Branch OSPF 샘플 (BGW1, BGW2, DSW1, DSW2)
! 확인: show ip ospf neighbor / show ip route ospf / show ip protocols
! 장비마다 값만 다르고 형식은 같다
!   BGW1 router-id 10.0.0.31, Gi1/0 10.50.0.0/31 (DSW1 Gi0/0 상대)
!   BGW2 router-id 10.0.0.32, Gi1/0 10.50.0.2/31 (DSW2 Gi0/0 상대)
!   DSW1 router-id 10.0.0.41, Gi0/0 10.50.0.1/31, SVI 192.168.50.2, 192.168.60.2
!   DSW2 router-id 10.0.0.42, Gi0/0 10.50.0.3/31, SVI 192.168.50.3, 192.168.60.3
! IP 주소는 인터페이스 단계에서 먼저 입력한 뒤에 OSPF를 입력한다
! BGW의 Gi0/0(PE3 방향 WAN 링크)은 OSPF에 넣지 않는다
! 인터페이스 방식(ip ospf 1 area 0)을 받지 않는 이미지는 network 문으로 바꾼다
!
! [BGW1] (BGW2는 router-id 10.0.0.32)
! default-information originate always: DSW가 DC 방향 경로를 default route로 받는다
! (BGW에 default가 없어도 항상 광고. DC 경로는 BGP로 BGW까지만 오고 OSPF로 내려가지 않기 때문)
router ospf 1
    router-id 10.0.0.31
    no passive-interface default
    passive-interface loopback 0
    default-information originate always
!
interface loopback 0
    ip ospf 1 area 0
!
interface gigabitethernet 1/0
    ip ospf network point-to-point
    ip ospf hello-interval 1
    ip ospf dead-interval 4
    ip ospf 1 area 0
!
! [DSW1] (DSW2는 router-id 10.0.0.42). Branch LAN(SVI)을 passive로 OSPF에 포함
! SVI는 VLAN 50, 60과 SVI 주소를 먼저 입력해야 올라온다 (SVI 샘플 참고)
router ospf 1
    router-id 10.0.0.41
    no passive-interface default
    passive-interface loopback 0
    passive-interface vlan 50
    passive-interface vlan 60
!
interface loopback 0
    ip ospf 1 area 0
!
interface gigabitethernet 0/0
    ip ospf network point-to-point
    ip ospf hello-interval 1
    ip ospf dead-interval 4
    ip ospf 1 area 0
!
interface vlan 50
    ip ospf 1 area 0
!
interface vlan 60
    ip ospf 1 area 0
!
```
