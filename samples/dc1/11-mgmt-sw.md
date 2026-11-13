# MGMT-SW (DC1 관리 전용 L2 스위치)

**목적**: DC1(누리데이터 임대망)의 장비 관리 포트와 관리 PC를 VLAN 900(native, 192.168.100.0/24)에 모음. 누리데이터 관리 전용이라 청명정밀 DC2·개발지사 장비는 연결하지 않음

**핵심**

- Cisco IOSv 스위치. 처음에는 기본 설정이 없으므로 아래 설정을 처음부터 입력함(비밀번호는 `<PASSWORD>`로 직접 정함)
- 포트: `Gi0/0` border-leaf1, `Gi0/1` border-leaf2, `Gi0/2` spine1, `Gi0/3` spine2, `Gi1/0`~`Gi1/3` leaf1~4, `Gi3/3` MGMT-PC. 장비 쪽은 태그 없이 연결되므로 native VLAN 900은 access VLAN 900과 같은 동작
- DC1 장비의 `Management1`은 192.168.100.x/24 그대로이고 MGMT-ACL이 `192.168.100.0/24`를 허용하므로 장비 컨피그는 바꾸지 않음
- SSH가 필요하면 `ip domain-name`과 `crypto key generate rsa`가 먼저 필요(이 이미지에서 확인하지 못함)

**확인 명령**: `show vlan brief`, `show interfaces status`, `show mac address-table vlan 900`, MGMT-PC에서 `ping -c 3 192.168.100.11`, `ssh -l admin 192.168.100.21`

파일: `mgmt-sw.ios`, 관리 PC는 `host/MGMT-PC.sh`

```text
hostname MGMT-SW
enable secret <PASSWORD>
username admin privilege 15 secret <PASSWORD>
vlan 900
 name MGMT-DC1
interface range gigabitethernet 0/0 - 3 , gigabitethernet 1/0 - 3 , gigabitethernet 3/3
 switchport mode access
 switchport access vlan 900
 spanning-tree portfast
 no shutdown
interface vlan 900
 ip address 192.168.100.2 255.255.255.0
 no shutdown
line vty 0 4
 login local
 transport input ssh
```
