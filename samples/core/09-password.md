# 비밀번호 지정 위치

**목적**: enable, 계정, 라인, OSPF, LDP, BGP 인증에 비밀번호와 키를 넣는 위치를 정리

**핵심**

- 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않음
- OSPF, BGP, LDP, VRRP 인증은 양쪽 장비의 키 번호와 값이 같아야 함
- `service password-encryption`을 켜면 평문 비밀번호(line password 등)가 약한 암호화로 저장됨

**확인 명령**: `show running-config | include password|secret|authentication`

파일: `password.ios`

```text
! Cisco IOS (c7200) - 비밀번호 지정 위치 샘플 (값은 모두 자리표시자)
! 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않는다
! 확인: show running-config | include password|secret|authentication
!
! 1. 권한 모드(enable)와 계정
enable secret <ENABLE-SECRET>
username admin privilege 15 secret <PASSWORD>
service password-encryption
!
! 2. 라인 비밀번호 (login local을 쓰면 계정 인증이 우선이므로 보통 생략)
line con 0
 password <CONSOLE-PASSWORD>
 login
!
! 3. OSPF 인증 (인터페이스 단위, 양쪽 같은 키)
interface gigabitethernet0/0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 <OSPF-KEY>
!
! 4. LDP 인증 (peer 루프백 주소 기준, 양쪽 같은 키)
mpls ldp neighbor 10.0.0.12 password <LDP-KEY>
!
! 5. BGP neighbor 인증 (iBGP VPNv4와 PE-CE eBGP)
router bgp 65000
 neighbor 10.0.0.12 password <BGP-KEY>
 address-family ipv4 vrf TENANT-A
  neighbor 10.0.20.1 password <PE-CE-KEY>
 exit-address-family
!
```
