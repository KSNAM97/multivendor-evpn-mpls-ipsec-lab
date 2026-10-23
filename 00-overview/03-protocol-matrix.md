# 03. 프로토콜 매트릭스 (계층별 x 벤더별)

설정 예시는 이 문서를 확정한 뒤 벤더별로 따로 작성

## 1. 계층 구성

| 계층 | 프로토콜 | 역할 |
|---|---|---|
| L2 | VLAN, 802.1Q, LACP/EtherChannel, MLAG/VSX, MSTP | 호스트 접속, 스위치 이중화 |
| 게이트웨이 | anycast gateway, VSX active gateway, VRRP | 기본 게이트웨이 이중화 |
| L3 (Underlay) | OSPF (DC1, 코어, Branch) | VTEP, 코어 루프백 도달성 |
| Overlay (DC) | VXLAN + iBGP EVPN | DC1 내부 L2/L3 가상 네트워크 |
| Overlay (WAN) | MPLS (OSPF + LDP) + MP-BGP VPNv4 | DC 사이 L3VPN |
| WAN 언더레이 (VRF WAN-UL) | 정적 경로(PE1 - Hub), eBGP(PE3 - BGW) | 터널 양끝 주소(10.0.30.x) 도달성. 구역별 방식은 [코어 PE-CE 기준](../baseline/core/07-pe-ce-ebgp.md) |
| 보안 터널 | GRE over IPsec (IKEv1) x2 + eBGP | Branch 연결 (이중 터널) |
| 부하 분산 | ECMP, BGP multipath, LACP 해시, MSTP 인스턴스 분산 | 경로와 링크 분산 |
| QoS | DiffServ (DSCP, MPLS TC) | 트래픽 보장 |

## 2. 벤더별 적용 범위

| 벤더 | 장비 | 담당 계층 |
|---|---|---|
| Arista | vEOS 6대 | DC1: OSPF underlay, MLAG x2, iBGP EVPN-VXLAN(L2/L3VNI), border leaf의 PE와 Hub 연동 |
| Aruba | CX 3대 | DC2: VSX 쌍(CX1, CX2) + access(CX3), active gateway, PE와 eBGP |
| Cisco c7200 | 7대 | MPLS 코어 PE 삼각형(OSPF, LDP, MP-BGP), Hub와 BGW 이중 터널, IPsec, QoS 집행 |
| Cisco IOSv | 3대 | Branch 스위치단 (VLAN, MSTP, EtherChannel, VRRP, OSPF) |

벤더는 Cisco, Arista, Aruba 3개. Juniper(vQFX)는 이 GNS3 환경에서 PFE가 FPC로 등록되지 않아 제외됨

## 3. 이중화와 부하 분산

### 3-1. 스위치

| 스위치 | 벤더 | 이중화 | 부하 분산 |
|---|---|---|---|
| spine1, spine2 | Arista | 2대가 동일 역할 | leaf 방향 OSPF ECMP, iBGP Route Reflector, ECMP |
| leaf1, leaf2 | Arista | **MLAG** 쌍 + anycast gateway | 호스트 LACP 해시, spine 2개로 ECMP |
| leaf3, leaf4 | Arista | **MLAG** 쌍 (border) | PE1로 2링크, Hub1과 Hub2로 각각 연결 |
| CX1, CX2 | Aruba | **VSX** 쌍 + active gateway | CX3 4링크 VSX LAG 해시, PE2 두 경로 |
| CX3 | Aruba | access (CX1, CX2에 VSX LAG 연결) | 4링크 LAG 해시 |
| DSW1, DSW2 | Cisco IOSv | **EtherChannel(LACP)** Po1 (DSW 간), VRRP, MSTP root 분담 | VLAN 50은 DSW1 master, VLAN 60은 DSW2 master |
| ASW1 | Cisco IOSv | 각 DSW에 **2링크 EtherChannel** (Po2, Po3) | MSTP 인스턴스별 root가 달라 번들별 blocking이 갈림 (VLAN 단위 분산) |

### 3-2. 라우터

| 구간 | 이중화 | 부하 분산 |
|---|---|---|
| 코어 | PE1, PE2, PE3 삼각형 (한 링크 장애 시 우회) | OSPF/LDP ECMP |
| DC1 WAN 출구 | Hub1, Hub2 (각각 leaf3, leaf4에 연결, PE1에 이중 연결) | 두 Hub로 eBGP multipath(ECMP) |
| Branch WAN 출구 | BGW1, BGW2 (PE3에 이중 연결, 각각 DSW1, DSW2에 연결) | 터널 2개(Tunnel0, Tunnel1) ECMP |

