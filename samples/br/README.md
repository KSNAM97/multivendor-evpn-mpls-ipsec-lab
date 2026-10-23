# Branch (Cisco IOS) 샘플 컨피그

번호는 구축 순서이고, 같은 번호는 baseline, verification에서도 같은 항목임. 프로토콜별로 문서를 나눴음. 같은 이름의 샘플 파일(원본, `.ios`)은 장비에 붙여 넣기 쉽게 그대로 두었음. 장비에서 검증한 컨피그가 아니라 문법 참고용 샘플

| 번호 | 항목 | 문서 |
|---|---|---|
| 01 | 기본 설정 | [기본 설정](01-base.md): BGW, DSW, ASW의 장비 이름, 권한 모드, domain-lookup, 세션 |
| 02 | VLAN과 IP | 별도 샘플 없음. VLAN은 [MSTP + EtherChannel](04-mstp-etherchannel.md), SVI는 [SVI + VRRP](05-vrrp-svi.md)에 포함 |
| 03 | 관리망 | [관리망 연결과 SSH 제한](03-mgmt-access.md): DSW는 VRF MGMT, ASW1은 VLAN 100 SVI |
| 04 | MSTP + EtherChannel | [MSTP + EtherChannel](04-mstp-etherchannel.md): DSW 쌍과 ASW 사이를 EtherChannel로 이중화하고 MSTP로 root 분담 |
| 05 | SVI + VRRP | [SVI + VRRP](05-vrrp-svi.md): Branch LAN의 기본 게이트웨이를 DSW 두 대로 이중화 |
| 06 | Branch OSPF | [Branch OSPF](06-ospf-branch.md): BGW와 DSW 사이를 OSPF area 0으로 연결 |
| 07 | PE3 - BGW eBGP (WAN-UL) | [PE3 - BGW eBGP](07-wan-ebgp.md): BGW의 PE3 이웃과 OSPF default 광고. PE3 쪽은 [코어 PE-CE 샘플](../core/07-pe-ce-ebgp.md) |
| 08 | IPsec 키 | 샘플 없음 ([키 관리 기준](../../baseline/br/08-ipsec-keys.md)) |
| 09 | GRE over IPsec (IKEv1) | [GRE over IPsec](09-ipsec-gre.md): Hub와 BGW 사이에 GRE 터널을 만들고 IPsec으로 보호 |
| 10 | 터널 위 eBGP | [터널 위 eBGP](10-bgp-over-tunnel.md): Hub와 BGW의 터널 이웃, Branch LAN 광고, 재귀 경로 방지 필터 |
| 13 | 비밀번호 지정 위치 | [비밀번호 지정 위치](13-password.md): enable, 계정, VRRP, OSPF, BGP, IPsec 사전 공유 키를 넣는 위치 |
