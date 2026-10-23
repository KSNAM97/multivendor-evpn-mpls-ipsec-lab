# MP-BGP VPNv4

VRF 경로를 PE 사이에서 교환하는 단계. 코어 안은 iBGP

기준 문서: [00-overview](../../00-overview/README.md)

## iBGP VPNv4

| 항목 | 값 |
|---|---|
| AS | 65000 |
| 세션 | PE1, PE2, PE3 full mesh (Loopback0 기준, `update-source loopback 0`) |
| BGP router-id | PE1 10.0.1.11, PE2 10.0.1.12, PE3 10.0.1.13 (OSPF router-id 10.0.0.11 ~ 10.0.0.13과 다름) |
| keepalive, hold | **3초, 9초** (DC1과 통일, 기본 60초, 180초) |
| 주소 패밀리 | vpnv4 (`send-community extended` 필요: RT 전달) |
| 선행 조건 | [OSPF](03-ospf.md)로 loopback0 경로, [LDP](04-mpls-ldp.md)로 레이블, [VRF](05-vrf.md)의 RD와 RT |
| 비고 | 코어 안은 iBGP VPNv4 (DC1의 EVPN도 iBGP Route Reflector) |

## 장비별 이웃

| 장비 | 이웃 (loopback0) |
|---|---|
| PE1 | 10.0.0.12 (PE2), 10.0.0.13 (PE3) |
| PE2 | 10.0.0.11 (PE1), 10.0.0.13 (PE3) |
| PE3 | 10.0.0.11 (PE1), 10.0.0.12 (PE2) |

- 이웃 주소는 BGP router-id(10.0.1.x)가 아니라 loopback0 주소(10.0.0.x)를 사용. router-id는 식별자일 뿐 라우팅되는 주소가 아님
- PE 3대뿐이라 Route Reflector 없이 full mesh로 구성

## 다음 단계

[PE-CE eBGP](07-pe-ce-ebgp.md): 고객 장비와 VRF 안에서 경로 교환