- DC2(Aruba)는 VSX 쌍이 단일 VTEP이라 EVPN 대상이 없으므로 VSX LAG, active gateway, eBGP 연동을 시연. EVPN-VXLAN은 DC1(Arista)에서 시연
- Cisco IOSv에는 MLAG(vPC, StackWise Virtual)가 없음. 그래서 EtherChannel과 MSTP 조합으로 이중화
- 각 스위치에서 EtherChannel 해시 방식(src-dst-ip 등)을 명시해 분산 결과를 인터페이스 카운터로 확인
- VRRP는 호스트 게이트웨이가 있는 Branch LAN에만 씀. Hub와 BGW는 게이트웨이가 아니라 경로 장비라서 FHRP 대신 이중 eBGP와 ECMP로 이중화

## 4. 프로토콜 x 장비 매트릭스

| 프로토콜 | spine (Arista) | leaf1-4 | PE1-3 | Hub1,2 | BGW1,2 | DSW | ASW | CX1-3 |
|---|---|---|---|---|---|---|---|---|
| OSPF | O | O | O (코어) | - | O (Branch) | O | - | - |
| LDP / MPLS | - | - | O | - | - | - | - | - |
| iBGP EVPN | O (AS 65100, spine이 RR) | O | - | - | - | - | - | - |
| iBGP VPNv4 | - | - | O (full mesh) | - | - | - | - | - |
| eBGP (PE-CE) | - | leaf3,4 | O | - | - | - | - | CX1,2 |
| eBGP (WAN-UL, PE3 - BGW) | - | - | PE3 | - | O | - | - | - |
| eBGP (Hub) | - | leaf3,4 | - | O | O | - | - | - |
| 정적 경로 (Hub - BGW 터널 주소) | - | - | PE1 (redistribute connected) | O | - | - | - | - |
| VXLAN | - | O | - | - | - | - | - | - |
| MLAG / VSX | - | MLAG | - | - | - | - | - | VSX |
| LACP / EtherChannel | - | O | - | - | - | O | O | O |
| MSTP | O (mode mstp) | O (mode mstp) | - | - | - | O | O | - |
| VRRP | - | - | - | - | - | O | - | - |
| GRE + IPsec | - | - | - | O | O | - | - | - |
| VRF | - | O | O | - | - | - | - | O |
| ECMP / multipath | O | O | O | O | O | - | - | O |
| QoS 큐잉/shaping | - | - | O | O | O | - | - | - |

## 5. 단계별 목표 프로토콜

| 단계 | 구성 | 완료 기준 |
|---|---|---|
| 1 | DC1: OSPF underlay + MLAG x2 + iBGP EVPN-VXLAN | Host A, B, C 간 L2/L3 통신, spine ECMP과 MLAG 장애 전환 확인 |
| 2 | MPLS 코어(PE 삼각형) + DC1 DCI | PE1 VRF 경유 경로 광고, 코어 링크 장애 우회 |
| 3 | DC2(Aruba) 연동 | DC1과 DC2 간 TENANT-A 통신, VSX 장애 전환 |
| 4 | Hub, BGW 이중 GRE over IPsec + Branch 스위치단 | 터널 위 eBGP와 ECMP, VRRP, MSTP 인스턴스별 blocking, EtherChannel 장애 전환 |
| 5 | QoS 적용과 검증 | 혼잡 상황에서 EF 지연과 손실 비교 |
| 6 | 장애 주입과 트러블슈팅 문서화 | 시나리오별 증상, 원인, 조치 기록 |

단계마다 필요한 노드만 켬. 4단계에서는 DC2를 끌 수 있음

## 6. 벤더별 멀티호밍 대응 (비교용)

| 벤더 | 기술 | 이 프로젝트 |
|---|---|---|
| Arista | MLAG | DC1 leaf1/leaf2, leaf3/leaf4 |
| Aruba | VSX | DC2 CX1/CX2 |
| Cisco IOSv | EtherChannel + MSTP | Branch DSW, ASW |
| Juniper | EVPN ESI-LAG | 미사용 (대응표만, vQFX는 환경 문제로 제외) |
| Cisco Nexus | vPC | 미사용 (대응표만) |
| Cisco Catalyst | StackWise Virtual | 미사용 (대응표만) |
| NVIDIA Cumulus | MLAG (clagd) | 대응표만 |
| 표준 | EVPN Multihoming (RFC 7432) | 비교 문서 |

## 7. 확인이 필요한 항목

