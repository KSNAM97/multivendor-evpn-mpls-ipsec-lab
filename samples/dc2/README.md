# DC2 (Aruba AOS-CX) 샘플 컨피그

구축 순서와 번호가 같음. 같은 이름의 샘플 파일(원본, `.aos`)은 장비에 붙여 넣기 쉽게 그대로 둠. 장비에서 검증한 컨피그가 아니라 문법 참고용 샘플

| 번호 | 문서 | 내용 | 파일 |
|---|---|---|---|
| 01 | [기본 설정](01-base.md) | 장비 이름, 계정, 세션, 관리 인터페이스 | `base.aos` |
| 02 | [인터페이스 IP](02-ip.md) | loopback0, PE2 방향 링크, VRF 소속 | `ip.aos` |
| 03 | [VSX](03-vsx.md) | VSX 쌍(ISL, keepalive) | `vsx.aos` |
| 04 | [VSX LAG](04-vsx-lag.md) | access 스위치(CX3)를 VSX 쌍에 하나의 LAG로 연결 | `vsx-lag.aos` |
| 05 | [VSX active gateway](05-active-gateway.md) | VLAN 110 게이트웨이를 active-active로 제공 | `active-gateway.aos` |
| 06 | [PE와 VRF eBGP](06-ebgp-pe.md) | PE2와 VRF 경로 교환 | `ebgp-pe.aos` |
| 07 | [비밀번호 지정 위치](07-password.md) | 계정, BGP neighbor 인증 위치 | `password.aos` |