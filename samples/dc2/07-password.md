# 비밀번호 지정 위치

**목적**: 계정과 BGP neighbor 인증에 비밀번호와 키를 넣는 위치를 정리

**핵심**

- 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않음
- OSPF, BGP, LDP, VRRP 인증은 양쪽 장비의 키 번호와 값이 같아야 함
- `password plaintext` 뒤에 값을 입력하면 장비가 암호화해서 저장

**확인 명령**: `show running-config`, `show bgp vrf TENANT-A all neighbors`

파일: `password.aos`

```text
! Aruba AOS-CX - 비밀번호 지정 위치 샘플 (값은 모두 자리표시자)
! 실제 비밀번호와 키는 컨피그 파일에만 두고 문서에는 적지 않는다
! 확인: show running-config / show bgp vrf TENANT-A all neighbors
!
! 1. 계정 (administrators 그룹)
user admin group administrators password plaintext <PASSWORD>
!
! 2. BGP neighbor 인증 (VRF 안)
router bgp 65201
    vrf TENANT-A
        neighbor 10.0.20.4 password plaintext <BGP-KEY>
!
```