| 항목 | 확인 방법 |
|---|---|
| c7200 이미지의 IPsec 지원 | 확인됨: `isakmp`, `ipsec` 있음, `ikev2` 없음(IKEv1), ISAKMP `hash sha256` 미지원(SHA-1 사용), `group 14` 지원 |
| c7200 MPLS/LDP, VRF 지원 | 확인됨: IOS 12.4(24)T5에서 `ip vrf`, `mpls ip`, `address-family vpnv4` 수락 |
| c7200 슬롯 구성 (PE1은 6포트) | GNS3 템플릿에서 PA-GE 슬롯 추가 |
| IOSvL3의 스위치 기능 (SVI, EtherChannel, VRRP) | `show vlan`, `show etherchannel`, `show vrrp` |
| IOSvL2의 EtherChannel(LACP)과 MSTP | 확인됨: MSTP 설정 수락, `channel-group 1~3 mode active` 수락, LACP 협상 동작(상대 포트 미설정 시 suspended 메시지). 그룹 번호는 1~3 사용(99는 거부). 실제 번들링(P)은 상대 연결 후 확인. 상세는 [기능 지원 확인 결과](05-feature-check.md) |
| IOSv 노드 어댑터 수 (DSW 5, ASW 6) | GNS3 템플릿에서 어댑터 수 조정 |
| AOS-CX Virtual 10.07의 LAG 데이터 경로 | 확인됨(한계): `lag10`은 LACP 협상(`ALFNCD`)까지 정상이지만 VLAN 110 데이터 프레임이 LAG를 통과하지 못함. 같은 링크를 일반 트렁크로 쓰면 정상. 그래서 Host D를 CX1 `1/1/7`에 직접 연결. ISL(`lag256`)은 정상. 상세는 [DC2 active gateway 검증](../verification/dc2/05-active-gateway.md) |
| AOS-CX Virtual의 `lacp rate fast` | 확인됨(한계): 에뮬레이션 부하에서 LACP가 반복해서 흔들려(`X`, `lacp-block`, VSX Out-Of-Sync) 제거하고 기본(slow) 사용 |
| vEOS의 VXLAN DSCP 복사 동작 | 캡처로 외부 헤더 DSCP 확인 |
| vEOS ACL의 interface 적용 | 확인됨: `ip access-group ... in/out`이 `% Unavailable command (not supported on this hardware platform)`로 거부됨. QoS 분류와 패킷 필터에 쓰지 않음. 컨트롤 플레인 ACL은 사용자 정의도 수락, 활성(`system control-plane`). 실제 차단은 미확인 |
| Aruba CX 시뮬레이터 QoS 기능 범위 | `show qos`에 cos-map, dscp-map, queue-profile, schedule-profile, threshold-profile, trust가 있음(상세는 [기능 지원 확인 결과](05-feature-check.md)) |
| QEMU 노드 vCPU 1개 안정성 | 이미지별로 부팅, BGP 유지 확인 후 필요 시 2개로 상향 |
| Arista vEOS RAM 축소 후 안정성 | 설정 투입 후에도 BGP, EVPN 유지 확인 |

## 협상 조건 통일 (타이머와 ID)

OSPF, BGP, LACP의 협상 조건은 **DC1 기준으로 전 구간을 통일**. 이웃은 양쪽이 같은 값이어야 맺어지거나, 협상해서 작은 값을 쓰기 때문

| 프로토콜 | 값 | 적용 범위 |
|---|---|---|
| OSPF | point-to-point, **hello 1초, dead 4초**, loopback은 passive | DC1 spine-leaf, 코어 PE 링크, Branch BGW-DSW 링크 |
| BGP | **keepalive 3초, hold 9초** (`timers 3 9`) | DC1 iBGP(EVPN), 코어 PE 간 iBGP(VPNv4), PE-CE eBGP(leaf3·4, CX ↔ PE), WAN-UL eBGP(PE3 ↔ BGW), 터널 위 eBGP(Hub ↔ BGW) |
| LACP | **fast**(1초 간격). 단 DC2 VSX LAG는 에뮬레이션에서 흔들려 **기본(slow)** 사용 | DC1 호스트 포트(leaf `lacp timer fast`, 호스트 `lacp_rate fast`). Branch EtherChannel은 IOSvL3가 `lacp rate fast`를 받지 않아 **기본(30초)** |
| router-id | OSPF는 loopback0 주소, **BGP는 별도 대역** | 전 구간 ([IP 설계](02-ip-addressing.md) 3-1-1) |

- 기본값은 OSPF 10초/40초, BGP 60초/180초, LACP 30초 간격. 빠른 수렴을 위해 줄였고, 이 랩은 장비 부하가 커서 이웃이 불필요하게 끊기면(flap) OSPF 2초/8초, BGP 6초/18초 정도로 올림
- 링크가 끊기면 OSPF가 dead 4초 안에 먼저 경로를 바꾸고, BGP는 hold 9초 안에 이웃을 내림
- 새 구간을 구성할 때는 이 표의 값을 먼저 적용
