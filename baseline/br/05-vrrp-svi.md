# SVI와 VRRP

Branch LAN의 기본 게이트웨이를 DSW 두 대로 이중화

기준 문서: [00-overview](../../00-overview/README.md)

| VLAN | 서브넷 | VRRP VIP | DSW1 | DSW2 | master | 호스트 |
|---|---|---|---|---|---|---|
| 50 | 192.168.50.0/24 | .1 | .2 (priority 110) | .3 (priority 100) | DSW1 | Host F .101 |
| 60 | 192.168.60.0/24 | .1 | .2 (priority 100) | .3 (priority 110) | DSW2 | Host G .101 |

- VRRP는 RFC 5798 표준이고 preempt를 켬.
- MSTP root와 VRRP master를 같은 DSW로 맞춰 경로가 꼬이지 않게 함
