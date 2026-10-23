# 트러블슈팅

설계와 다르게 동작했거나 시험 중 문제가 된 항목과 조치

## 요약

| 분류 | 항목 | 조치 |
|---|---|---|
| 장비 한계 | Aruba 가상 이미지에서 LAG(lag10) 위 VLAN 110 데이터가 전달되지 않음(LACP 협상은 정상) | 설계 변경: Host D를 CX1 `1/1/7`에 직접 연결 |
| 장비 한계 | vEOS가 인터페이스 ACL을 지원하지 않음 | 설계 변경: QoS 분류는 c7200 |
| 설정 | `lacp rate fast`로 LACP와 VSX ISL이 흔들림 | `no lacp rate`로 slow 복귀 |
| 설정 | AOS-CX VRF의 BGP router-id가 SVI 주소로 선택됨 | `vrf` 하위에 router-id 지정 |
| 설정 | IOSv 포트채널 멤버의 trunk 설정이 서로 달라 묶이지 않음 | `switchport trunk encapsulation dot1q` 포함 같은 설정 |
| 설정 | IOSvL3 물리 포트에 IP와 VRF를 줄 때 거부됨 | `no switchport`를 먼저 입력 |
| 설계 | BGW BGP가 Branch LAN을 PE3로 광고 | `prefix-list NONE out`, network는 터널 단계에서 광고 |
| 시험 | TCP 처리량이 터널 없는 구간에서도 끊김 | ping과 UDP 저속 전송으로 검증 |
| 시험 | 혼잡 시험 중 PE1-PE2 BGP가 22초 끊김 | NETCTRL 클래스 추가 |

## 사례 1: LACP rate fast

- 증상: ISL `lag256`이 `lacp-block`, 상대 Out-Of-Sync, VSX 상태 Out-Of-Sync가 반복됨
- 확인: LACP 상태 화면에서 상대 장비가 Out-Of-Sync로 표시됨([캡처](../verification/dc2/images/04-vsx-lag/wireshark-lacp.png))
- 조치: `lag256`과 `lag10`에서 `no lacp rate` 입력, 이후 안정
- 상세: [VSX LAG 검증](../verification/dc2/04-vsx-lag.md)

## 사례 2: TCP만 끊기고 ping과 UDP는 정상

- 증상: iperf3 TCP가 1초 단위 0 Bytes 구간이 반복되고 재전송 109회. 연결 설정(SYN)은 정상
- 배제한 원인: 터널 카운터 손실 없음(BGW1 52개 송신, Hub1 52개 수신), 1400바이트 ping 50/50, UDP 200K 0% 손실, 두 번째 터널과 무관
- 결정적 시험: 터널을 거치지 않는 Branch 내부(Host F → Host G)에서도 같은 증상
- 판단: 호스트와 스위치 에뮬레이션이 TCP 버스트를 처리하지 못하는 환경 한계. MSS는 SYN-ACK 캡처로 검증하고 이후 시험은 ping과 UDP로 진행
- 상세: [MTU와 MSS 검증](../verification/br/11-mtu-mss.md)

## 사례 3: 혼잡 시험 중 BGP 세션 단절

- 증상: shaping만 적용한 상태(큐 하나)에서 UDP 800Kbit/sec를 흘리자 `neighbor 10.0.0.12 Down Peer closed the session`, 22.6초 뒤 Up
- 추정 원인: 모든 트래픽이 한 큐라 혼잡 UDP 뒤에서 BGP 유지 패킷이 밀림
- 조치: DSCP CS6, TC 6을 `NETCTRL` 클래스(최소 5%)로 분류. 이후 같은 부하에서 NETCTRL 드롭 0
- 상세: [QoS 검증](../verification/core/08-qos.md)

## 사례 4: 시험 입력 오류

- 시험 문서에 지속 ping 명령을 적을 때 Host A의 대상을 자기 주소로 입력해 공백이 없는 무효 결과가 나옴. 대상 주소를 호스트마다 다시 확인하고 재시험
- PE-CE에서 BGP 요약 명령을 `show ip bgp summary`로 입력해 빈 결과가 나옴. PE는 VPNv4라 `show bgp vpnv4 unicast all summary`를 사용
