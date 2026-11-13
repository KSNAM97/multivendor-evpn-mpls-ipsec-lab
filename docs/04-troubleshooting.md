# 트러블슈팅

설계와 다르게 동작했거나 시험 중 문제가 된 항목과 조치

## 요약

| 분류 | 항목 | 조치 |
|---|---|---|
| 장비 한계 | Aruba 가상 이미지에서 LAG(lag10) 위 VLAN 110 데이터가 전달되지 않음(LACP 협상은 정상) | 설계 변경: Host E를 CX1 `1/1/7`에 직접 연결 |
| 장비 한계 | vEOS가 인터페이스 ACL을 지원하지 않음 | 설계 변경: 인터페이스 ACL 대신 Cisco·Aruba에서 시연 |
| 설정 | `lacp rate fast`로 LACP와 VSX ISL이 흔들림 | `no lacp rate`로 slow 복귀 |
| 설정 | AOS-CX VRF의 BGP router-id가 SVI 주소로 선택됨 | `vrf` 하위에 router-id 지정 |
| 설정 | IOSv 포트채널 멤버의 trunk 설정이 서로 달라 묶이지 않음 | `switchport trunk encapsulation dot1q` 포함 같은 설정 |
| 설정 | IOSvL3 물리 포트에 IP와 VRF를 줄 때 거부됨 | `no switchport`를 먼저 입력 |
| 설계 | leaf3·4가 VTEP을 공유하는데 Hub 1대씩만 연결해 Hub 한쪽 경로가 끊기면 트래픽이 블랙홀 | 외부 연결을 전용 border leaf 2대로 분리하고 MLAG 없이 VTEP을 각각 둠 |
| 시험 | 가상 라우터(Dynamips)는 케이블 없이도 인터페이스가 up/up이고 상대가 링크 down을 바로 인식하지 못함 | 링크 장애 감지는 BGP hold 9초가 기준. 시험 결과에 감지 시간이 포함됨 |
| 시험 | PE2 `Gi1/0`을 내린 채로 남겨 PE2 - PE3 경로가 PE1 경유로 보임(Wireshark 캡처에서 발견) | `no shutdown`으로 복구 후 OSPF FULL, VPNv4 이웃 확인 |
| 시험 | 혼잡 시험 중 PE1-PE2 BGP가 22초 끊김 | NETCTRL 클래스 추가 |

## 사례 1: LACP rate fast

- 증상: ISL `lag256`이 `lacp-block`, 상대 Out-Of-Sync, VSX 상태 Out-Of-Sync가 반복됨
- 확인: LACP 상태 화면에서 상대 장비가 Out-Of-Sync로 표시됨([캡처](../verification/dc2/images/04-vsx-lag/wireshark-lacp.png))
- 조치: `lag256`과 `lag10`에서 `no lacp rate` 입력, 이후 안정
- 상세: [VSX LAG 검증](../verification/dc2/04-vsx-lag.md)

## 사례 2: leaf3·4가 Hub 한쪽에만 연결되면 블랙홀

- 증상: PE1 - Hub 링크 한쪽을 내리면 Host A → Host F 통신이 끊기고 복구되지 않음
- 원인: leaf3·4가 VTEP(10.1.1.34)을 공유해서 spine이 어느 leaf로든 트래픽을 보낼 수 있는데, 각 leaf가 Hub 1대에만 연결되어 있었음. Hub 경로가 끊긴 쪽 leaf로 들어온 트래픽이 갈 곳이 없어 블랙홀이 됨
- 1차 조치: leaf3 `Et8` - Hub2 `Gi2/0`, leaf4 `Et8` - Hub1 `Gi2/0` 링크를 추가해 두 leaf를 Hub 2대에 모두 연결(교차 연결)
- 최종 조치: 외부 연결을 전용 border leaf 2대(border-leaf1·Hub1, border-leaf2·Hub2)로 분리하고, MLAG 없이 VTEP을 각각 둠. leaf1~4에서 Hub 링크를 제거
- 결과: Hub 링크 장애 시험에서 T1 손실 0, T1b 손실 47개(약 9.4초 환산) 후 자동 복구
- 상세: [DC1 Hub 검증](../verification/dc1/04-dci-hub-ebgp.md)

## 사례 3: 시험 입력 오류

- 시험 문서에 지속 ping 명령을 적을 때 Host A의 대상을 자기 주소로 입력해 공백이 없는 무효 결과가 나옴. 대상 주소를 호스트마다 다시 확인하고 재시험
- PE-CE에서 BGP 요약 명령을 `show ip bgp summary`로 입력해 빈 결과가 나옴. PE는 VPNv4라 `show bgp vpnv4 unicast all summary`를 사용
