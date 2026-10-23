# MP-BGP VPNv4 검증

**선행 조건**: [MPLS와 LDP 검증](04-mpls-ldp.md), [VRF 검증](05-vrf.md)이 끝나 있고 [VPNv4 샘플](../../samples/core/06-mp-bgp-vpnv4.md)이 적용되어 있어야 함

기준 문서: [06-mp-bgp-vpnv4.md](../../baseline/core/06-mp-bgp-vpnv4.md) / 샘플: [06-mp-bgp-vpnv4.md](../../samples/core/06-mp-bgp-vpnv4.md)

## 확인 항목

| 순서 | 장비 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | PE1~PE3 | `show bgp vpnv4 unicast all summary` | 이웃 2개가 **Established**, router-id가 10.0.1.x | loopback0 도달성, `update-source loopback 0`, `send-community extended` |
| 2 | PE1~PE3 | `show bgp vpnv4 unicast all neighbors <상대 loopback0> \| include hold` | `Hold time is 9`, `keepalive interval is 3 seconds` | `neighbor ... timers 3 9` (양쪽 같은 값) |
| 3 | PE1 | `show bgp vpnv4 unicast all` | 다른 PE의 VRF 경로가 RT와 함께 보임 (PE-CE 구성 뒤) | RT import/export |

## 증빙

`show bgp vpnv4 unicast all summary`, `show bgp vpnv4 unicast all neighbors <상대 loopback0> | include hold` 출력

### PE1

- router identifier **10.0.1.11**, local AS 65000
- 이웃 10.0.0.12(PE2), 10.0.0.13(PE3) 모두 AS 65000(iBGP), State/PfxRcd가 숫자(0)라 **Established**. PE-CE 경로가 아직 없어 받은 prefix는 0
- 이웃 10.0.0.12의 hold time **9**, keepalive interval **3**초 (Configured도 같은 값)

![PE1 VPNv4](images/06-mp-bgp-vpnv4/pe1-vpnv4.png)

### PE2

- router identifier **10.0.1.12**, 이웃 10.0.0.11, 10.0.0.13 Established, PfxRcd 0
- hold 확인은 이웃이 아닌 자기 주소(10.0.0.12)로 실행되어 결과가 없음. PE1, PE3 쪽에서 확인한 값으로 대체하고, PE2는 `neighbors 10.0.0.11 | include hold`로 다시 확인 가능

![PE2 VPNv4](images/06-mp-bgp-vpnv4/pe2-vpnv4.png)

### PE3

- router identifier **10.0.1.13**, 이웃 10.0.0.11, 10.0.0.12 Established, PfxRcd 0
- 이웃 10.0.0.12의 hold time 9, keepalive interval 3초 (Configured도 같은 값)

![PE3 VPNv4](images/06-mp-bgp-vpnv4/pe3-vpnv4.png)

### VPNv4 경로 전달 (PE-CE 구성 뒤)

- PE2에서 show ip route vrf TENANT-A: 192.168.10.0/24, 192.168.20.0/24가 **B [200/0] via 10.0.0.11**(PE1 loopback0), iBGP VPNv4로 학습 (DC1 경로가 코어를 통해 전달됨)
- PE1과 leaf를 잇는 링크 서브넷 10.0.20.0/31, 10.0.20.2/31도 같은 방식으로 학습됨. leaf의 
edistribute connected가 링크 /31까지 광고하기 때문이며 동작에는 문제없음
- PE2 자신의 CX 링크 10.0.20.4, 10.0.20.6은 직결(C)

![PE2 VRF 경로](images/06-mp-bgp-vpnv4/pe2-vrf-route.png)

## 패킷 캡처 (Wireshark)

계획표: [08-wireshark-capture.md](../../00-overview/08-wireshark-capture.md). 링크 한 개만 캡처하고, 표시 필터로 패킷 한두 개의 상세 창이 보이게 잘라 images/에 저장. 캡처한 동작(어떤 명령으로 일으켰는지)을 설명에 남김

