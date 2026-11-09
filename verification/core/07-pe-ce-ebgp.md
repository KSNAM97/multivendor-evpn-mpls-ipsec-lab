# PE-CE eBGP 검증

**선행 조건**: [VRF 검증](05-vrf.md), [MP-BGP VPNv4 검증](06-mp-bgp-vpnv4.md)이 끝나 있고 [PE-CE 샘플](../../samples/core/07-pe-ce-ebgp.md)이 적용되어 있어야 함. [기준 문서](../../baseline/core/07-pe-ce-ebgp.md)

## 확인 항목

| 순서 | 장비 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | PE1 | `show bgp vpnv4 unicast vrf TENANT-A summary` | Hub1(10.0.30.1), Hub2(10.0.30.3)가 AS 65010, **Established**, State/PfxRcd가 숫자 | 링크 IP, AS 번호, Hub 쪽 `neighbor 10.0.30.0`(Hub1), `10.0.30.2`(Hub2) |
| 2 | PE2 | `show bgp vpnv4 unicast vrf PARTNER summary` | CX1(10.0.20.5), CX2(10.0.20.7)가 AS 65201, **Established** | 링크 IP, CX 쪽 `router bgp 65201` |
| 3 | PE3 | `show ip bgp vpnv4 vrf BR1 summary` | BGW1(10.0.60.1), BGW2(10.0.60.3)가 AS 65020, **Established**, PfxRcd 2(192.168.50.0, 192.168.60.0) | `.100` 서브인터페이스, BGW 쪽 `router bgp 65020` |
| 4 | PE1 | `show ip route vrf TENANT-A 192.168.50.0` | BGP(내부) 경로, next hop 10.0.0.13(PE3) | PE3 VRF BR1 export RT 65000:3, PE1 TENANT-A import RT 65000:3 |
| 5 | PE1 | `show bgp vpnv4 unicast all labels` | RD 65000:3의 192.168.50.0, 192.168.60.0이 next hop 10.0.0.13, `nolabel/26`, `nolabel/27` | VPNv4 세션(PE1 - PE3) |
| 6 | PE2 | `show ip route vrf PARTNER` | 192.168.110.0/24(CX 경유)와 BR1 경로(192.168.50.0, 192.168.60.0) 보임. DC1 경로(192.168.10.0)는 **없음** | PARTNER import RT에 65000:1이 없어야 함 |
| 7 | PE1 | `show ip route vrf TENANT-A` | DC1 경로와 BR1 경로 보임. DC2 경로(192.168.110.0)는 **없음** | TENANT-A import RT에 65000:2가 없어야 함 |
| 8 | PE1, PE2, PE3 | `show bgp vpnv4 unicast ... neighbors <이웃> \| include hold` | `hold time is 9, keepalive interval is 3 seconds` | 양쪽 `timers 3 9` |

- 3번은 BGW가 설정된 뒤, 6번과 7번은 DC1, DC2, Branch가 모두 연결된 뒤 확인

## 측정 결과 (2026-11-07)

- PE1 `show ip route vrf TENANT-A 192.168.50.0`: Routing entry for 192.168.50.0/24, Known via **"bgp 65000"**, distance 200, metric 2, Tag 65020, type internal, from **10.0.0.13**. BR1 경로를 PE3(VPNv4)에서 받음
- PE1 `show bgp vpnv4 unicast all labels`: RD 65000:1(TENANT-A)에 10.0.31.0/31 등 DC1 경로와 192.168.50.0, 192.168.60.0(next hop 10.0.0.13, `nolabel/26`, `nolabel/27`), RD 65000:3에도 같은 두 경로
- PE2 `show bgp vpnv4 unicast all summary`: 이웃 10.0.0.11(PE1) PfxRcd 6, 10.0.0.13(PE3) PfxRcd 2, CX 10.0.20.5, 10.0.20.7(AS 65201) PfxRcd 각 2, 모두 Established
- 화면 증빙은 최종 구성에서 다시 찍어 추가해야 함. 이전 구성(leaf 직결, WAN-UL)에서 찍은 화면은 삭제함

## 패킷 캡처 (Wireshark)

| 캡처 링크 | 표시 필터 | 볼 것 |
|---|---|---|
| PE1 `Gi1/0` - PE3 `Gi0/0` | `mpls` | Host A와 Host F ping 때 VPN 레이블 1개(S=1). PE1 -> PE3는 Label 26(BR1 192.168.50.0), PE3 -> PE1은 Label 33(192.168.10.101/32, PE1 표의 in label)과 일치. 직결 링크라 PHP로 전송 레이블은 보이지 않음 |
| PE1 `Gi2/0` - Hub1 `Gi0/0` | `bgp` | OPEN: AS 65000과 65010, Hold Time 9, UPDATE에 192.168.10.0/24, 192.168.20.0/24 |

## 결과 기록

| 일시 | 결과 (성공, 실패) | 비고 |
|---|---|---|
| 2026-10-22 | 이전 구성 | leaf 직결, WAN-UL 구성에서 확인. 최종 구성에서 재확인 |
| 2026-11-07 | 부분 확인 | 항목 4, 5와 PE2 이웃 상태 확인. Host A ↔ Host F, Host D ↔ Host F ping 통과 |
