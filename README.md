# Multivendor EVPN-VXLAN / MPLS / IPsec Lab

GNS3 기반 멀티벤더(Cisco, Arista, Aruba) 데이터센터, MPLS 코어, IPsec Branch 실습 프로젝트

## 폴더 구조

상위는 문서 종류, 그 아래가 지역

```text
guide/              단계별 진행 순서 (0 사전 준비 ~ 5 QoS, 06은 Hub 보조 가이드). 처음 하는 사람은 여기서 시작
00-overview/        전체 기준 (토폴로지, 포트 매핑, IP 설계, 프로토콜 매트릭스, 리소스 계획, 기능 지원 확인 결과, VLAN과 IP 대역 총괄, 장비별 IP 포트 매칭표, Wireshark 캡처 계획)
baseline/           기준 문서 (지역별, 프로토콜별로 나눔. 각 폴더의 README가 읽는 순서)
  dc1/  dc2/  core/  br/  host/
configs/            장비별 실제 컨피그
  dc1/  dc2/  core/  br/  host/
samples/            장비별, 프로토콜별 샘플 컨피그 (프로토콜마다 문서를 나눔, 각 폴더의 README가 목차)
  dc1/  dc2/  core/  br/  host/
verification/       검증 (프로토콜별. 선행 조건, 확인 명령, 기대 결과, 안 될 때 확인)
  dc1/  dc2/  core/  br/  host/
```

## 지역 구분

| 폴더 | 지역 | 장비 |
|---|---|---|
| `dc1` | DC1 (Arista 패브릭 + WAN 출구) | spine1, spine2, leaf1~leaf4, Hub1, Hub2 |
| `dc2` | DC2 (Aruba) | CX1, CX2, CX3 |
| `core` | MPLS 코어 | PE1, PE2, PE3 |
| `br` | Branch (Cisco) | BGW1, BGW2, DSW1, DSW2, ASW1 |
| `host` | 테스트 호스트 (Ubuntu Docker Guest) | Host A, B, C(DC1), D(DC2), F, G(Branch) |

## 컨피그 파일 확장자

| 확장자 | OS |
|---|---|
| `.eos` | Arista EOS |
| `.ios` | Cisco IOS (c7200, IOSv) |
| `.aos` | Aruba AOS-CX |
| `.sh` | 호스트 (Ubuntu Docker Guest) |

예: `configs/dc1/spine1.eos`, `configs/core/PE1.ios`, `configs/dc2/CX1.aos`, `configs/host/HOST-A.sh`

## 문서 기준

- 전체 값은 `00-overview`가 기준이고, `baseline/*`은 지역별로 발췌한 것. 값이 다르면 `00-overview`가 우선
- 이 저장소의 계정, enable 비밀번호와 IPsec 사전 공유 키는 **공개된 실습 랩 전용 값**이며 실제 환경에 재사용하지 않음. 키 규칙은 [IPsec 키 관리](baseline/br/08-ipsec-keys.md)
- 지역이나 장비가 추가되면 `baseline`, `configs`, `samples`, `verification` 아래에 같은 이름의 지역 폴더를 만듦
