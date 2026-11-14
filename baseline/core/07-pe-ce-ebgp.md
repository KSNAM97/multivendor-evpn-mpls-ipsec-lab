# PE-CE eBGP

PE가 DC와 Branch 쪽 장비와 경로를 교환하는 부분. 모든 구역이 같은 방식(PE-CE eBGP)

기준 문서: [00-overview](../../00-overview/README.md)

선행 조건: [VRF](05-vrf.md), [MP-BGP VPNv4](06-mp-bgp-vpnv4.md)

## PE-CE 접속

| PE  | 상대   | 상대 AS | 링크                                     | VRF      |
| --- | ---- | ----- | -------------------------------------- | -------- |
| PE1 | Hub1 | 65010 | 10.0.30.0/31 (PE1 .0, Hub1 .1)         | TENANT-A |
| PE1 | Hub2 | 65010 | 10.0.30.2/31 (PE1 .2, Hub2 .3)         | TENANT-A |
| PE2 | CX1  | 65201 | 10.0.20.4/31 (PE2 .4, CX1 .5)          | PARTNER  |
| PE2 | CX2  | 65201 | 10.0.20.6/31 (PE2 .6, CX2 .7)          | PARTNER  |
| PE3 | BGW1 | 65020 | 10.0.60.0/31 (PE3 .0, BGW1 .1, `.100`) | BR1      |
| PE3 | BGW2 | 65020 | 10.0.60.2/31 (PE3 .2, BGW2 .3, `.100`) | BR1      |

- DC1은 border-leaf1이 Hub1, border-leaf2가 Hub2에 각각 연결되어 있고(1대1), Hub가 PE1과 eBGP를 맺음. border leaf와 Hub 사이도 eBGP ([DC1 Hub eBGP](../dc1/06-dci-hub-ebgp.md))
- Branch는 BGW가 고객사 망 끝단(CE)이고, PE3와 BGW 사이는 물리 포트 하나에 dot1q 100 서브인터페이스를 만들어 VRF BR1에 넣음
- PE1은 Hub 2대, PE2는 CX 2대, PE3는 BGW 2대와 각각 `maximum-paths 2`로 ECMP

### 경로 흐름

| 구간 | 동작 |
|---|---|
| DC1 -> 코어 | border leaf가 TENANT-A 경로(192.168.10.0/24, 192.168.20.0/24 등)를 Hub에 광고하고, Hub가 PE1에 전달. PE1이 VPNv4(RT 65000:1)로 PE2, PE3에 실음 |
| DC2 -> 코어 | CX1·2가 192.168.110.0/24를 PE2에 광고. PE2가 VPNv4(RT 65000:2)로 실음 |
| Branch -> 코어 | BGW가 192.168.50.0/24, 192.168.60.0/24만 PE3에 광고. PE3가 VPNv4(RT 65000:3)로 실음 |
| 코어 -> Branch | PE3 VRF BR1이 RT 65000:1, 65000:2를 import해서 DC1과 DC2 경로를 BGW에 전달. BGW는 `prefix-list PARTNER-TO-BR in`으로 192.168.10.0/24, 192.168.20.0/24, 192.168.110.0/24만 받음 |
| 코어 -> DC1, DC2 | PE1 VRF TENANT-A와 PE2 VRF PARTNER가 RT 65000:3(BR1)을 import해서 Branch 경로를 받음. DC1과 DC2는 서로 import하지 않음 |

### 주의

- BGW가 자기 대역만 광고하므로 BR1을 거쳐 DC1과 DC2가 서로 통신하는 경로(transit)가 생기지 않음
- CX 쪽 VRF 이름은 장비 로컬 이름이라 `TENANT-A`로 남아 있어도 PE2의 `PARTNER`와 달라도 동작에 영향 없음
- BGP 타이머는 DC1과 같은 **keepalive 30초, hold 90초**(`timers 30 90`)로 통일함(기본 60초, 180초). PE와 CE 양쪽에 같은 값을 줌
