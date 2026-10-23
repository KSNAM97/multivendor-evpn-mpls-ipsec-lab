# MPLS 코어 (Cisco IOS) 샘플 컨피그

구축 순서와 번호가 같음. 같은 이름의 샘플 파일(원본, `.ios`)은 장비에 붙여 넣기 쉽게 그대로 둠. 장비에서 검증한 컨피그가 아니라 문법 참고용 샘플

| 번호 | 문서 | 내용 | 파일 |
|---|---|---|---|
| 01 | [기본 설정](01-base.md) | 장비 이름, 권한 모드, domain-lookup, 세션, 배너 | `base.ios` |
| 02 | [인터페이스 IP](02-ip.md) | loopback0, 링크 IP, VRF 소속 | `ip.ios` |
| 03 | [OSPF](03-ospf.md) | 코어 링크와 루프백 광고, 타이머 | `ospf.ios` |
| 04 | [MPLS와 LDP](04-mpls-ldp.md) | LDP 레이블 배포 | `mpls-ldp.ios` |
| 05 | [VRF](05-vrf.md) | RD, route-target | `vrf.ios` |
| 06 | [MP-BGP VPNv4](06-mp-bgp-vpnv4.md) | PE 간 iBGP VPNv4 | `mp-bgp-vpnv4.ios` |
| 07 | [PE-CE eBGP](07-pe-ce-ebgp.md) | VRF 안 고객 장비와 eBGP | `pe-ce-ebgp.ios` |
| 08 | [QoS](08-qos.md) | DSCP, MPLS TC 매핑, 큐잉, shaping | `qos.ios` |
| 09 | [비밀번호 지정 위치](09-password.md) | enable, 계정, 라인, OSPF, LDP, BGP 인증 위치 | `password.ios` |