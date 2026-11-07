# DC1 외부 연결: leaf - Hub - PE1 (eBGP)

border leaf(leaf3, leaf4)가 Hub 2대를 거쳐 MPLS 코어(PE1)에 연결되는 부분. leaf3·4는 PE1에 직접 연결하지 않음

기준 문서: [00-overview](../../00-overview/README.md)

## 링크

| 링크                      | 서브넷          | A측       | B측       | VRF                              | 방식   |
| ----------------------- | ------------ | -------- | -------- | -------------------------------- | ---- |
| PE1 Gi4/0 - Hub1 Gi0/0  | 10.0.30.0/31 | PE1 .0   | Hub1 .1  | PE1 쪽 TENANT-A (Hub는 VRF 없음)    | eBGP |
| PE1 Gi5/0 - Hub2 Gi0/0  | 10.0.30.2/31 | PE1 .2   | Hub2 .3  | PE1 쪽 TENANT-A (Hub는 VRF 없음)    | eBGP |
| leaf3 Et6 - Hub1 Gi1/0  | 10.0.31.0/31 | leaf3 .0 | Hub1 .1  | TENANT-A (leaf 쪽만, Hub는 VRF 없음)  | eBGP |
| leaf4 Et6 - Hub2 Gi1/0  | 10.0.31.2/31 | leaf4 .2 | Hub2 .3  | TENANT-A (leaf 쪽만, Hub는 VRF 없음)  | eBGP |
| leaf3 Et8 - Hub2 Gi2/0  | 10.0.32.0/31 | leaf3 .0 | Hub2 .1  | TENANT-A (leaf 쪽만, Hub는 VRF 없음)  | eBGP |
| leaf4 Et8 - Hub1 Gi2/0  | 10.0.32.2/31 | leaf4 .2 | Hub1 .3  | TENANT-A (leaf 쪽만, Hub는 VRF 없음)  | eBGP |

## eBGP

| 세션                             | 로컬 AS | 상대 AS | VRF      |
| ------------------------------ | ----- | ----- | -------- |
| leaf3, leaf4 - Hub1, Hub2 (leaf 쪽) | 65100 | 65010 | TENANT-A |
| Hub1, Hub2 - leaf3, leaf4 (Hub 쪽)  | 65010 | 65100 | 없음 (전역)  |
| Hub1, Hub2 - PE1 (Hub 쪽)          | 65010 | 65000 | 없음 (전역)  |
| PE1 - Hub1, Hub2 (PE 쪽)          | 65000 | 65010 | TENANT-A |

## 교차 연결하는 이유

- leaf3·4는 VTEP(10.1.1.34)을 공유해서 spine에서는 한 장비처럼 보이고, Hub 방향 트래픽이 leaf3 또는 leaf4 어느 쪽으로든 들어올 수 있음
- 한 leaf가 한 Hub에만 연결되어 있으면, Hub 한쪽 경로(예: PE1 - Hub1)가 끊길 때 그 Hub에 연결된 leaf로 들어온 트래픽이 갈 곳을 잃어 **블랙홀**이 됨
- 두 leaf가 Hub 2대에 모두 연결되면 한 Hub 경로가 끊겨도 반대쪽 Hub로 나갈 수 있음
- 측정: PE1 `Gi4/0`(Hub1 링크) 차단 시 손실 0, `Gi5/0`(Hub2 링크) 차단 시 약 8.4초 손실 후 자동 복구 ([검증](../../verification/dc1/04-dci-hub-ebgp.md))

## Hub 주소 정리

| 장비 | 인터페이스 | 주소 | 상대 |
| ---- | ---------- | ---- | ---- |
| Hub1 | `gigabitethernet 0/0` | 10.0.30.1/31 | PE1 `Gi4/0` |
| Hub1 | `gigabitethernet 1/0` | 10.0.31.1/31 | leaf3 `ethernet6` |
| Hub1 | `gigabitethernet 2/0` | 10.0.32.3/31 | leaf4 `ethernet8` |
| Hub2 | `gigabitethernet 0/0` | 10.0.30.3/31 | PE1 `Gi5/0` |
| Hub2 | `gigabitethernet 1/0` | 10.0.31.3/31 | leaf4 `ethernet6` |
| Hub2 | `gigabitethernet 2/0` | 10.0.32.1/31 | leaf3 `ethernet8` |
| Hub1, Hub2 | BGP router-id | 10.0.1.21, 10.0.1.22 | loopback0(10.0.0.21, 10.0.0.22)과 다른 대역 |

## 이중화

- leaf3·4가 Hub 2대에 모두 연결(교차 연결)되고, Hub 2대가 각각 PE1에 연결됨
- DC1 외부 출구는 Hub1과 Hub2 두 대

- BGP 타이머는 DC1 iBGP와 같은 **keepalive 3초, hold 9초**(`timers 3 9`)로 통일. leaf3·4와 Hub, PE1과 Hub 양쪽에 같은 값을 줌
