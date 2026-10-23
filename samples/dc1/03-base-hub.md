# 기본 설정 - Hub (Cisco IOS)

**목적**: HUB1, HUB2(c7200)의 장비 이름, 권한 모드, domain-lookup, 세션을 설정

**핵심**

- `no ip domain-lookup`: 오타를 입력했을 때 DNS 조회로 멈추는 것을 막음
- `enable secret`과 `username ... privilege 15 secret`으로 권한 모드를 보호하고, 콘솔과 vty는 `privilege level 15`로 바로 권한 모드로 진입
- `exec-timeout 0 0`과 `logging synchronous`로 세션 유지와 입력 줄 보호를 함
- SSH를 쓰려면 hostname과 domain-name을 설정한 뒤 exec 모드에서 `crypto key generate rsa modulus 2048`이 필요

**확인 명령**: `show running-config | include hostname|domain|enable|username`

파일: `base-hub.ios`

```text
! Cisco IOS (c7200) - 기본 설정 샘플 (Hub1 기준, 값은 예시)
! 호스트 이름은 GNS3 노드 이름과 같게 한다: HUB1, HUB2
! 확인: show running-config | include hostname|domain|enable|username
! 비밀번호는 문서에 적지 않고 자리표시자로 둔다
!
service timestamps debug datetime msec
service timestamps log datetime msec
service password-encryption
!
hostname HUB1
!
! 오타를 입력했을 때 DNS 조회로 멈추는 것을 막는다
no ip domain-lookup
ip domain-name lab.local
!
! 권한 모드(enable)와 계정
enable secret <ENABLE-SECRET>
username admin privilege 15 secret <PASSWORD>
!
! 콘솔: 바로 권한 모드로 진입, 세션 유지, 출력 중 입력 줄 보호
line con 0
 exec-timeout 0 0
 privilege level 15
 logging synchronous
!
line vty 0 4
 exec-timeout 0 0
 privilege level 15
 login local
 transport input ssh
 logging synchronous
!
! SSH (exec 모드에서 키 생성 필요: crypto key generate rsa modulus 2048)
ip ssh version 2
!
logging buffered 16384
clock timezone KST 9 0
!
banner motd #
 LAB HUB1 - authorized use only
#
!
```
