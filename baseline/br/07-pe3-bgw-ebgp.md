# PE3 - BGW eBGP (VRF BR1)

BGW가 고객사 망 끝단(CE)으로서 PE3의 VRF BR1과 eBGP로 경로를 교환하는 부분. PE3 쪽 설정은 [코어 PE-CE 기준](../core/07-pe-ce-ebgp.md)

기준 문서: [00-overview](../../00-overview/README.md)

선행 조건: [Branch OSPF](06-ospf-branch.md)

## 세션

PE3와 BGW 사이는 물리 포트 하나에 dot1q 100 서브인터페이스(`.100`)를 만들어 쓰고, PE3 쪽 서브인터페이스는 VRF BR1에 넣음

| 장비 | 링크 | BGW 주소 | PE3 주소 | 로컬 AS | 상대 AS |
|---|---|---|---|---|---|
| BGW1 | PE3 `Gi2/0.100` | 10.0.60.1/31 (`Gi0/0.100`) | 10.0.60.0 | 65020 | 65000 |
| BGW2 | PE3 `Gi3/0.100` | 10.0.60.3/31 (`Gi0/0.100`) | 10.0.60.2 | 65020 | 65000 |

| 항목 | 값 |
|---|---|
| BGP router-id | BGW1 10.0.1.31, BGW2 10.0.1.32 (OSPF router-id인 loopback0 주소 10.0.0.31, 10.0.0.32와 다름) |
| 타이머 | keepalive 3초, hold 9초 (`timers 3 9`). PE3와 양쪽 같은 값 |
| BGW가 PE3에 광고 | **자기 대역만**: 192.168.50.0/24, 192.168.60.0/24 (`network` 문). `prefix-list BR-TO-PARTNER out`으로 이 두 개만 허용 |
| BGW가 PE3에서 받음 | DC1(192.168.10.0/24, 192.168.20.0/24, 192.168.30.0/24, 192.168.99.0/24)과 DC2(192.168.110.0/24) 대역. `prefix-list PARTNER-TO-BR in`으로 이 다섯 개만 허용 |

## DC1과 DC2를 분리하는 방법

- BR1 VRF는 DC1(65000:1)과 DC2(65000:2)를 모두 import해서 Branch가 양쪽과 통신
- DC1과 DC2는 서로의 RT를 import하지 않아 VRF 단계에서 경로가 섞이지 않음
- BGW가 자기 대역만 PE3에 내보내므로, BR1을 거쳐 DC1과 DC2가 서로 통신하는 경로도 생기지 않음

## Branch 안으로 default 내리기

- DC1, DC2 경로는 BGP로 BGW까지만 오고 OSPF로는 내려가지 않음. Host F, G가 DC로 가려면 DSW에 default가 있어야 해서 BGW의 OSPF에 `default-information originate always`를 둠
- 샘플: [BGW OSPF와 BGP](../../samples/br/07-pe3-bgw-ebgp.md)

## 참고

- BGW의 `Gi0/0`(PE3 방향) 물리 인터페이스는 IP 없이 `no shutdown`만 하고, `.100` 서브인터페이스에 주소를 줌. OSPF에는 넣지 않음 ([Branch OSPF](06-ospf-branch.md))
