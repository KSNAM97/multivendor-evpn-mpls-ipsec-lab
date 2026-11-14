# MGMT-SW1 (DC1 관리 전용 스위치)

**목적**: DC1(누리데이터 임대망)의 장비 관리 포트와 관리 PC를 VLAN 900(native, 10.9.0.0/24)에 모음. 누리데이터 관리 전용이라 청명정밀 DC2·개발지사 장비는 연결하지 않음

**핵심**

- Cisco IOSv 스위치. 처음에는 기본 설정이 없으므로 아래 설정을 처음부터 입력함(비밀번호는 `<PASSWORD>`로 직접 정함)
- 포트: `Gi0/0` border-leaf1, `Gi0/1` border-leaf2, `Gi0/2` spine1, `Gi0/3` spine2, `Gi1/0`~`Gi1/3` leaf1~4, `Gi3/3` MGMT-PC. 장비 쪽은 태그 없이 연결되므로 native VLAN 900은 access VLAN 900과 같은 동작
- DC1 장비의 `Management1`은 `vrf MGMT`의 `10.9.0.x/24`(spine .11, .12, leaf .21~.24, border-leaf .25, .26). 게이트웨이(라우터)가 없는 SVI 방식이라 모든 장비와 MGMT-PC가 같은 서브넷
- 게이트웨이는 MGMT-RTR `Gi0/0`(10.9.0.1). MGMT-SW1 `Gi3/2`를 라우터에 연결하고 `ip default-gateway 10.9.0.1`. 코어 관리망(MGMT-SW2, 10.9.1.0/24)과의 경계는 [코어 관리 샘플](../core/10-mgmt.md) 참조
- SSH는 MGMT-ACL로 관리 PC(`10.9.0.10`)에서만 허용
- SSH가 필요하면 `ip domain-name`을 넣고 `crypto key generate rsa modulus 2048`을 먼저 실행(이 이미지에서 확인하지 못함)

**확인 명령**: `show vlan brief`, `show interfaces status`, `show mac address-table vlan 900`, MGMT-PC에서 `ping -c 3 10.9.0.11`, `ssh -l admin 10.9.0.21`

파일: `mgmt-sw1.ios`, 관리 PC는 `host/MGMT-PC1.sh`

```text
service timestamps debug datetime msec
service timestamps log datetime msec
service password-encryption
hostname MGMT-SW1
no ip domain-lookup
ip domain-name lab.local
ip ssh version 2
enable secret <PASSWORD>
username admin privilege 15 secret <PASSWORD>
vlan 900
 name MGMT-DC1
interface range gigabitethernet 0/0 - 3 , gigabitethernet 1/0 - 3 , gigabitethernet 3/3
 switchport mode access
 switchport access vlan 900
 spanning-tree portfast
 spanning-tree bpduguard enable
 no shutdown
interface vlan 900
 ip address 10.9.0.2 255.255.255.0
 no shutdown
line vty 0 4
 exec-timeout 0 0
 privilege level 15
 login local
 transport input ssh
 logging synchronous
```
