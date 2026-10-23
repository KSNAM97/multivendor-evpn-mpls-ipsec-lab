# 터널 위 eBGP

Hub와 BGW가 GRE over IPsec 터널 위에서 eBGP로 DC1과 Branch 경로를 교환

기준 문서: [00-overview](../../00-overview/README.md)

선행 조건: [GRE over IPsec](09-ipsec-gre.md), [PE3 - BGW eBGP](07-wan-ebgp.md)

## 세션

| 세션 | 로컬 AS | 상대 AS | 이웃 주소 |
|---|---|---|---|
| Hub1 - BGW1 (Tunnel0) | 65010 | 65020 | Hub1 10.0.40.0, BGW1 10.0.40.1 |
| Hub2 - BGW2 (Tunnel1) | 65010 | 65020 | Hub2 10.0.40.2, BGW2 10.0.40.3 |

## 값

| 항목 | 값 |
|---|---|
| BGP router-id | Hub1 10.0.1.21, Hub2 10.0.1.22, BGW1 10.0.1.31, BGW2 10.0.1.32 (BGW의 OSPF router-id 10.0.0.31, 10.0.0.32와 다름) |
| 타이머 | keepalive 3초, hold 9초 (`timers 3 9`)로 DC1과 통일 |
| BGW 광고 | Branch LAN 192.168.50.0/24, 192.168.60.0/24 (`network` 문). DSW에서 OSPF로 받은 경로가 테이블에 있어야 함 |
| 터널 쪽 out 필터 | `prefix-list NO-UNDERLAY`로 `10.0.30.0/24`를 막음 (Hub, BGW 양쪽) |

- 두 터널로 ECMP 되고, 한 터널이 끊기면 다른 터널로 전환됨
- BGW는 PE3에서 언더레이 경로를 받으므로, 터널 위로 다시 내보내면 터널 목적지를 터널 안에서 배워 터널이 내려갈 수 있음(재귀 경로). 그래서 위 필터가 필요
- Hub가 leaf에서 받은 경로(DC1, DC2의 TENANT-A)는 같은 `router bgp 65010`에서 터널 이웃으로 그대로 전달됨
- 샘플: [터널 위 eBGP](../../samples/br/10-bgp-over-tunnel.md)
