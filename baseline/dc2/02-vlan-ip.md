# DC2 VLAN과 IP

장비별 포트와 IP 전체: [IP와 포트 매칭표](../../00-overview/07-ip-port-matrix.md)

DC2(Aruba)의 VLAN과 IP 대역

기준 문서: [00-overview/06-vlan-ip-plan](../../00-overview/06-vlan-ip-plan.md)

## VLAN

| VLAN | 이름      | 서브넷              | 게이트웨이                                           | 호스트         |
| ---- | ------- | ---------------- | ----------------------------------------------- | ----------- |
| 110  | APP-DC2 | 192.168.110.0/24 | .1 (VSX active gateway), CX1 SVI .2, CX2 SVI .3 | Host D .101 |

- VRF `TENANT-A`
- DC2는 VXLAN이 없어서 L2VNI(10110)는 예약만 하고 쓰지 않음
- VLAN 999는 모든 트렁크의 네이티브 VLAN임(호스트, SVI 없음). 트렁크가 있는 장비마다 `vlan 999`를 만들고 트렁크에 `native vlan 999`를 지정. 10.99.0.0/16 대역은 기능 시험 전용

## 관리와 루프백

| 노드 | Mgmt (192.168.100.0/24) | Loopback0 | 비고 |
|---|---|---|---|
| CX1 | .41 | 10.2.0.1/32 | VSX 쌍 |
| CX2 | .42 | 10.2.0.2/32 | VSX 쌍 |
| CX3 | .43 | - | L2 전용 (access) |

## 링크 주소

| 용도                        | 서브넷           | A측     | B측     | VRF       |
| ------------------------- | ------------- | ------ | ------ | --------- |
| PE2 - CX1 (DCI)           | 10.0.20.4/31  | PE2 .4 | CX1 .5 | TENANT-A  |
| PE2 - CX2 (DCI)           | 10.0.20.6/31  | PE2 .6 | CX2 .7 | TENANT-A  |
| CX1 - CX2 (VSX keepalive) | 10.2.254.0/31 | CX1 .0 | CX2 .1 | KEEPALIVE |

## AS

| 노드 | AS |
|---|---|
| CX1, CX2 | 65201 |

## 미사용 대역

- 10.2.1.0/24 (VTEP), 10.2.10.0/24 (spine 링크): DC2에 VXLAN과 spine이 없어서 쓰지 않음

## VLAN이 있는 장비

| VLAN | 장비 |
|---|---|
| 110 | CX1, CX2 (SVI .2/.3, active gateway .1), CX3 (L2 trunk). Host D access 포트는 CX1 `1/1/7` |

## 장비별 포트와 IP

| 장비  | 포트                | IP                            | 상대                           |
| --- | ----------------- | ----------------------------- | ---------------------------- |
| CX1 | 1/1/1             | 10.0.20.5/31                  | PE2 Gi2/0                    |
| CX1 | lag 256 (1/1/2-3) | VSX ISL                       | CX2 1/1/2-3                  |
| CX1 | 1/1/4             | 10.2.254.0/31 (VRF KEEPALIVE) | CX2 1/1/4                    |
| CX1 | lag 10 (1/1/5-6)  | L2 trunk, multi-chassis       | CX3 1/1/1-2                  |
| CX2 | 1/1/1             | 10.0.20.7/31                  | PE2 Gi3/0                    |
| CX2 | lag 256 (1/1/2-3) | VSX ISL                       | CX1 1/1/2-3                  |
| CX2 | 1/1/4             | 10.2.254.1/31 (VRF KEEPALIVE) | CX1 1/1/4                    |
| CX2 | lag 10 (1/1/5-6)  | L2 trunk, multi-chassis       | CX3 1/1/3-4                  |
| CX3 | lag 10 (1/1/1-4)  | L2 trunk                      | CX1 (1/1/5-6), CX2 (1/1/5-6) |
| CX1 | 1/1/7             | L2 access (VLAN 110)          | Host D eth1                  |
| CX3 | 1/1/5             | L2 access (VLAN 110, 미사용)    | Host D eth0                  |

Loopback1은 없음(DC2는 VXLAN 없음). CX1, CX2의 Loopback0만 router-id
