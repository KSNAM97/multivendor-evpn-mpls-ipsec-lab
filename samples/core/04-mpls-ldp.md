# MPLS와 LDP

**목적**: 코어 링크에서 LDP로 레이블을 배포

**핵심**

- `mpls ldp router-id loopback 0 force`: LDP router-id를 loopback0 주소로 고정
- `mpls ip`는 코어 링크(Gi0/0, Gi1/0)에만 입력. 고객 쪽 링크에는 레이블을 보내지 않음
- LDP 이웃은 loopback0 주소끼리 TCP 646으로 세션을 맺으므로 OSPF가 먼저 FULL이어야 함
- 코어 링크 이웃 사이는 바깥 레이블을 바로 제거(`Pop Label`, PHP)
- 앞의 OSPF 블록(interface 모드)에 이어서 붙여 넣을 때는 사이에 `exit`를 한 줄 넣어 설정 모드를 빠져나와야 함. `exit` 없이 이어 붙이면 `mpls label protocol ldp`, `mpls ldp router-id ...`가 설정에 들어가지 않음 (c7200에서 확인, 설정 파일의 OSPF 블록 끝에 `exit`가 있는 이유)

**확인 명령**: `show mpls interfaces`, `show mpls ldp neighbor`, `show mpls ldp bindings`, `show mpls forwarding-table`

파일: `mpls-ldp.ios`

```text
! Cisco IOS (c7200) - MPLS와 LDP 샘플 (PE1 기준)
! 확인: show mpls interfaces / show mpls ldp neighbor / show mpls forwarding-table
! PE2, PE3는 loopback IP만 다르고 명령은 같다
! OSPF로 loopback 0 경로가 보인 뒤에 입력한다
! 앞 OSPF 블록(interface 모드)에 이어 붙일 때는 아래 exit가 필요하다 (없으면 mpls 명령이 들어가지 않는다)
!
exit
!
mpls label protocol ldp
mpls ldp router-id loopback 0 force
!
! 코어 링크에만 mpls ip (VRF 링크와 loopback에는 넣지 않는다)
interface gigabitethernet 0/0
    mpls ip
!
interface gigabitethernet 1/0
    mpls ip
!
```
