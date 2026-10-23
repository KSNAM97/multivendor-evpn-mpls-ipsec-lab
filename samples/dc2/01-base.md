# 기본 설정 (장비 이름, 계정, 세션)

**목적**: 장비 이름, 관리자 계정, 세션 유지, 관리 인터페이스를 설정

**핵심**

- 호스트 이름은 GNS3 노드 이름과 같게 함
- `user ... group administrators`로 관리자 계정을 만들고, `cli-session timeout 0`으로 세션 유지를 함
- 관리 인터페이스는 `interface mgmt`에 고정 IP를 지정
- DNS 서버를 지정하지 않으면 도메인 조회를 하지 않는 것으로 알려져 있어 `no ip domain-lookup`에 해당하는 설정을 두지 않았음(시뮬레이터에서 확인 필요).

**확인 명령**: `show running-config`, `show ssh server`, `show interface mgmt`

파일: `base.aos`

```text
! Aruba AOS-CX - 기본 설정 샘플 (CX1 기준, 값은 예시)
! 호스트 이름은 GNS3 노드 이름과 같게 한다: CX1, CX2, CX3
! 확인: show running-config / show ssh server / show interface mgmt
! 비밀번호는 문서에 적지 않고 자리표시자로 둔다
!
hostname CX1
!
! 계정 (administrators 그룹 = 모든 명령 사용 가능)
user admin group administrators password plaintext <PASSWORD>
!
! CLI 세션이 끊기지 않게 (실습용)
cli-session
    timeout 0
!
! 관리 인터페이스 (GNS3 어댑터 0번)
interface mgmt
    no shutdown
    ip static 192.168.100.41/24
!
ssh server vrf mgmt
!
banner motd !
LAB CX1 - authorized use only
!
! 참고: AOS-CX는 DNS 서버를 따로 지정하지 않으면 도메인 조회를 하지 않으므로
!       Cisco의 "no ip domain-lookup" 에 해당하는 설정이 필요 없다 (시뮬레이터에서 확인)
!
```
