# Branch 검증

번호는 구축 순서이고, 같은 번호는 baseline, samples에서도 같은 항목임. 순서대로 진행

키 관련 문제: [IPsec 키 관리](../../baseline/br/08-ipsec-keys.md)

| 번호 | 항목 | 문서 |
|---|---|---|
| 04 | MSTP와 EtherChannel | [MSTP와 EtherChannel](04-mstp-etherchannel.md) |
| 05 | SVI와 VRRP | [SVI와 VRRP](05-vrrp-svi.md) |
| 06 | Branch OSPF | [Branch OSPF](06-ospf-branch.md) |
| 07 | PE3 - BGW eBGP (WAN-UL) | [PE3 - BGW eBGP](07-wan-ebgp.md). PE3 쪽은 [코어 PE-CE 검증](../core/07-pe-ce-ebgp.md) 항목 6~11 |
| 09 | GRE over IPsec: IKE SA, IPsec SA, GRE 터널 | [GRE over IPsec](09-ipsec-gre.md) |
| 10 | 터널 위 eBGP | [터널 위 eBGP](10-bgp-over-tunnel.md) |
| 11 | MTU와 MSS | [MTU와 MSS](11-mtu-mss.md) |
| 12 | IPsec 이중화 장애 시험 | [IPsec 이중화 장애 시험](12-ipsec-failover.md) |

- 01~03(기본 설정, VLAN과 IP, 관리망)과 08(키)은 별도 검증 문서가 없음. ASW1 관리 SVI 확인은 [MSTP와 EtherChannel 검증](04-mstp-etherchannel.md)에 포함
