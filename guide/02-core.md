# 2단계: MPLS 코어와 DC1 연동

## 목표

PE1이 VRF 경로를 학습하고, DC1 border leaf와 PE1 사이 eBGP가 맺어짐.

## 켜는 노드

1단계 노드 + PE1, PE2, PE3 (c7200은 2~3대씩 켜기).

## 순서

시작 전에 코어의 [VLAN과 IP 계획](../baseline/core/02-ip.md)을 확인

| 순서 | 할 일 | 참고 문서 | 확인 |
|---|---|---|---|
| 1 | PE 기본 설정(이름, 권한 모드, domain-lookup, 배너) | [기준](../baseline/core/01-overview.md), [샘플](../samples/core/01-base.md), [비밀번호 위치](../samples/core/09-password.md) | [검증](../verification/core/01-base.md) |
| 2 | 인터페이스 IP (loopback0, 링크, VRF 소속) | [기준](../baseline/core/02-ip.md), [샘플](../samples/core/02-ip.md) | [검증](../verification/core/02-interface-ip.md) |
| 3 | OSPF (코어 링크와 loopback0) | [기준](../baseline/core/03-ospf.md), [샘플](../samples/core/03-ospf.md) | [검증](../verification/core/03-ospf.md) |
| 4 | MPLS와 LDP (코어 링크) | [기준](../baseline/core/04-mpls-ldp.md), [샘플](../samples/core/04-mpls-ldp.md) | [검증](../verification/core/04-mpls-ldp.md) |
| 5 | VRF (RD, route-target) | [기준](../baseline/core/05-vrf.md), [샘플](../samples/core/05-vrf.md) | [검증](../verification/core/05-vrf.md) |
| 6 | MP-BGP VPNv4 (PE 간 iBGP) | [기준](../baseline/core/06-mp-bgp-vpnv4.md), [샘플](../samples/core/06-mp-bgp-vpnv4.md) | [검증](../verification/core/06-mp-bgp-vpnv4.md) |
| 7 | PE-CE eBGP (DC1 border leaf와 PE1, DC2와 PE2. 양쪽 설정) | [기준](../baseline/core/07-pe-ce-ebgp.md), [PE 샘플](../samples/core/07-pe-ce-ebgp.md), [leaf 샘플](../samples/dc1/09-pe-ce-ebgp.md) | [검증](../verification/core/07-pe-ce-ebgp.md), [DC1 검증](../verification/dc1/04-dci-hub-ebgp.md) |
| 8 | 저장 | `write memory`, 컨피그를 `configs/core/`에 보관 | |
Hub 설정은 [Hub 설정 가이드](06-hub.md)를 따름

## 완료 기준

- PE 간 OSPF, LDP, VPNv4 세션이 정상 (구축 순서 1 ~ 6 검증 통과)
- PE1의 TENANT-A VRF에 DC1 경로가 보임

다음: [3단계 DC2](03-dc2.md)
