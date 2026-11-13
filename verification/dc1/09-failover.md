# 장애 시험 T1 ~ T4 (2026-11-14)

기준: 시험 전에 같은 ping이 0% 손실인지 확인하고, ping을 시작한 뒤 5초쯤 지나 인터페이스를 `shutdown`. 끝나면 `no shutdown`으로 복구하고 BGP·OSPF가 돌아온 것까지 확인. 응답 시간은 증빙에 쓰지 않음

## 결과

| 시험 | 단절 (ping 중) | 단절 중 상태 | 손실 | 복구 확인 |
|---|---|---|---|---|
| T1 Hub1 경로 | PE1 `Gi2/0` | Hub1 Idle, 경로는 Hub2(10.0.30.3) 하나, traceroute 4홉 10.0.30.2 -> 5홉 Hub2 -> 6홉 10.0.31.2(border leaf2) | `Host F: ping -c 300 -i 0.2 192.168.30.101` **손실 0**(재시험 300/300, 첫 시험 300/300) | Hub1 Established, 경로 multipath 복귀, traceroute 4홉이 10.0.30.0·.2 번갈아 |
| T1b Hub2 경로 | PE1 `Gi5/0` | Hub2 Idle, 경로는 Hub1(10.0.30.1) 하나, traceroute 4홉 10.0.30.0 -> 5홉 Hub1 -> 6홉 10.0.31.0(border leaf1) | 재시험 **손실 0**(300/300), 첫 시험은 300개 중 1개 | Hub2 Established, 두 경로 복귀 |
| T2 코어 링크 | PE2 `Gi1/0`(PE3 방향) | OSPF 이웃 PE1만, `10.0.0.13`이 PE1(10.0.10.0) 경유 metric 3, traceroute 7홉(PE1 경유), 단절 중 ping 120/120 0% | 복구(`no shutdown`) 중 `Host E: ping -c 120 -i 0.2 192.168.50.101` **손실 0** | PE2에 PE1·PE3 FULL, 10.0.0.13 next hop 10.0.10.5 metric 2, traceroute 6홉(PE3 직접) |
| T3 Leaf 업링크 | leaf1 `Et1`(spine1 방향) | leaf1 OSPF 이웃 spine2만, `10.1.1.34` next hop 10.1.10.8 하나(정상은 두 개), traceroute 3홉 | `Host A: ping -c 120 -i 0.2 192.168.30.101` 120개 중 **5개 손실**(4.17%, 약 1초) | spine1·spine2 FULL, next hop 두 개 복귀 |
| T4 호스트 포트 | leaf1 `Et5`(Host A) | Host A -> 192.168.30.101 **100% 손실**, Host B -> 같은 대역 0% 손실(leaf2 Et5) | 호스트가 단일 연결이라 Host A만 끊김 | `no shutdown` 뒤 Host A 4/4 0% |

- T1b의 이전 기록(47개 손실, 약 9.4초)은 단절 방식이 달라 값이 다름. 이번 시험은 인터페이스 `shutdown`으로 링크 다운이 바로 감지되어 손실이 거의 없었던 것으로 보이나 이 해석은 확인하지 못함
- T2는 코어 링크를 내려둔 상태가 길게 이어져 단절 직후 손실은 측정하지 못했고, 단절 중 통신 유지와 복구 중 손실 0을 기록

## 증빙

### T1 Hub1 단절 / 복구

![T1 PE1 BGP](images/09-fail-t1-t1b-t3-t4/t1-pe1-bgp-summary.png)

![T1 PE1 경로](images/09-fail-t1-t1b-t3-t4/t1-pe1-route-hub2-only.png)

![T1 traceroute](images/09-fail-t1-t1b-t3-t4/t1-host-f-trace.png)

![T1 ping](images/09-fail-t1-t1b-t3-t4/t1-rerun-ping-300.png)

![T1 복구](images/09-fail-t1-t1b-t3-t4/t1-recover-bgp.png)

### T1b Hub2 단절 / 복구

![T1b PE1 BGP](images/09-fail-t1-t1b-t3-t4/t1b-pe1-bgp-hub2-idle.png)

![T1b PE1 경로](images/09-fail-t1-t1b-t3-t4/t1b-pe1-route-hub1-only.png)

![T1b traceroute](images/09-fail-t1-t1b-t3-t4/t1b-trace-hub1.png)

![T1b ping](images/09-fail-t1-t1b-t3-t4/t1b-rerun-ping-300.png)

![T1b 복구](images/09-fail-t1-t1b-t3-t4/t1b-recover-bgp.png)

### T2 코어 링크

![PE2 OSPF](images/06-core-link-t2/pe2-ospf-pe1-only.png)

![PE2 Gi1/0 down](images/06-core-link-t2/pe2-gi1-0-admin-down.png)

![복구 중 ping](images/06-core-link-t2/host-e-ping-recover-120.png)

![복구 후 OSPF](images/06-core-link-t2/pe2-ospf-recovered.png)

### T3 Leaf 업링크, T4 호스트 포트

![T3 ping](images/09-fail-t1-t1b-t3-t4/t3-ping-120.png)

![T3 leaf1](images/09-fail-t1-t1b-t3-t4/t3-leaf1-ospf-route.png)

![T4 Host B](images/09-fail-t1-t1b-t3-t4/t4-host-b-ok.png)

![T4 Host A](images/09-fail-t1-t1b-t3-t4/t4-host-a-down.png)

![복구 leaf1](images/09-fail-t1-t1b-t3-t4/t3-t4-recover-leaf1.png)

## 결과 기록

| 일시 | 결과 | 비고 |
|---|---|---|
| 2026-11-14 | 성공 | T1~T4 완료. 단절 중 통신 유지와 복구 확인 |
