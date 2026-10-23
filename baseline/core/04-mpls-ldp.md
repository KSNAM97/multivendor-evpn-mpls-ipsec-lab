# MPLS와 LDP

PE 3대 사이 코어 링크에서 레이블을 배포하는 단계. 고객 경로(VPNv4)를 레이블로 전달하는 기반

기준 문서: [00-overview](../../00-overview/README.md)

## 개념

| 항목 | 내용 |
|---|---|
| MPLS | IP 헤더 대신 레이블로 포워딩하는 방식. PE 입구에서 레이블을 붙이고(push), 출구에서 뗌(pop) |
| LDP | IGP가 알려준 prefix마다 레이블을 만들어 이웃에 알려주는 프로토콜 |
| 레이블 2개 | 바깥 레이블(전송, LDP)은 상대 PE의 loopback0까지 이동. 안쪽 레이블(VPN, MP-BGP)은 PE가 어느 VRF로 보낼지 지정 |
| P 라우터 | 없음. PE 3대가 직접 연결되어 있어 바깥 레이블은 이웃 PE에 닿는 순간 제거(PHP) |

PHP(penultimate hop popping): 마지막 전 홉이 바깥 레이블을 먼저 제거. 이 코어에서는 상대 PE가 바로 이웃이라 `show mpls forwarding-table`에 `Pop Label`로 보임

## 설계값

| 항목 | 값 |
|---|---|
| 레이블 프로토콜 | LDP (`mpls label protocol ldp`) |
| LDP router-id | `loopback 0` (`force`로 고정) |
| 활성 인터페이스 | 코어 링크 `gigabitethernet 0/0`, `gigabitethernet 1/0`에 `mpls ip` |
| 비활성 인터페이스 | loopback0과 VRF에 속한 링크(Gi2/0 ~ 5/0). 고객 쪽에는 레이블을 보내지 않음 |
| 선행 조건 | OSPF로 loopback0 경로가 서로 보임 |
| 세션 방식 | UDP 646 Hello로 이웃 발견, TCP 646으로 세션. loopback0 주소끼리 연결 |

## 장비별 값

| 장비  | LDP router-id | `mpls ip` 인터페이스 | LDP 이웃                           |
| --- | ------------- | --------------- | -------------------------------- |
| PE1 | 10.0.0.11     | Gi0/0, Gi1/0    | PE2 (10.0.0.12), PE3 (10.0.0.13) |
| PE2 | 10.0.0.12     | Gi0/0, Gi1/0    | PE1 (10.0.0.11), PE3 (10.0.0.13) |
| PE3 | 10.0.0.13     | Gi0/0, Gi1/0    | PE1 (10.0.0.11), PE2 (10.0.0.12) |

## 주의

- LDP 이웃은 OSPF가 loopback0 경로를 배운 뒤에 맺어짐. OSPF가 FULL이 아니면 LDP도 올라오지 않음
- c7200 이미지 IOS 12.4(24)T5는 MPLS와 LDP를 지원(확인됨)
- 링크 MTU 1500에 레이블 4바이트씩 붙음. 이 랩의 호스트 트래픽은 작아서 문제없지만 IPsec 터널 구간 MTU는 [Branch 기준 문서](../br/09-ipsec-gre.md)에서 따로 다룸

## 다음 단계

[VRF](05-vrf.md): 고객별 라우팅 테이블 분리
