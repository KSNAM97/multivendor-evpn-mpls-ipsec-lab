# MLAG

두 leaf를 하나의 논리 스위치처럼 묶음. MLAG는 벤더 독자 방식이라 Arista끼리만 묶임

기준 문서: [00-overview](../../00-overview/README.md)

## MLAG 쌍

| 항목              | leaf1 / leaf2 (서버 leaf)     | leaf3 / leaf4 (border leaf) |
| --------------- | --------------------------- | --------------------------- |
| domain-id       | MLAG1                       | MLAG2                       |
| peer-link       | Port-Channel1 (Et3-4)       | Port-Channel1 (Et3-4)       |
| 제어 VLAN         | 4094 (trunk group MLAGPEER) | 4094 (trunk group MLAGPEER) |
| local / peer 주소 | 10.1.254.0 / 10.1.254.1     | 10.1.254.2 / 10.1.254.3     |

- leaf1 = .0, leaf2 = .1, leaf3 = .2, leaf4 = .3 (Vlan4094)
- 스패닝트리 모드는 `mstp`이고 VLAN 4094는 스패닝트리에서 제외

## 호스트 연결 MLAG

| 호스트    | 포트                   | 포트채널           | mlag 번호 | VLAN |
| ------ | -------------------- | -------------- | ------- | ---- |
| Host A | leaf1 Et5, leaf2 Et5 | Port-Channel10 | 10      | 10   |

- 양쪽 leaf에 같은 `mlag` 번호를 설정하고, 호스트는 LACP(802.3ad)로 연결
