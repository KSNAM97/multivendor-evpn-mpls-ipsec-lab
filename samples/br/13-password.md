# 비밀번호 지정 위치

**목적**: enable, 계정, VRRP, OSPF, BGP, IPsec 사전 공유 키를 넣는 위치를 정리

**핵심**

- 계정, enable 비밀번호와 IPsec 사전 공유 키는 공개된 실습 랩 전용 값이며 실제 환경에 재사용하지 않음. 키 목록은 [키 관리](../../baseline/br/08-ipsec-keys.md)
- OSPF, BGP, LDP, VRRP 인증은 양쪽 장비의 키 번호와 값이 같아야 함
- IPsec 사전 공유 키는 `crypto isakmp key`로 지정하고, 양쪽 장비에서 같은 값이어야 함

**확인 명령**: `show running-config | include password|secret|authentication|pre-shared`

파일: `password.ios`

```text
! Cisco IOS / IOSv - 비밀번호 지정 위치 샘플 (값은 모두 자리표시자)
! 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않는다
! 확인: show running-config | include password|secret|authentication|pre-shared
!
! 1. 권한 모드(enable)와 계정
enable secret <ENABLE-SECRET>
username admin privilege 15 secret <PASSWORD>
service password-encryption
!
! 2. VRRP 인증 (DSW 양쪽 같은 키)
interface vlan50
 vrrp 50 authentication text <VRRP-KEY>
!
! 3. OSPF 인증 (BGW-DSW 링크, 양쪽 같은 키)
interface gigabitethernet1/0
 ip ospf authentication message-digest
 ip ospf message-digest-key 1 md5 <OSPF-KEY>
!
! 4. BGP neighbor 인증 (터널 위 eBGP)
router bgp 65020
 neighbor 10.0.40.0 password <BGP-KEY>
!
! 5. IPsec(IKEv1) 사전 공유 키 (peer 언더레이 주소 기준, 양쪽 같은 값)
crypto isakmp key Fy2Wa7sRcCosSoXG5TXziEVq address 10.0.30.1
!
```
