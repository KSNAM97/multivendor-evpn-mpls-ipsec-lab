# OSPF

**목적**: 코어 링크와 루프백을 OSPF로 광고

**핵심**

- OSPF router-id는 `loopback 0` 주소(10.0.0.x)이고, BGP router-id(10.0.1.x)와 다른 값
- 빠른 수렴을 위해 코어 링크마다 `ip ospf hello-interval 1`, `ip ospf dead-interval 4`로 타이머를 줄임(양쪽 같은 값). 루프백은 passive
- `passive-interface`는 인터페이스 모드가 아니라 `router ospf` 아래에 입력
- `auto-summary`는 OSPF에 없는 명령이라 쓰지 않음
- VRF에 속한 링크(Gi2/0 ~ 5/0)는 OSPF에 넣지 않음

**확인 명령**: `show ip ospf neighbor`, `show ip ospf interface gigabitethernet 0/0`, `show ip route ospf`

파일: `ospf.ios`

```text
! Cisco IOS (c7200) - OSPF 샘플 (PE1 기준)
! 확인: show ip ospf neighbor / show ip ospf interface gigabitethernet 0/0 / show ip route ospf
! PE2, PE3는 router-id와 loopback IP만 바꾼다 (PE2 10.0.0.12, PE3 10.0.0.13)
!
router ospf 1
    router-id 10.0.0.11
    passive-interface loopback 0
!
interface loopback 0
    ip ospf 1 area 0
!
interface gigabitethernet 0/0
    ip ospf network point-to-point
    ip ospf hello-interval 1
    ip ospf dead-interval 4
    ip ospf 1 area 0
!
interface gigabitethernet 1/0
    ip ospf network point-to-point
    ip ospf hello-interval 1
    ip ospf dead-interval 4
    ip ospf 1 area 0
!
```
