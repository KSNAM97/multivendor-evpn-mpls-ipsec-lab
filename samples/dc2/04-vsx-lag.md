# VSX LAG

**목적**: access 스위치(CX3)를 VSX 쌍에 하나의 LAG로 연결

**핵심**

- VSX 쌍 쪽은 `interface lag 10 multi-chassis`, access 쪽은 일반 `interface lag 10`을 씀
- 링크 4개(쌍의 각 스위치에 2개씩)가 하나의 LAG로 묶임

- 호스트(Host D)에 연결된 access 포트에는 `spanning-tree port-type admin-edge`를 줌(Arista의 `portfast`에 해당하는 말단 포트 설정).
- **이미지 한계**: AOS-CX Virtual 10.07에서는 LACP 협상은 정상이지만 `lag10` 위로 VLAN 110 데이터가 전달되지 않음. Host D는 CX3가 아니라 **CX1 `1/1/7`**(VLAN 110 access)에 연결. 아래 CX3 `1/1/5` 설정은 이미지를 바꿨을 때 쓰는 원래 구성
- LACP는 기본(slow, 30초 간격)을 사용. `lacp rate fast`(1초 간격)를 줬을 때 에뮬레이션 부하로 LACP가 반복해서 흔들려(`X` 플래그, `lacp-block`, VSX Out-Of-Sync) ISL과 `lag 10`에서 모두 제거함.

**확인 명령**: `show lacp interfaces`, `show lacp aggregates`

파일: `vsx-lag.aos`

```text
! Aruba AOS-CX - VSX LAG 샘플 (access 스위치 CX3 연결, 값은 예시)
! 확인: show lacp interfaces / show lacp aggregates / show vsx status
!
! [CX1, CX2 공통] 멀티 섀시 LAG (양쪽에 같은 lag 번호)
vlan 110
    name APP-DC2
!
vlan 999
    name NATIVE
!
interface lag 10 multi-chassis
    no shutdown
    description to-CX3
    no routing
    vlan trunk native 999
    vlan trunk allowed 110
    lacp mode active
!
interface 1/1/5
    no shutdown
    lag 10
!
interface 1/1/6
    no shutdown
    lag 10
!
! [CX3 access] 일반 LAG (4링크: CX1 2개, CX2 2개)
interface lag 10
    no shutdown
    description to-VSX-pair
    no routing
    vlan trunk native 999
    vlan trunk allowed 110
    lacp mode active
!
interface 1/1/1
    no shutdown
    lag 10
!
interface 1/1/2
    no shutdown
    lag 10
!
interface 1/1/3
    no shutdown
    lag 10
!
interface 1/1/4
    no shutdown
    lag 10
!
interface 1/1/5
    no shutdown
    description to-HostD
    spanning-tree port-type admin-edge
    no routing
    vlan access 110
!
! [CX1] Host D 직접 연결 (CX3 경유가 이미지 한계로 안 될 때 사용, Host D의 eth1)
interface 1/1/7
    no shutdown
    description to-HostD-eth1
    no routing
    vlan access 110
!
```
