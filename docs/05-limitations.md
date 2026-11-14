# 한계와 향후 과제

## 확인된 한계

| 항목 | 내용 | 개선안 |
|---|---|---|
| 링크 장애 감지 시간 | 가상 라우터(Dynamips)는 링크가 끊겨도 상대가 바로 인식하지 못해 BGP hold 90초가 감지 기준이 됨. T1b 손실 47개(약 9.4초 환산, 이전 타이머 기준 측정). OSPF Hello 3초·Dead 9초는 감지 시간이고, SPF 지연 기본값(초기 5초, 최소 간격 10초)이 재계산에 더해져 T2 손실이 3회에 70~236개(약 14~47초 이상)로 크게 달랐음. 운영 중 Hello·Dead(Keepalive·Hold)가 불안정해 이웃이 반복해서 끊기면 값을 늘려 조정 | BFD 적용(이미지 지원 확인 필요), 실장비에서 재측정 |
| BGW 장애 시 Branch 이중화 | 이전 구성에서 BGW1 WAN을 끊었을 때 DSW1의 default가 BGW1에 고정(`default-information originate always`)되어 Host F → Host A 손실 75.5%. 최종 구성(VRF BR1)에서 재시험하지 않음 | default를 조건부로 바꾸고 DSW1·2가 SVI에서 OSPF 인접을 맺어 다른 DSW로 default를 넘김 |
| DC1과 DC2 분리 | 물리 분리가 아니라 VRF, RT, BGW prefix-list로 하는 논리적 분리. BGW 설정 실수 시 BR1을 거쳐 경로가 새어 나갈 수 있음 | PE3에서 BR1 export 경로를 prefix-list로 한 번 더 제한 |
| TCP 처리량 | 에뮬레이션 환경에서 TCP가 끊겨 처리량 시험을 쓰지 못함 | ping과 UDP로 검증(적용 중). 실장비나 더 높은 사양에서 재측정 |
| Aruba LAG 데이터 경로 | 가상 이미지(10.07)에서 LAG 위 VLAN 데이터가 전달되지 않음 | 다른 이미지 버전에서 재시험 |

## 하지 않은 시험

- DC1 spine, leaf 정지 시험, Branch VRRP 장애 시험(0.81초 측정 결과는 있음), Hub1 정지 시험
- 최종 구성 화면 증빙: PE-CE 요약, VRF 상세, Hub 이웃, T1·T1b·T2 ping 통계와 로그
- 이전 단계 일부 결과 행의 보강(초기 부분 성공 항목)

## 개선 후 재시험 계획

1. DSW SVI OSPF 인접과 조건부 default를 적용한 뒤 `ping -D`로 시각을 기록하며 BGW1 단절 시험을 반복
2. 최종 구성의 화면 증빙을 추가하고 T1, T1b, T2를 같은 방식으로 재현
3. 결과는 [DC1 Hub 검증](../verification/dc1/04-dci-hub-ebgp.md)의 장애 시험 표에 같은 형식으로 추가
