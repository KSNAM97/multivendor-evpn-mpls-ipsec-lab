# VSX active gateway

VSX 쌍이 같은 게이트웨이 주소를 active-active로 제공

기준 문서: [00-overview](../../00-overview/README.md)

## 설계값

| 항목                 | 값                                |
| ------------------ | -------------------------------- |
| VLAN               | 110                              |
| 서브넷                | 192.168.110.0/24                 |
| CX1 SVI            | 192.168.110.2/24                 |
| CX2 SVI            | 192.168.110.3/24                 |
| active gateway     | 192.168.110.1 (양쪽 같은 주소)         |
| active gateway MAC | 12:00:00:00:01:10 (양쪽 같은 값)      |
| VRF                | TENANT-A                         |
| 호스트                | Host E 192.168.110.101, 게이트웨이 .1 |

- CX1·CX2의 SVI vlan 110은 `ip mtu 1400`(양쪽 같은 값). MSS 클램핑 명령은 AOS-CX에서 확인하지 못함
