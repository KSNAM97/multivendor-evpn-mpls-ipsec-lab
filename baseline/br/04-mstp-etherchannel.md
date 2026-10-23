# MSTP와 EtherChannel

DSW 쌍과 ASW1 사이를 EtherChannel로 이중화하고 MSTP로 VLAN별 경로를 나눔

기준 문서: [00-overview](../../00-overview/README.md)

## MSTP

| 항목 | 값 |
|---|---|
| region | LAB |
| revision | 1 |
| 인스턴스 1 | VLAN 50, root DSW1 (priority 4096) |
| 인스턴스 2 | VLAN 60, root DSW2 (priority 4096) |

## EtherChannel

| 번들 | 양 끝 | 포트 | 모드 |
|---|---|---|---|
| Po1 | DSW1 - DSW2 | Gi0/1-2 (양쪽) | LACP active |
| Po2 | DSW1 - ASW1 | DSW1 Gi0/3, Gi1/0 / ASW1 Gi0/0-1 | LACP active |
| Po3 | DSW2 - ASW1 | DSW2 Gi0/3, Gi1/0 / ASW1 Gi0/2-3 | LACP active |

- IOSv에는 MLAG가 없어서 ASW1의 두 번들 중 하나는 인스턴스별로 blocking됨. 이것이 VLAN 단위 부하 분산
- 호스트 포트: ASW1 Gi1/0 = VLAN 50 (Host F), Gi1/1 = VLAN 60 (Host G).

- LACP는 **기본(30초 간격)**을 씀. DC1은 fast(1초)이지만 IOSvL3 이미지는 `lacp rate fast`를 받지 않음(`% Invalid input`, 장비에서 확인)
- 멤버 포트에도 port-channel과 같은 trunk 설정(encapsulation dot1q, native 999, allowed 50,60)을 넣어야 번들됨. 멤버가 auto encapsulation이면 `%EC-5-CANNOT_BUNDLE2`로 suspended
