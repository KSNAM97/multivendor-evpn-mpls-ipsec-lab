# 관리망 연결과 SSH 제한 (DSW, ASW1)

**목적**: DSW1, DSW2, ASW1의 관리 포트(`Gi3/3`)를 MGMT-SW에 연결하고, 관리망에서만 SSH로 접속하게 제한

**핵심**

| 장비 | 이미지 | `Gi3/3` 방식 | 관리 주소 | MGMT-SW 포트 |
|---|---|---|---|---|
| DSW1 | IOSvL3 | `no switchport` + **VRF MGMT** | 192.168.100.44/24 | Et10 |
| DSW2 | IOSvL3 | 같음 | 192.168.100.45/24 | Et11 |
| ASW1 | IOSvL2 | access VLAN 100 + `Vlan100` SVI (VRF 없음) | 192.168.100.46/24 | Et12 |

- DSW는 `gigabitethernet 3/3`을 **VRF MGMT**에 넣어 데이터 라우팅(OSPF, SVI)과 분리. IOSvL3의 물리 포트는 기본이 L2 스위치 포트라서 `no switchport`를 먼저 입력해야 `vrf forwarding`과 `ip address`가 받아짐 (`% Invalid input detected`가 나오는 경우)
- ASW1은 L2 이미지(IOSvL2)라 물리 포트에 IP를 줄 수 없고 `no switchport`도 없음(`vrf forwarding`, `ip address`가 `% Invalid input detected`). 그래서 `Gi3/3`을 access VLAN 100에 두고 `interface vlan 100`에 관리 주소를 줌. VLAN 100은 ASW1에만 있고 트렁크 allowed(50,60)에 넣지 않아 관리 트래픽이 데이터 트렁크로 나가지 않음
- vty 접속은 `access-class MGMT-ACL`로 `192.168.100.0/24`만 허용. DSW는 VRF 안의 인터페이스로 들어오는 접속도 같이 걸러야 해서 `in vrf-also`, ASW1은 VRF가 없어서 `in`
- `line vty 0 4` 블록은 **하나만** 두고, 기본 설정([01-base](01-base.md))의 vty 설정에 `access-class` 한 줄을 더함. 블록을 두 번 쓰면 설정이 섞임
- IOS 버전에 따라 VRF 선언이 다름(15.x `vrf definition`, 12.4 `ip vrf`). 이 이미지에서는 `?`로 확인. `access-class`의 `vrf-also` 옵션 지원도 이미지에서 확인이 필요
- SSH는 키를 만들어야 올라옴(`crypto key generate rsa modulus 2048`, exec 모드).
- c7200(PE, Hub, BGW)은 관리 포트가 없어서 콘솔로만 접속하며 이 설정이 필요 없음

**확인 명령**: `show ip interface brief`, `show ip ssh`, `show access-lists MGMT-ACL`

파일: `mgmt-access.ios`

```text
! Cisco IOSv - 관리망 연결과 SSH 제한 샘플 (DSW1, DSW2, ASW1)
! DSW(IOSvL3): Gi3/3 을 MGMT-SW 로 연결하고 VRF MGMT 에 넣어 데이터 라우팅과 분리한다
! ASW1(IOSvL2): 물리 포트에 IP를 줄 수 없어서 Gi3/3 을 access VLAN 100 에 두고 Vlan100 SVI 로 관리한다
! 장비마다 주소만 다르다: DSW1 192.168.100.44, DSW2 192.168.100.45, ASW1 192.168.100.46
! MGMT-SW 포트는 DSW1 Et10, DSW2 Et11, ASW1 Et12
! IOS 버전에 따라 VRF 선언이 다르다: 15.x 는 vrf definition, 12.4 는 ip vrf (먼저 ? 로 확인)
! 확인: show ip interface brief / show ip ssh / show access-lists MGMT-ACL
!
! [DSW1, DSW2] VRF MGMT
vrf definition MGMT
 address-family ipv4
 exit-address-family
!
! [DSW1] (DSW2는 192.168.100.45)
interface gigabitethernet 3/3
    description to-MGMT-SW
    no switchport
    vrf forwarding MGMT
    ip address 192.168.100.44 255.255.255.0
    no shutdown
!
! [ASW1] VRF 없이 관리 VLAN 100 (VLAN 100은 트렁크 allowed 50,60에 넣지 않는다)
vlan 100
    name MGMT
!
interface gigabitethernet 3/3
    description to-MGMT-SW
    switchport mode access
    switchport access vlan 100
    no shutdown
!
interface vlan 100
    description MGMT
    ip address 192.168.100.46 255.255.255.0
    no shutdown
!
! SSH (exec 모드에서 키 생성 필요: crypto key generate rsa modulus 2048)
ip ssh version 2
!
ip access-list standard MGMT-ACL
    permit 192.168.100.0 0.0.0.255
!
! line vty 0 4 는 기본 설정 샘플의 vty 블록에 access-class 한 줄을 더한 형태로 쓴다
! (line vty 블록을 따로 두 번 쓰면 뒤의 설정이 앞의 설정과 섞인다)
! DSW는 access-class MGMT-ACL in vrf-also, ASW1은 VRF가 없어서 access-class MGMT-ACL in
line vty 0 4
    exec-timeout 0 0
    privilege level 15
    login local
    transport input ssh
    logging synchronous
    access-class MGMT-ACL in vrf-also
!
```