| 확인할 동작 | 캡처 링크 (GNS3 Start capture) | 일으킬 동작 | 표시 필터 | 볼 것 | 상태 |
|---|---|---|---|---|---|
| VPNv4 iBGP 세션 | PE1 `Gi0/0` - PE2 `Gi0/0` | `clear ip bgp vpnv4 unicast *` (문법은 `?`로 확인) | `bgp` | OPEN: AS 65000, Hold Time **9**, BGP Identifier **10.0.1.11**(OSPF router-id와 다름), Capability에 AFI 1 / SAFI 128(VPNv4). 출발·목적이 loopback0(10.0.0.11, 10.0.0.12) | 캡처 완료 (KEEPALIVE, OPEN, AFI 1 / SAFI 128 확인) |
| BGP keepalive 주기 | 같은 링크 | 그대로 대기 | `bgp.type == 4` | 약 3초마다 KEEPALIVE | 같은 캡처에서 필터만 변경 |
| VPNv4 경로 광고 | 같은 링크 | PE-CE 구성 뒤 세션 재시작 | `bgp.type == 2` | UPDATE의 MP_REACH_NLRI에 VPNv4, RD 65000:1과 Route Target 65000:1, VPN 레이블 | 같은 캡처에서 필터만 변경 (07 이후) |

### 캡처 결과: BGP KEEPALIVE

- 링크 PE1 `Gi0/0` - PE2 `Gi0/0`, 패킷 2673. Src **10.0.0.12**, Dst **10.0.0.11**(loopback0끼리), **TCP Dst 포트 179**(Src 63883)
- BGP: Marker 모두 ff, Length 19, Type **KEEPALIVE Message (4)**
- 이 화면은 KEEPALIVE입니다. 간격(3초)은 패킷 목록의 Time 열에서 확인

![BGP KEEPALIVE 패킷](images/06-mp-bgp-vpnv4/wireshark-bgp-keepalive.png)

### 캡처 결과: BGP OPEN

- 링크 PE1 `Gi0/0` - PE2 `Gi0/0`, 패킷 4147(세션 재시작 직후). Src **10.0.0.12**(PE2), Dst **10.0.0.11**(PE1), TCP Dst 포트 **179**(Src 21254)
- BGP OPEN Message: Version 4, **My AS 65000**, **Hold Time 9**, **BGP Identifier 10.0.1.12**(PE2의 BGP router-id, OSPF router-id 10.0.0.12와 다름), Optional Parameters Length 24
- 설계값(AS 65000, Hold 9, BGP router-id 10.0.1.x)과 일치. Optional Parameters 안의 Multiprotocol Capability(AFI 1, SAFI 128 = VPNv4)는 접힌 상태라, 해당 줄을 펼쳐 한 번 더 캡처하면 완성

![BGP OPEN 패킷](images/06-mp-bgp-vpnv4/wireshark-bgp-open.png)

- PE1이 보낸 OPEN(패킷 4148): Src **10.0.0.11**, Dst 10.0.0.12, TCP Src 포트 **179**(PE1이 서버 역할), My AS 65000, Hold Time 9, **BGP Identifier 10.0.1.11**(PE1의 BGP router-id). 두 PE의 OPEN을 합쳐 양쪽 AS, Hold Time, router-id가 모두 확인됨
- Optional Parameters 펼침: 첫 번째 Capability가 **Multiprotocol extensions capability**, **AFI IPv4 (1)**, **SAFI Labeled VPN Unicast (128)**. 즉 VPNv4 주소 패밀리를 협상. 4번째는 4-octet AS number capability(AS 65000)
- 설계한 주소 패밀리(vpnv4)와 send-community extended 구성이 OPEN 협상에 반영됨

![PE1 BGP OPEN 패킷](images/06-mp-bgp-vpnv4/wireshark-bgp-open-pe1.png)

![PE1 BGP OPEN의 Capability 펼침](images/06-mp-bgp-vpnv4/wireshark-bgp-open-afi.png)

## 결과 기록

| 일시 | 장비 | 결과 (성공, 실패) | 비고 |
|---|---|---|---|
| 2026-10-22 | PE1 | 성공 | 항목 1, 2 완료. 3(`show bgp vpnv4 unicast all`)은 PE-CE 구성 뒤 확인 |
| 2026-10-22 | PE2 | 성공 | 항목 1 완료. PE1에서 받은 VPNv4 경로가 PE2 VRF 경로에 보임(항목 3 확인). 2(hold)는 상대 주소로 다시 확인 필요 |
| 2026-10-22 | PE3 | 성공 | 항목 1, 2 완료. 3은 PE-CE 구성 뒤 확인 |