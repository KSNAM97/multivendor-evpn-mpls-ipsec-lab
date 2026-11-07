# 4단계: Branch

## 목표

BGW 2대가 PE3의 VRF BR1과 eBGP를 맺고, Host F·G가 DC1(Host A)과 DC2(Host D)와 통신. DC1과 DC2는 서로 통신하지 않음(VRF와 RT, BGW prefix-list로 분리)

## 켜는 노드

Arista 3대(spine1, leaf3, leaf4), Hub1, Hub2, PE1, PE2, PE3, BGW1, BGW2, IOSv 3대(DSW1, DSW2, ASW1), Host A 또는 B, Host F, G. DC2(PE2, CX)를 함께 확인하려면 CX1~3과 Host D도 켬. 약 12GB 예상.

## 순서

시작 전에 Branch의 [VLAN과 IP 계획](../baseline/br/02-vlan-ip.md)을 확인. 값이 다르면 [IP와 포트 매칭표](../00-overview/07-ip-port-matrix.md)가 우선

| 순서 | 할 일 | 참고 문서 | 확인 |
|---|---|---|---|
| 1 | Branch 기본 설정, 관리망 | [샘플: 기본 설정](../samples/br/01-base.md), [비밀번호 위치](../samples/br/13-password.md), [관리망](../samples/br/03-mgmt-access.md) | 콘솔 로그인, SSH |
| 2 | DSW, ASW1 L2: VLAN, MSTP, EtherChannel (ASW1은 L2 전용, SVI 없음) | [기준](../baseline/br/04-mstp-etherchannel.md), [샘플](../samples/br/04-mstp-etherchannel.md) | [검증](../verification/br/04-mstp-etherchannel.md) |
| 3 | SVI와 VRRP (DSW1, DSW2) | [기준](../baseline/br/05-vrrp-svi.md), [샘플](../samples/br/05-vrrp-svi.md) | [검증](../verification/br/05-vrrp-svi.md) |
| 4 | Branch OSPF: BGW와 DSW를 area 0으로 (BGW `Gi0/0`은 제외) | [기준](../baseline/br/06-ospf-branch.md), [샘플](../samples/br/06-ospf-branch.md) | [검증](../verification/br/06-ospf-branch.md): BGW에서 DSW가 FULL |
| 5 | PE3의 VRF BR1과 BGW eBGP (`.100` 서브인터페이스), BGW의 OSPF default | [기준](../baseline/br/07-pe3-bgw-ebgp.md), [샘플](../samples/br/07-pe3-bgw-ebgp.md), PE3 쪽은 [코어 PE-CE 샘플](../samples/core/07-pe-ce-ebgp.md) | [검증](../verification/br/07-pe3-bgw-ebgp.md), [코어 PE-CE 검증](../verification/core/07-pe-ce-ebgp.md): PE3 이웃 Established, DSW에 default |
| 6 | 통신 확인 | [연결 확인](../samples/host/04-connectivity.md) | Host F ↔ Host A, Host F ↔ Host D ping, Host A ↔ Host D는 통신 안 됨 |
| 7 | 저장 | `write memory`, 컨피그를 `configs/br/`에 보관 | |

## 순서의 이유

- 2번(L2)이 먼저여야 3번의 SVI가 올라오고, SVI가 있어야 4번 OSPF에서 Branch LAN이 BGW로 광고됨
- 5번에서 BGW가 자기 대역(192.168.50.0/24, 192.168.60.0/24)을 PE3로 광고하고, PE3 VRF BR1이 DC1(65000:1)과 DC2(65000:2)를 import해서 양쪽 경로가 BGW로 내려옴
- BGW는 자기 대역만 PE3로 내보내서(`prefix-list BR-TO-PARTNER out`), BR1을 거쳐 DC1과 DC2가 서로 통신하지 않음

## 완료 기준

- PE3 - BGW eBGP가 Established
- Host F가 Host A(DC1), Host D(DC2)와 ping이 됨
- Host A와 Host D 사이에는 경로가 없음
