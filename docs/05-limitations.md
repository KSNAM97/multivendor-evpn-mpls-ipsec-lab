# 한계와 향후 과제

## 확인된 한계

| 항목 | 내용 | 개선안 |
|---|---|---|
| BGW 장애 시 Branch 이중화 | BGW1 WAN을 끊어도 DSW1의 default가 BGW1에 고정(`default-information originate always`). Host F → Host A 손실 75.5%, 오류 547건 | default를 조건부로 바꾸고 DSW1·2가 SVI에서 OSPF 인접을 맺어 다른 DSW로 default를 넘김 |
| leaf3·4 Hub 이중화 | leaf3·4가 VTEP 10.1.1.34를 공유해 leaf3이 Hub1을 잃으면 leaf4로 경로를 넘기지 못함. 일부 흐름만 끊김 | VRF TENANT-A에서 leaf3·4를 iBGP로 연결 |
| TCP 처리량 | 에뮬레이션 환경에서 TCP가 끊겨 처리량 시험을 쓰지 못함 | ping과 UDP로 검증(적용 중). 실장비나 더 높은 사양에서 재측정 |
| QoS 범위 | PE1 한 방향(Host A → Host D)만 구현 | PE2, PE3, 반대 방향, Hub와 BGW 입구로 확장 |
| EF 지연 비교 | 같은 상태에서도 회차마다 평균이 달라(156 ms, 305 ms) 지연으로는 판정 불가 | 반복 측정 또는 부하가 낮은 환경에서 재측정 |
| Aruba LAG 데이터 경로 | 가상 이미지(10.07)에서 LAG 위 VLAN 데이터가 전달되지 않음 | 다른 이미지 버전에서 재시험 |

## 하지 않은 시험

- DC1 spine, leaf 정지 시험, Branch VRRP 장애 시험, Hub1 정지 시험
- 터널 구간 DSCP 보존 캡처(Host F → 터널 → PE1의 바깥 ESP 패킷)
- 이전 단계 일부 결과 행의 보강(초기 부분 성공 항목)

## 개선 후 재시험 계획

1. DSW SVI OSPF 인접과 조건부 default를 적용한 뒤 `ping -D`로 시각을 기록하며 BGW1 WAN 단절 시험을 반복
2. leaf3·4 iBGP를 적용한 뒤 Hub1 단절 시험에서 일부 흐름이 끊기는 현상이 사라지는지 확인
3. 결과는 [장애 시험 문서](../verification/br/12-ipsec-failover.md)에 같은 형식으로 추가
