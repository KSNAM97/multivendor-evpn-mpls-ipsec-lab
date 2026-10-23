# VSX LAG

access 스위치(CX3)를 VSX 쌍에 하나의 LAG로 연결

기준 문서: [00-overview](../../00-overview/README.md)

## 연결

| 스위치 | 포트 | LAG | 상대 포트 |
|---|---|---|---|
| CX1 | 1/1/5-6 | lag 10 (multi-chassis) | CX3 1/1/1-2 |
| CX2 | 1/1/5-6 | lag 10 (multi-chassis) | CX3 1/1/3-4 |
| CX3 | 1/1/1-4 | lag 10 | CX1, CX2 |

| 항목 | 값 |
|---|---|
| LACP 모드 | active (양쪽) |
| 허용 VLAN | 110 |
| 호스트 포트 | CX1 1/1/7 (VLAN 110 access, Host D `eth1`). CX3 1/1/5는 미사용 |

- CX3의 4개 링크가 하나의 LAG로 묶이고, 쌍의 각 스위치에 2개씩 연결됨
- **이미지 한계**: LACP 협상(`ALFNCD`, up)과 LAG 상태는 정상이지만, 이 이미지(AOS-CX Virtual 10.07)에서는 `lag10`을 통과하는 VLAN 110 데이터 프레임이 전달되지 않음. 같은 링크를 LAG 없이 일반 트렁크로 쓰면 정상. 그래서 Host D는 CX3가 아니라 CX1 `1/1/7`에 직접 연결 ([상세](../../verification/dc2/05-active-gateway.md))

- LACP는 기본(slow, 30초 간격) 사용. 에뮬레이션에서 `lacp rate fast`가 LACP를 반복해서 흔들어 ISL(`lag 256`)과 `lag 10` 모두 제거. VSX 쌍(CX1·2)과 CX3 양쪽 같은 값
