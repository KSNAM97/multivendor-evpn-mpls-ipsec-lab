# DCI와 Hub 연동 (eBGP)

border leaf(leaf3, leaf4)가 MPLS 코어(PE1)와 WAN 출구(Hub)에 연결되는 부분

기준 문서: [00-overview](../../00-overview/README.md)

## 링크

| 링크                  | 서브넷          | A측       | B측       | VRF                             | 방식   |
| ------------------- | ------------ | -------- | -------- | ------------------------------- | ---- |
| PE1 - leaf3 (DCI)   | 10.0.20.0/31 | PE1 .0   | leaf3 .1 | TENANT-A                        | eBGP |
| PE1 - leaf4 (DCI)   | 10.0.20.2/31 | PE1 .2   | leaf4 .3 | TENANT-A                        | eBGP |
| leaf3 - Hub1        | 10.0.31.0/31 | leaf3 .0 | Hub1 .1  | TENANT-A (leaf 쪽만, Hub는 VRF 없음) | eBGP |
| leaf4 - Hub2        | 10.0.31.2/31 | leaf4 .2 | Hub2 .3  | TENANT-A (leaf 쪽만, Hub는 VRF 없음) | eBGP |
| PE1 - Hub1 (WAN-UL) | 10.0.30.0/31 | PE1 .0   | Hub1 .1  | WAN-UL                          | 정적   |
| PE1 - Hub2 (WAN-UL) | 10.0.30.2/31 | PE1 .2   | Hub2 .3  | WAN-UL                          | 정적   |

## eBGP

| 세션                         | 로컬 AS | 상대 AS | VRF      |
| -------------------------- | ----- | ----- | -------- |
| leaf3, leaf4 - PE1         | 65100 | 65000 | TENANT-A |
| leaf3 - Hub1, leaf4 - Hub2 (leaf 쪽) | 65100 | 65010 | TENANT-A |
| Hub1 - leaf3, Hub2 - leaf4 (Hub 쪽) | 65010 | 65100 | 없음 (전역) |

## WAN-UL (PE1 - Hub)은 정적

- PE1과 Hub 사이에는 BGP 이웃을 두지 않음. PE1은 VRF WAN-UL에서 `redistribute connected`로 직결 링크만 VPNv4에 실음
- Hub는 BGW 터널 주소로 가는 정적 경로만 가짐. Hub1은 `10.0.30.5/32`를 next-hop `10.0.30.0`으로, Hub2는 `10.0.30.7/32`를 next-hop `10.0.30.2`로
- 이유와 PE3 - BGW(eBGP)와의 구역별 구분은 [코어 PE-CE 기준](../core/07-pe-ce-ebgp.md)

## Hub 주소 정리

| 장비 | 인터페이스 | 주소 | 상대 |
| ---- | ---------- | ---- | ---- |
| Hub1 | `gigabitethernet 0/0` | 10.0.30.1/31 | PE1 `Gi4/0` |
| Hub1 | `gigabitethernet 1/0` | 10.0.31.1/31 | leaf3 `ethernet6` |
| Hub2 | `gigabitethernet 0/0` | 10.0.30.3/31 | PE1 `Gi5/0` |
| Hub2 | `gigabitethernet 1/0` | 10.0.31.3/31 | leaf4 `ethernet6` |
| Hub1, Hub2 | BGP router-id | 10.0.1.21, 10.0.1.22 | loopback0(10.0.0.21, 10.0.0.22)과 다른 대역 |

## 이중화

- PE1로 두 링크(leaf3, leaf4)와 Hub가 이중으로 연결됨
- WAN 출구는 Hub1과 Hub2 두 대

- BGP 타이머는 DC1 iBGP와 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일. leaf3·4와 PE1, Hub 양쪽에 같은 값을 줌
