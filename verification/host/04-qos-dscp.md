# QoS 트래픽과 DSCP 검증

**선행 조건**: 코어(PE1)에 QoS 정책이 적용되어 있고 호스트 사이 도달성(연결 확인 시나리오 4번)이 끝나 있어야 함

기준 문서: [03-qos-traffic.md](../../baseline/host/03-qos-traffic.md) / 샘플: [03-iperf-dscp.md](../../samples/host/03-iperf-dscp.md)

## 확인 항목

| 순서 | 위치 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | 수신 호스트 | `iperf3 -s` | 서버 대기 | iperf3 설치 |
| 2 | 송신 호스트 | `iperf3 -c 192.168.110.101 -u -b 200k -l 1200 --dscp 26 -t 30` | UDP 전송 완료, 손실 낮음(TCP는 이 랩에서 끊겨 쓰지 않음) | 도달성, 데이터그램 크기 |
| 3 | 코어 PE1 | `show policy-map interface gigabitethernet 0/0` | 클래스별 패킷 카운터가 오름(CRITICAL-EXP 등) | class-map, policy-map 적용 방향 |
| 4 | 송신 호스트 | `ping -Q 184 -c 100 -i 0.2 192.168.110.101` | EF 트래픽의 지연과 손실이 혼잡에서도 낮음 | priority 큐, shaping |
| 5 | 송신 호스트 | UDP 800Kbps(`-b 800k -l 1200`) 혼잡을 걸고 4번 반복 | 혼잡이 있어도 EF 지연이 유지됨 | 400Kbps shaping |
| 6 | 와이어샤크 (코어 링크) | `ip.dsfield.dscp == 46`, `mpls.exp == 5` | DSCP 46이 MPLS TC 5로 매핑됨 | 입구 정책의 `set mpls experimental` |

## 결과 기록

| 일시 | 결과 (성공, 실패) | 비고 |
|---|---|---|
| 2026-10-23 | 성공 (확인 항목 기준) | Host A -> Host D로 UDP 혼잡과 EF 프로브를 보내 PE1 카운터와 캡처로 확인. 상세는 [QoS 검증](../core/08-qos.md) |