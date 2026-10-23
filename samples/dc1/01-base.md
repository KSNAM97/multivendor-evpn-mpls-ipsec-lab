# 기본 설정 (장비 이름, 권한 모드, 세션)

**목적**: 장비 이름, 계정과 권한 모드, 세션 유지, 관리 인터페이스를 설정

**핵심**

- 호스트 이름은 GNS3 노드 이름과 같게 함
- `privilege 15` 계정은 로그인하면 바로 권한 모드
- 세션이 끊기지 않도록 `idle-timeout 0`을 둠(실습용).
- EOS는 name-server가 없으면 도메인 조회를 하지 않으므로 `no ip domain-lookup`에 해당하는 설정이 필요 없음
- EVPN을 쓰려면 `service routing protocols model multi-agent`가 필요하고, 설정 후 `write memory`와 `reload`를 해야 적용됨(적용 전에는 `address-family evpn`이 "multi-agent must be configured"로 거부되고 `show bgp evpn summary`가 "% Not supported"로 나옴).
- 첫 부팅에서 ZeroTouch(ZTP)가 동작 중이면 `zerotouch cancel`로 중단하고 `zerotouch disable`로 끔(자세한 방법은 [ZTP 끄기](02-ztp-disable.md)).

**확인 명령**: `show running-config section username`, `show management ssh`, `show version`

파일: `base.eos`

```text
! Arista EOS - 기본 설정 샘플 (leaf1 기준, 값은 예시)
! [먼저] 첫 부팅에서 ZeroTouch(ZTP)가 동작 중이면 hostname이 localhost로 남고 설정이 적용되지 않을 수 있다
!   exec 모드에서: zerotouch cancel (ZTP 중단, 재부팅) > 이후 zerotouch disable (영구 비활성화) > write memory
! 호스트 이름은 GNS3 노드 이름과 같게 한다: SPINE1, SPINE2, LEAF1 ~ LEAF4
! 확인: show running-config section username / show management ssh / show version
! 비밀번호, 해시는 문서에 적지 않고 자리표시자로 둔다
!
hostname LEAF1
!
! EVPN(BGP evpn)에 필요한 라우팅 모델. 설정 후 write memory, reload 를 해야 적용된다 (적용 전에는 address-family evpn 이 거부됨)
service routing protocols model multi-agent
!
! 계정과 권한 (privilege 15 = 권한 모드로 바로 진입)
username admin privilege 15 role network-admin secret <PASSWORD>
! enable 비밀번호가 필요하면 (선택): enable password <ENABLE-PASSWORD>
!
! 콘솔, SSH 세션이 끊기지 않게 (실습용)
management console
   idle-timeout 0
!
management ssh
   idle-timeout 0
   no shutdown
!
! 관리 인터페이스 (GNS3 어댑터 0번)
interface management1
   ip address 192.168.100.21/24
!
! 로그와 시간
logging buffered 64000
clock timezone Asia/Seoul
!
! 참고: EOS는 name-server를 지정하지 않으면 도메인 조회를 하지 않으므로
!       Cisco의 "no ip domain-lookup" 에 해당하는 설정이 따로 필요 없다
!
```
