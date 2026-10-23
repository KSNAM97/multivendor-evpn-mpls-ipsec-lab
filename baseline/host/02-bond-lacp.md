# LACP bond (Host A)

Host A는 MLAG 쌍(leaf1, leaf2)에 LACP로 이중 연결

샘플: [02-bond-lacp.md](../../samples/host/02-bond-lacp.md)

## 설계값

| 항목 | 값 |
|---|---|
| 호스트 어댑터 | 2개 (`eth0` -> leaf1 `ethernet5`, `eth1` -> leaf2 `ethernet5`) |
| bond | `bond0`, `mode 802.3ad`(LACP) |
| 옵션 | `miimon 100`, `lacp_rate fast`, `xmit_hash_policy layer3+4` |
| 주소 | 192.168.10.101/24 (`bond0`), 게이트웨이 192.168.10.1 |

## 스위치 쪽 짝

| 장비 | 인터페이스 | 설정 |
|---|---|---|
| leaf1, leaf2 | `ethernet5` | `channel-group 10 mode active` |
| leaf1, leaf2 | `port-channel10` | `switchport mode access`, `switchport access vlan 10`, `mlag 10` (양쪽 같은 번호) |

- 호스트는 두 어댑터를 한 장비의 포트채널처럼 보고, 스위치 쪽은 MLAG로 두 leaf가 하나처럼 응답
- `lacp_rate fast`로 LACP를 1초 간격으로 보내 장애 감지를 빠르게 함
- `layer3+4` 해시는 IP와 포트로 흐름을 나눠서 두 링크에 분산함(`iperf3 -P`로 여러 흐름을 만들어 확인).

## 확인

| 위치 | 명령 | 기대 |
|---|---|---|
| Host A | `cat /proc/net/bonding/bond0` | 두 slave의 Aggregator ID가 같고 LACP 협상됨 |
| leaf1 | `show mlag interfaces` | `port-channel10`이 **active-full** |
| leaf1 | `show port-channel dense` | `Po10`의 멤버가 `P`(bundled) |