# DC1 외부 연결 검증 (leaf - Hub - PE1)

**선행 조건**: [EVPN-VXLAN 검증](03-evpn-vxlan.md)이 끝나 있고, MPLS 코어(PE1)가 올라와 있어야 함([core 검증](../core/06-mp-bgp-vpnv4.md))

기준 문서: [06-dci-hub-ebgp.md](../../baseline/dc1/06-dci-hub-ebgp.md) / 샘플: [09-pe-ce-ebgp.md](../../samples/dc1/09-pe-ce-ebgp.md), [Hub 가이드](../../guide/06-hub.md)

## 확인 항목

| 순서 | 장비 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | Hub1 | `ping 10.0.30.0` (PE1 `Gi4/0`), `ping 10.0.31.0` (leaf3), `ping 10.0.32.2` (leaf4) | 모두 응답 | 링크 IP, 인터페이스 up |
| 2 | Hub2 | `ping 10.0.30.2` (PE1 `Gi5/0`), `ping 10.0.31.2` (leaf4), `ping 10.0.32.0` (leaf3) | 모두 응답 | 같은 점검 |
| 3 | Hub1 | `show ip bgp summary` | PE1(10.0.30.0, AS 65000), leaf3(10.0.31.0), leaf4(10.0.32.2) (AS 65100)가 **Established** | AS 번호, 주소, address-family activate |
| 4 | Hub2 | `show ip bgp summary` | PE1(10.0.30.2), leaf4(10.0.31.2), leaf3(10.0.32.0)가 **Established** | 같은 점검 |
| 5 | leaf3 | `show ip bgp summary vrf TENANT-A` | Hub1(10.0.31.1)과 Hub2(10.0.32.1)(AS 65010)가 **Established**, router identifier 10.1.2.13 | VRF 안 `router-id`, address-family activate |
| 6 | leaf4 | `show ip bgp summary vrf TENANT-A` | Hub2(10.0.31.3)와 Hub1(10.0.32.3)가 **Established**, router identifier 10.1.2.14 | 같은 점검 |
| 7 | leaf3 | `show ip route vrf TENANT-A` | Branch 경로(192.168.50.0/24, 192.168.60.0/24)가 Hub 2대를 next hop으로 ECMP(2경로) | PE1 TENANT-A import RT 65000:3 |
| 8 | Host A | `ping -c 3 192.168.50.101` | Host F 응답 (DC1 -> Branch) | PE-CE eBGP, VPNv4 RT |
| 9 | Host A | `ping -c 3 192.168.110.101` | **응답 없음**(정상). DC1과 DC2는 분리 | TENANT-A import RT에 65000:2가 없어야 함 |
| 10 | leaf3 | `show ip bgp neighbors 10.0.31.1 vrf TENANT-A \| include hold` | `Hold time is 9`, `keepalive interval is 3 seconds` | 양쪽 `timers 3 9` |

## 장애 시험 (2026-11-07)

Host A에서 Host F(192.168.50.101)로 ping 300개를 보내면서 링크를 내림. 복구는 모두 자동

| 시험 | 내린 링크 | 결과 | 설명 |
|---|---|---|---|
| T1 | PE1 `Gi4/0` (PE1 - Hub1) | 300/300 응답, 손실 0, 최대 RTT 1557 ms | PE1은 Hub2로 우회. Dynamips는 상대 쪽이 링크 down을 바로 인식하지 못해 BGP hold 9초가 감지 기준이지만, 이 시험에서는 경로가 이미 ECMP로 두 Hub를 쓰고 있어 손실이 없었음 |
| T1b | PE1 `Gi5/0` (PE1 - Hub2) | 258/300 응답, 손실 약 8.4초 | Hub2 경로를 쓰던 흐름이 hold 9초 안에 Hub1로 옮겨 감 |
| T2 | PE2 `Gi1/0` (PE2 - PE3 코어 링크) | 237/300 응답(오류 2개 포함), 손실 약 12.6초 | 이 링크가 끊기면 PE2 -> PE3 next hop이 PE1(10.0.10.0)을 경유하도록 바뀜. OSPF dead 4초 이후 BGP, LDP가 재수렴 |

- 세 시험 모두 링크를 올리면 경로가 자동으로 복구됨(별도 조치 없음)
- 이 결과의 전제: leaf3·4가 Hub 2대에 모두 연결(교차 연결). leaf3·4가 VTEP을 공유하는데 각 leaf가 Hub 1대에만 연결되어 있으면 Hub 한쪽 경로가 끊길 때 그 Hub에 연결된 leaf로 들어온 트래픽이 블랙홀이 되어 복구되지 않음(교차 연결 이전 구성에서 확인)

## 증빙

이전 구성(leaf3·4 - PE1 직결, Hub 정적 경로)에서 찍은 화면은 삭제함. 최종 구성의 항목 1 ~ 7, 10 화면과 T1, T1b, T2 화면(ping 통계, 로그)은 추가해야 함

PE1에서 확인한 값(2026-11-07): `show ip route vrf TENANT-A 192.168.50.0`이 BGP(내부) 경로, next hop 10.0.0.13(PE3), tag 65020. `show bgp vpnv4 unicast all labels`에 RD 65000:1과 65000:3이 함께 보이고 192.168.10.0, 192.168.20.0은 Hub 2대(10.0.30.1, 10.0.30.3)를 next hop으로 가짐

## 패킷 캡처 (Wireshark)

| 캡처 링크 | 표시 필터 | 볼 것 |
|---|---|---|
| PE1 `Gi4/0` - Hub1 `Gi0/0` | `bgp` | OPEN: AS 65000과 65010, Hold Time 9, BGP Identifier(PE1 10.0.1.11, Hub1 10.0.1.21), UPDATE에 192.168.10.0/24, 192.168.20.0/24 |
| leaf3 `ethernet6` - Hub1 `Gi1/0` | `bgp` | AS 65100과 65010, Hold Time 9 |

## 결과 기록

| 일시 | 결과 (성공, 실패) | 비고 |
|---|---|---|
| 2026-10-22 | 이전 구성 | leaf3·4 - PE1 직결, Hub 정적 경로 구성에서 확인. 최종 구성으로 변경됨 |
| 2026-11-07 | 성공 (장애 시험) | T1 손실 0, T1b 약 8.4초, T2 약 12.6초, 모두 자동 복구. Host A ↔ Host F ping 통과 |
| 2026-11-07 | 확인 필요 | 항목 1 ~ 7, 10 화면 증빙을 최종 구성에서 다시 찍어 추가 |
