# 08. Wireshark 패킷 캡처 계획

중요한 동작은 **링크 한 개씩만** 골라서 패킷을 캡처하고, 필요한 부분만 잘라서 각 검증 문서에 증빙으로 넣음. 이 문서는 어떤 링크에서 무엇을 보는지를 정한 계획표

## 캡처 방법 (GNS3)

1. 캡처할 링크를 우클릭하고 **Start capture**를 선택한 뒤 Wireshark를 엶
2. 동작을 일으킴(명령 실행, ping, 포트 shutdown 등).
3. 필요한 패킷이 보이면 **Stop capture**로 끝냄
4. 표시 필터를 걸어서 패킷 한두 개의 상세 창(펼친 계층)이 보이게 화면을 잘라서 저장
5. 파일 이름은 `wireshark-<이름>.png`로 하고, 해당 검증 문서의 `images/<문서 이름>/` 폴더에 둠. pcap 원본은 크기가 작을 때만 `captures/` 폴더에 둠

- 캡처는 링크 양 끝 중 한쪽 방향이 아니라 **링크 전체**를 봄. 한 링크에서 양방향이 모두 보임
- 비밀번호와 키가 들어갈 수 있는 프로토콜(IPsec 사전 공유 키 등)은 패킷에 키가 노출되지 않지만, 캡처 화면에 장비 설정이 같이 찍히지 않게 주의

## DC1 (Arista)

| 확인할 동작 | 캡처 링크 (한 개) | 표시 필터 | 볼 것 |
|---|---|---|---|
| OSPF hello 타이머 | spine1 `ethernet1` - leaf1 `ethernet1` | `ospf.msg.hello` | Source OSPF Router `10.1.0.1`(OSPF router-id, BGP와 다름), Hello Interval **1**, Router Dead Interval **4**, Network Mask /31, 이웃(Active Neighbor) 목록 |
| OSPF 이웃 형성 과정 | 같은 링크 | `ospf` | Hello, DB Description, LS Request, LS Update 순서 |
| MLAG 피어링 | leaf1 `ethernet3` - leaf2 `ethernet3` | `tcp.port == 4432` (일반적인 MLAG 제어 포트, 이미지에서 확인) | `10.1.254.0`과 `10.1.254.1` 사이 TCP, VLAN 4094 태그 |
| LACP (피어 링크) | 같은 링크 | `lacp` | Actor, Partner 정보, Active 모드, 상태 플래그 |
| 네이티브 VLAN 999 | 같은 링크 | `vlan` | 데이터 VLAN은 태그가 붙고 untagged 프레임은 VLAN 999로 처리 |
| iBGP 세션 형성 | spine1 `ethernet1` - leaf1 `ethernet1` | `bgp` | OPEN(AS 65100, Hold Time 9, **BGP Identifier 10.1.2.11**: OSPF router-id 10.1.0.11과 다름), KEEPALIVE 3초 간격, 출발·목적 주소가 loopback0(`10.1.0.11` ↔ `10.1.0.1`) |
| BGP keepalive 주기 | 같은 링크 | `bgp.type == 4` | 약 3초마다 KEEPALIVE |
| EVPN 경로 광고 | 같은 링크 | `bgp.type == 2` | UPDATE의 MP_REACH_NLRI에 EVPN(Type 2 MAC/IP, Type 3 IMET, Type 5), Route Target, next-hop이 VTEP(`10.1.1.12`) |
| Route Reflector 동작 | spine1 `ethernet3` - leaf3 `ethernet1` | `bgp.type == 2` | leaf1이 광고한 경로가 spine을 거쳐 leaf3로 오며 ORIGINATOR_ID, CLUSTER_LIST 속성이 보임 |
| VXLAN 터널 (L2) | spine1 `ethernet1` - leaf1 `ethernet1` | `vxlan` | Host A에서 Host B로 ping 때 외부 UDP 4789, VNI **10010**, 외부 주소 `10.1.1.12` -> `10.1.1.34`, 안쪽 ICMP |
| VXLAN 터널 (L3) | 같은 링크 | `vxlan.vni == 50001` | Host B에서 Host C로 ping 때 L3VNI **50001** |
| 관리 ACL 차단 | leaf1 `ethernet1` - spine1 `ethernet1` | `tcp.port == 22` | spine1에서 leaf1로 SSH 시 SYN만 보이고 응답이 없음 |

## MPLS 코어 (c7200)

| 확인할 동작 | 캡처 링크 (한 개) | 표시 필터 | 볼 것 |
|---|---|---|---|
| OSPF hello | PE1 `Gi0/0` - PE2 `Gi0/0` | `ospf.msg.hello` | 코어 OSPF 이웃 |
| LDP 세션 | 같은 링크 | `ldp` | Hello(UDP 646), 이후 TCP 646 세션과 Label Mapping |
| MPLS 라벨 스택 | 같은 링크 | `mpls` | 직결 링크에서는 PHP로 VPN 라벨 1개만 보임. 라벨 2개(전송, VPN)는 PE3를 거치는 우회 경로(장애 시험)에서 보임. TC 값 확인 |
| VPNv4 iBGP | 같은 링크 | `bgp` | OPEN의 AFI/SAFI VPNv4, UPDATE의 RD(65000:1)와 Route Target |
| PE-CE eBGP (DC1) | PE1 `Gi2/0` - leaf3 `ethernet5` | `bgp` | AS 65000과 65100, Hold Time 9, BGP Identifier(PE1 10.0.1.11, leaf3 VRF router-id 10.1.2.13), UPDATE에 192.168.10.0/24, 192.168.20.0/24 |
| QoS (MPLS TC) | 같은 링크 | `mpls.exp == 5` | 음성 트래픽의 TC 5 (`ip.dsfield.dscp == 46`과 비교) |

