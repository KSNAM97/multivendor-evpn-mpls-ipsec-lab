# PE와 eBGP

VSX 쌍(CX1, CX2)이 MPLS 코어의 PE2와 TENANT-A 경로를 교환

기준 문서: [00-overview](../../00-overview/README.md)

## 링크

| 링크 | 서브넷 | A측 | B측 | VRF |
|---|---|---|---|---|
| PE2 - CX1 | 10.0.20.4/31 | PE2 .4 | CX1 .5 | TENANT-A |
| PE2 - CX2 | 10.0.20.6/31 | PE2 .6 | CX2 .7 | TENANT-A |

## eBGP

| 항목              | 값                                                                |
| --------------- | ---------------------------------------------------------------- |
| CX1, CX2 AS     | 65201                                                            |
| PE2 AS          | 65000                                                            |
| VRF / RD        | TENANT-A / 65201:1                                               |
| BGP router-id   | CX1 10.2.2.1, CX2 10.2.2.2 (loopback0 주소 10.2.0.1, 10.2.0.2와 다름) |
| keepalive, hold | **3초, 9초** (DC1과 통일, 기본 60초, 180초)                               |
| 광고              | connected (VLAN 110 서브넷)                                         |
