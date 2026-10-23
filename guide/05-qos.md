# 5단계: QoS

## 목표

혼잡 상황에서 EF(음성)와 라우팅 제어 트래픽이 큐에서 보호되고, 혼잡 손실이 best-effort에만 몰림

## 켜는 노드

DC1(spine1, leaf1~leaf4), PE1, PE2, DC2(CX1, CX2, CX3), Host A, Host D. 시험 경로가 DC1 -> DC2라 **DC2를 켬**. Branch와 Hub는 터널 DSCP 보존을 확인할 때만 켬

## 순서

| 순서 | 할 일 | 참고 문서 |
|---|---|---|
| 1 | 정책 이해 | [기준: QoS](../baseline/core/08-qos.md) |
| 2 | c7200에 정책 적용 | [샘플: QoS](../samples/core/08-qos.md) |
| 3 | 호스트에서 트래픽 생성과 DSCP 마킹 | [iperf와 DSCP](../samples/host/03-iperf-dscp.md) |
| 4 | 3가지 상태 비교와 카운터 확인 | [검증: QoS](../verification/core/08-qos.md) |

## 완료 기준

- 입구 DSCP -> TC 매핑, 출구 우선 큐(EF 드롭 0), 혼잡 드롭이 best-effort에만 몰리는 것, 제어 트래픽 보호를 `show policy-map interface` 카운터와 캡처로 확인함(지연은 이 랩의 변동이 커서 판정에 쓰지 않음)
