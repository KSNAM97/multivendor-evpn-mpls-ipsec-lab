# 4단계: Branch와 IPsec

## 목표

Hub와 BGW 사이에 GRE over IPsec 터널 2개가 맺어지고, Host A와 Host F가 통신

## 켜는 노드 (DC2는 끔)

Arista 3대(spine1, leaf3, leaf4), PE1, PE3, Hub1, Hub2, BGW1, BGW2, IOSv 3대(DSW1, DSW2, ASW1), Host A 또는 B, Host F, G. 약 12GB 예상.

## 순서

시작 전에 Branch의 [VLAN과 IP 계획](../baseline/br/02-vlan-ip.md)을 확인. 값이 다르면 [IP와 포트 매칭표](../00-overview/07-ip-port-matrix.md)가 우선

| 순서 | 할 일 | 참고 문서 | 확인 |
|---|---|---|---|
| 1 | Branch와 Hub 기본 설정, 관리망 | [샘플: 기본 설정](../samples/br/01-base.md), [Hub 기본 설정](../samples/dc1/03-base-hub.md), [비밀번호 위치](../samples/br/13-password.md), [관리망](../samples/br/03-mgmt-access.md) | 콘솔 로그인, SSH |
| 2 | DSW, ASW1 L2: VLAN, MSTP, EtherChannel (ASW1은 L2 전용, SVI 없음) | [기준](../baseline/br/04-mstp-etherchannel.md), [샘플](../samples/br/04-mstp-etherchannel.md) | [검증](../verification/br/04-mstp-etherchannel.md) |
| 3 | SVI와 VRRP (DSW1, DSW2) | [기준](../baseline/br/05-vrrp-svi.md), [샘플](../samples/br/05-vrrp-svi.md) | [검증](../verification/br/05-vrrp-svi.md) |
| 4 | Branch OSPF: BGW와 DSW를 area 0으로 (BGW `Gi0/0`은 제외) | [기준](../baseline/br/06-ospf-branch.md), [샘플](../samples/br/06-ospf-branch.md) | [검증](../verification/br/06-ospf-branch.md): BGW에서 DSW가 FULL |
| 5 | PE3 - BGW eBGP (WAN-UL), BGW의 OSPF default | [기준](../baseline/br/07-wan-ebgp.md), [샘플](../samples/br/07-wan-ebgp.md), PE3 쪽은 [코어 PE-CE 샘플](../samples/core/07-pe-ce-ebgp.md) | [검증](../verification/br/07-wan-ebgp.md), [코어 항목 6~11](../verification/core/07-pe-ce-ebgp.md): PE3 이웃 Established, DSW에 default |
| 6 | Hub 언더레이: 정적 경로(BGW 터널 주소 방향) | [Hub 가이드](06-hub.md)의 정적 경로 표 | Hub와 BGW가 서로 `ping 10.0.30.x source gigabitethernet 0/0` |
| 7 | 사전 공유 키 입력 (실습 랩 전용 값) | [키 관리](../baseline/br/08-ipsec-keys.md) | 양쪽 같은 값 |
| 8 | GRE over IPsec | [기준](../baseline/br/09-ipsec-gre.md), [샘플](../samples/br/09-ipsec-gre.md) | [검증](../verification/br/09-ipsec-gre.md): IKE SA, IPsec SA, GRE 터널 |
| 9 | 터널 위 eBGP, MTU와 MSS | [기준](../baseline/br/10-bgp-over-tunnel.md), [샘플](../samples/br/10-bgp-over-tunnel.md) | [eBGP 검증](../verification/br/10-bgp-over-tunnel.md), [MTU 검증](../verification/br/11-mtu-mss.md) |
| 10 | 이중화 장애 시험 | [장애 시험](../verification/br/12-ipsec-failover.md) | 복구 시간 기록 |
| 11 | 저장 | `write memory`, 컨피그를 `configs/br/`에 보관 | |

Hub 설정은 [Hub 설정 가이드](06-hub.md)를 따름

## 순서의 이유

- 2번(L2)이 먼저여야 3번의 SVI가 올라오고, SVI가 있어야 4번 OSPF에서 Branch LAN이 BGW로 광고됨
- 5, 6번(WAN-UL)이 되어야 터널 양끝 주소(10.0.30.x)가 서로 도달되어 8번의 터널이 올라옴
- BGW는 PE3에서 받은 언더레이 경로를 터널 위로 Hub에 광고하지 않도록 `prefix-list NO-UNDERLAY`를 8번에서 함께 적용

## 완료 기준

- 터널 2개가 up이고 터널 위 eBGP가 Established
- Host A와 Host F 사이 ping이 됨
- 이중화 장애 시험으로 감지와 복구 시간을 기록함. 현재 구조는 BGW 한쪽 WAN 장애에서 일부 흐름이 복구되지 않는 한계가 있고 내용은 [장애 시험](../verification/br/12-ipsec-failover.md)에 기록

다음: [5단계 QoS](05-qos.md)