## DC1 WAN 출구와 Branch

| 확인할 동작 | 캡처 링크 (한 개) | 표시 필터 | 볼 것 |
|---|---|---|---|
| IKE 협상 (IKEv1) | Hub1 `Gi0/0` - PE1 `Gi4/0` | `isakmp` | Main Mode 메시지 교환, 암호화 제안(AES-256, SHA, group 14) |
| IPsec 데이터 | 같은 링크 | `esp` | ESP 패킷만 보이고 안쪽(GRE, BGP)은 암호화되어 보이지 않음 |
| 터널 안쪽(복호화 후) | BGW1 `Gi1/0` - DSW1 `Gi0/0` | `ospf or icmp` | Branch 쪽에서는 일반 IP |
| MSTP | DSW1 `Gi0/3` - ASW1 `Gi0/0` | `stp` | MST region `LAB`, revision 1, 인스턴스별 regional root 우선순위 4096 |
| LACP | DSW1 `Gi0/3` - ASW1 `Gi0/0` | `lacp` | EtherChannel 협상 |
| VRRP | DSW1 `Gi0/1` - DSW2 `Gi0/1` | `vrrp` | VIP 192.168.50.1, VRID 50 우선순위 110, Advertisement |

## DC2 (Aruba)

| 확인할 동작 | 캡처 링크 (한 개) | 표시 필터 | 볼 것 |
|---|---|---|---|
| VSX 키퍼얼라이브 | CX1 `1/1/4` - CX2 `1/1/4` | `udp` | 10.2.254.0 <-> 10.2.254.1 사이 주기적 UDP |
| LACP (VSX LAG) | CX1 `1/1/5` - CX3 `1/1/1` | `lacp` | 멀티섀시 LAG 협상 |
| eBGP (PE2) | CX1 `1/1/1` - PE2 `Gi2/0` | `bgp` | AS 65201과 65000 |

## 대표 캡처 기준

같은 프로토콜을 지역마다 반복해서 캡처하지 않고, **포트나 전송 방식이 다르거나 전용인 프로토콜만 대표로 한 번씩** 캡처. 나머지 구간은 CLI 검증으로 확인하고 캡처는 생략

| 프로토콜 | 대표 링크 | 이유 | 검증 문서 |
|---|---|---|---|
| OSPF | PE1 `Gi0/0` - PE2 `Gi0/0` | IP 프로토콜 89 | [core 03](../verification/core/03-ospf.md) (DC1 underlay는 [dc1 01](../verification/dc1/01-ospf-underlay.md)) |
| LDP | PE1 `Gi0/0` - PE2 `Gi0/0` | UDP/TCP 646 | [core 04](../verification/core/04-mpls-ldp.md) |
| MPLS 라벨 스택 | 같은 링크 | 전용 프레임(VPN 라벨, 우회 시 라벨 2개) | [core 04](../verification/core/04-mpls-ldp.md) |
| BGP | PE1 `Gi0/0` - PE2 `Gi0/0` (VPNv4) | TCP 179, AFI/SAFI와 타이머. iBGP EVPN, PE-CE eBGP, 터널 위 eBGP는 같은 프로토콜이라 생략 | [core 06](../verification/core/06-mp-bgp-vpnv4.md) |
| VSX keepalive | CX1 `1/1/4` - CX2 `1/1/4` | 전용 UDP 7678 | [dc2 03](../verification/dc2/03-vsx.md) |
| LACP | CX1 `1/1/5` - CX3 `1/1/1` | slow protocols. VSX system-mac 확인 | [dc2 04](../verification/dc2/04-vsx-lag.md) |
| VXLAN | spine1 `ethernet1` - leaf1 `ethernet1` | UDP 4789 | [dc1 03](../verification/dc1/03-evpn-vxlan.md) |
| IKE, ESP | Hub1 `Gi0/0` - PE1 `Gi4/0` | UDP 500, ESP | Branch 단계 |
| STP(MSTP) | DSW1 `Gi0/3` - ASW1 `Gi0/0` | 전용 BPDU(802.3 + LLC), 인스턴스별 root | [br 02](../verification/br/04-mstp-etherchannel.md) (캡처 완료) |
| VRRP | DSW1 `Gi0/1` - DSW2 `Gi0/1` | 전용 IP 프로토콜 112, 224.0.0.18 | [br 03](../verification/br/05-vrrp-svi.md) (캡처 완료) |

## 증빙에 넣는 방법

- 각 검증 문서의 증빙 절에 "패킷 캡처 (Wireshark)" 소절을 추가하고, 위 표의 행마다 화면과 한 줄 설명(무엇이 보이는지)을 넣음
- 한 링크에서 여러 프로토콜을 볼 때는 캡처 한 번으로 모아서 표시 필터만 바꿔 화면을 여러 장 저장
- 캡처한 시각과 어느 동작(어떤 명령, 어떤 ping)을 일으켰는지를 파일 이름이나 설명에 남김