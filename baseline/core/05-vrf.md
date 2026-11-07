# VRF

고객(DC1, DC2, Branch)별로 라우팅 테이블을 분리하는 단계. 코어 OSPF와 LDP는 global 테이블에서만 동작

기준 문서: [00-overview](../../00-overview/README.md)

## VRF 정의

| VRF      | 용도     | RD      | RT export | RT import                 | 정의하는 장비 |
| -------- | ------ | ------- | --------- | ------------------------- | ------- |
| TENANT-A | DC1    | 65000:1 | 65000:1   | 65000:1, 65000:3          | PE1     |
| PARTNER  | DC2    | 65000:2 | 65000:2   | 65000:2, 65000:3          | PE2     |
| BR1      | Branch | 65000:3 | 65000:3   | 65000:1, 65000:2, 65000:3 | PE3     |

- DC1(TENANT-A)과 DC2(PARTNER)는 서로의 RT를 import하지 않아 경로가 섞이지 않음. BR1만 양쪽을 import해서 Branch가 DC1, DC2와 통신
- DC1과 DC2는 물리적으로 분리되지 않고 VRF와 RT, BGW의 prefix-list로 논리적으로 분리됨 ([PE3 - BGW eBGP](../br/07-pe3-bgw-ebgp.md))

- RD: PE마다 같은 VRF의 경로를 구분하는 값. VPNv4 주소에 붙음
- RT: 어느 VRF가 경로를 가져가고 내보낼지 정하는 값. 같은 VRF끼리 같은 값
- VRF 이름 정의와 인터페이스 소속은 [인터페이스 IP](02-ip.md) 단계에서 이미 입력. 이 단계에서는 `rd`와 `route-target`을 추가
- RD와 RT는 VPNv4 단계([MP-BGP VPNv4](06-mp-bgp-vpnv4.md))가 되어야 쓰임

## 인터페이스 소속

| 장비      | 인터페이스                   | VRF             | 상대           |
| ------- | ----------------------- | --------------- | ------------ |
| PE1     | Gi4/0, Gi5/0            | TENANT-A        | Hub1, Hub2   |
| PE2     | Gi2/0, Gi3/0            | PARTNER         | CX1, CX2     |
| PE3     | Gi2/0.100, Gi3/0.100    | BR1             | BGW1, BGW2   |
| PE1~PE3 | Gi0/0, Gi1/0, loopback0 | global (VRF 없음) | 코어           |

## 작성 규칙

- 인터페이스에서 `ip vrf forwarding`을 **먼저** 넣고 `ip address`를 나중에 넣음. 순서가 바뀌면 `ip vrf forwarding` 입력 때 IP가 지워짐
- c7200 IOS 12.4는 `ip vrf`, IOS 15.x는 `vrf definition`을 사용
- global은 VRF가 아니라 기본 라우팅 테이블. `ip vrf global` 또는 `ip vrf forwarding global`은 쓰지 않음

## 다음 단계

[MP-BGP VPNv4](06-mp-bgp-vpnv4.md): VRF 경로를 PE 사이에서 교환
