# QoS (DiffServ)

**목적**: 호스트가 마킹한 DSCP를 MPLS TC로 매핑하고 출구에서 큐잉과 shaping을 함

**핵심**

- 이 랩의 경로 용량이 약 1Mbit/sec라서 **400Kbit/sec shaping**으로 혼잡을 만들고, 혼잡 트래픽은 UDP 800Kbit/sec(데이터그램 1200바이트)로 보냄
- 시험 상태는 세 가지: 정책 없음, `SHAPE-ONLY`(shaping만), `SHAPE-400K`(shaping과 큐잉). 정책을 바꿀 때는 `no service-policy output` 후 새로 적용
- 혼잡 시험(상태 2)에서 PE1-PE2 BGP 세션이 끊긴 적이 있어 **제어 트래픽 클래스 `NETCTRL`(최소 5%)** 를 추가함. 우선 큐 20%, 30%, 20%와 합쳐 75%로 `max-reserved-bandwidth` 기본값(75%) 이내
- 분류는 c7200에서 하고, Arista vEOS는 ACL의 인터페이스 적용이 되지 않아 쓰지 않음
- 정책은 PE1에만 적용. 입구 `Gi2/0`, `Gi3/0`(leaf3, leaf4), 출구 `Gi0/0`(PE2 방향)

**확인 명령**: `show policy-map interface gigabitethernet 0/0`, `show class-map`

파일: `qos.ios`

```text
! Cisco IOS (c7200) - QoS(DiffServ) 샘플 (값은 예시)
! 대상: PE1. 입구 Gi2/0, Gi3/0(leaf3, leaf4), 출구 Gi0/0(PE2 방향)
! 확인: show policy-map interface gigabitethernet 0/0 / show class-map
! 호스트가 DSCP를 마킹하고, PE 입구에서 MPLS TC(EXP)로 매핑, 출구에서 큐잉과 shaping
!
class-map match-all VOICE
    match dscp ef
class-map match-all CRITICAL
    match dscp af31
class-map match-all BUSINESS
    match dscp af21
class-map match-all SCAVENGER
    match dscp cs1
!
! 입구: DSCP -> MPLS TC (기본 복사와 같은 값이지만 의도를 드러내려고 명시)
policy-map PE-IN
    class VOICE
        set mpls experimental imposition 5
    class CRITICAL
        set mpls experimental imposition 3
    class BUSINESS
        set mpls experimental imposition 2
    class SCAVENGER
        set mpls experimental imposition 1
!
! 출구: MPLS TC 기준 큐잉
class-map match-all VOICE-EXP
    match mpls experimental topmost 5
class-map match-all CRITICAL-EXP
    match mpls experimental topmost 3
class-map match-all BUSINESS-EXP
    match mpls experimental topmost 2
! 라우팅 제어 트래픽(BGP, OSPF, LDP는 CS6, TC 6)을 혼잡에서 보호
class-map match-any NETCTRL
    match mpls experimental topmost 6
    match dscp cs6
!
policy-map CORE-OUT
    class VOICE-EXP
        priority percent 20
    class NETCTRL
        bandwidth percent 5
    class CRITICAL-EXP
        bandwidth percent 30
    class BUSINESS-EXP
        bandwidth percent 20
    class class-default
        fair-queue
!
! 혼잡을 만들기 위한 shaping. 경로 용량이 약 1Mbit/sec라 400Kbit/sec로 제한
! 상태 2 (혼잡, 정책 없음): shaping만
policy-map SHAPE-ONLY
    class class-default
        shape average 400000
!
! 상태 3 (혼잡, 정책 적용): shaping 아래에 큐잉 정책
policy-map SHAPE-400K
    class class-default
        shape average 400000
        service-policy CORE-OUT
!
interface gigabitethernet 2/0
    service-policy input PE-IN
!
interface gigabitethernet 3/0
    service-policy input PE-IN
!
! 상태에 따라 하나만 적용 (정책을 바꿀 때는 먼저 no service-policy output)
interface gigabitethernet 0/0
    service-policy output SHAPE-400K
!
```
