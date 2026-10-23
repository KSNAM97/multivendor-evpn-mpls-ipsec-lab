# 비밀번호 지정 위치

**목적**: 계정, enable, BGP, OSPF 인증에 비밀번호와 키를 넣는 위치를 정리

**핵심**

- 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않음
- OSPF, BGP, LDP, VRRP 인증은 양쪽 장비의 키 번호와 값이 같아야 함
- BGP는 peer group에 한 번 지정하면 모든 neighbor에 적용됨

**확인 명령**: `show running-config section username`, `show bgp neighbors`

파일: `password.eos`

```text
! Arista EOS - 비밀번호 지정 위치 샘플 (값은 모두 자리표시자)
! 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않는다
! 확인: show running-config section username / show bgp neighbors | include authentication
!
! 1. 계정 (권한 15, network-admin 역할)
username admin privilege 15 role network-admin secret <PASSWORD>
!
! 2. enable 비밀번호 (선택, 없으면 privilege 15 계정은 바로 권한 모드)
enable password <ENABLE-PASSWORD>
!
! 3. BGP neighbor 인증 (peer group 단위로 한 번에)
router bgp 65100
   neighbor SPINES password <BGP-KEY>
!
! 4. OSPF 인증 (인터페이스 단위, 양쪽 키 번호와 값이 같아야 한다)
interface ethernet1
   ip ospf authentication message-digest
   ip ospf message-digest-key 1 md5 <OSPF-KEY>
!
```
