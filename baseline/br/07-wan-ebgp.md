# PE3 - BGW eBGP (WAN-UL)

BGW가 WAN 언더레이(VRF WAN-UL)에서 PE3와 경로를 교환하는 부분. PE3 쪽 설정과 구역별 방식(PE1 - Hub는 정적, PE3 - BGW는 eBGP)은 [코어 PE-CE 기준](../core/07-pe-ce-ebgp.md)

기준 문서: [00-overview](../../00-overview/README.md)

선행 조건: [Branch OSPF](06-ospf-branch.md)

## 세션

| 장비 | 링크 | BGW 주소 | PE3 주소 | 로컬 AS | 상대 AS |
|---|---|---|---|---|---|
| BGW1 | PE3 `Gi2/0` | 10.0.30.5/31 (`Gi0/0`) | 10.0.30.4 | 65020 | 65000 |
| BGW2 | PE3 `Gi3/0` | 10.0.30.7/31 (`Gi0/0`) | 10.0.30.6 | 65020 | 65000 |

| 항목 | 값 |
|---|---|
| BGP router-id | BGW1 10.0.1.31, BGW2 10.0.1.32 (OSPF router-id인 loopback0 주소 10.0.0.31, 10.0.0.32와 다름) |
| 타이머 | keepalive 3초, hold 9초 (`timers 3 9`). PE3와 양쪽 같은 값 |
| BGW가 PE3에 광고 | **없음**. Branch LAN을 WAN-UL VRF로 흘리지 않도록 PE3 방향 out을 `prefix-list NONE`으로 막음. BGW 링크 주소(10.0.30.4/31, .6/31)는 PE3가 `redistribute connected`로 이미 VPNv4에 실음 |
| BGW가 PE3에서 받음 | PE1 쪽 언더레이 10.0.30.0/31, 10.0.30.2/31 (Hub 터널 주소 10.0.30.1, 10.0.30.3에 도달하기 위해) |

## Branch 안으로 default 내리기

- DC1, DC2 경로는 터널 위 eBGP로 BGW까지만 오고 OSPF로는 내려가지 않음. Host F, G가 DC로 가려면 DSW에 default가 있어야 해서 BGW의 OSPF에 `default-information originate always`를 둠
- 샘플: [BGW OSPF와 BGP](../../samples/br/07-wan-ebgp.md)

## 참고

- BGW의 `Gi0/0`(PE3 방향)은 OSPF에 넣지 않음 ([Branch OSPF](06-ospf-branch.md))
- Hub와의 터널 위 eBGP, Branch LAN 광고(`network`)는 [터널 위 eBGP](10-bgp-over-tunnel.md)
