# VSX

두 스위치(CX1, CX2)를 하나의 논리 스위치처럼 묶음

기준 문서: [00-overview](../../00-overview/README.md)

## 설계값

| 항목 | CX1 | CX2 |
|---|---|---|
| 역할 | primary | secondary |
| ISL | lag 256 (1/1/2-3) | lag 256 (1/1/2-3) |
| keepalive 포트 | 1/1/4 (VRF KEEPALIVE) | 1/1/4 (VRF KEEPALIVE) |
| keepalive 주소 | 10.2.254.0/31 | 10.2.254.1/31 |
| system-mac | 02:00:00:00:01:01 | 02:00:00:00:01:01 |

- ISL은 링크 2개를 LACP로 묶고, keepalive는 ISL과 별도의 링크를 씀
- 두 스위치의 system-mac은 같아야 함
