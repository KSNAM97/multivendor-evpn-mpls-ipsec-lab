# 연결 확인 시나리오

호스트 사이 도달성을 가까운 곳부터 먼 곳 순서로 확인. 명령은 [샘플](../../samples/host/04-connectivity.md)

## 확인 순서

| 순서 | 구간 | 출발 -> 대상 | 쓰는 기술 | 선행 단계 |
|---|---|---|---|---|
| 1 | 게이트웨이 | 각 호스트 -> 자기 게이트웨이 | anycast gateway, VSX active gateway, VRRP | 해당 지역 SVI, 게이트웨이 설정 |
| 2 | 같은 VLAN (DC1) | Host A -> Host B `192.168.10.102` | VXLAN L2VNI 10010 (leaf1·2 -> leaf3·4) | EVPN-VXLAN |
| 3 | 다른 VLAN (DC1) | Host A -> Host C `192.168.20.101` | VXLAN L3VNI 50001 (VRF TENANT-A, symmetric IRB) | EVPN-VXLAN |
| 4 | DC1 -> DC2 | Host A -> Host D `192.168.110.101` | leaf3·4 -> PE1 -> MPLS L3VPN -> PE2 -> CX1·2 -> CX3 | DCI(eBGP), MPLS 코어, DC2 |
| 5 | DC1 -> Branch | Host A -> Host F `192.168.50.101` | border leaf -> Hub -> GRE over IPsec -> BGW -> DSW -> ASW1 | Hub, 터널 eBGP, Branch |
| 6 | Branch 내부 | Host F -> Host G `192.168.60.101` | DSW의 SVI 간 라우팅 (VRRP) | Branch SVI, VRRP |

## 결과 기록

| 일시 | 순서 | 결과 | 비고 |
|---|---|---|---|
| 2026-10-22 | 1 (게이트웨이) | Host A, B, C 성공 | Host A `192.168.10.1` 3/3 (bond0), Host B `192.168.10.1` 3/3, Host C `192.168.20.1` 3/3. Host D, F, G는 해당 지역 연결 후 확인
| 2026-10-22 | 2, 3 (DC1 같은 VLAN, 다른 VLAN) | Host A -> Host B, Host A -> Host C 성공 | Host A -> Host B `192.168.10.102` 3/3 (ttl 64, L2VNI 10010), Host A -> Host C `192.168.20.101` 3/3 (L3VNI 50001). Host D, F, G는 DC2, Branch 구성 후 확인 |
| 2026-10-22 | 1, 4 (Host D 게이트웨이, DC1에서 DC2 방향) | Host D 성공 | Host D(`eth1`, CX1 `1/1/7` 직접 연결) -> `192.168.110.1` ARP 응답(VMAC `12:00:00:00:01:10`), Host D -> Host A `192.168.10.101` 3/3 (ttl 59). CX3 경유 연결은 이미지 한계로 사용 못 함 ([DC2 05](../../verification/dc2/05-active-gateway.md), [DC2 06](../../verification/dc2/06-ebgp-pe.md)). Host F, G는 Branch 구성 후 확인 |

- 경로는 `traceroute -n <대상>`으로 확인
- 각 단계의 증빙(화면, 캡처)은 해당 지역의 검증 문서에 넣음