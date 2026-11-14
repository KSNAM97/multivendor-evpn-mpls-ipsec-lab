# DC1 동시 부하 시험 (Spine ECMP)

**목적**: DC1에서 부하를 걸었을 때 경로가 어떻게 나뉘는지 확인. DC1의 MSTP는 L2 인스턴스 매핑이고, Leaf - Spine 업링크는 L3(OSPF, ECMP)이므로 이 시험은 MSTP가 아니라 업링크 분산을 본 것

**방법**: Host A, Host B에서 `iperf3 -u -b <속도> -l 1000 -t 30`으로 UDP를 보내고, Leaf1 업링크(`Ethernet1` = Spine1 쪽, `Ethernet2` = Spine2 쪽)의 `packets output`을 전후 비교. 이 환경의 처리 한계가 약 275 ~ 300 Kbit/s 부근이라 낮은 속도를 씀(TCP는 개발지사 시험과 같은 이유로 제외)

## MSTP 설정 (참고)

![MST 설정](images/10-load/mst-config.png)

- region `DC1`, revision 1, 인스턴스 1 = VLAN 10·20, 인스턴스 2 = VLAN 30·99. 두 인스턴스의 priority는 모두 4096이라 인스턴스별로 root를 나눠 경로를 갈라놓는 설계가 아님

## 시험 1: Host A -> C, Host B -> D (각 300 Kbit/s, 서로 다른 Leaf)

| 포트 | output 전 | output 후 | 증가 |
|---|---|---|---|
| Leaf1 Ethernet1 | 1,126 packets | 2,509 packets | +1,383 packets |
| Leaf1 Ethernet2 | 1,290 packets | 1,514 packets | +224 packets |

- Host A, Host B 모두 1,125개 중 0% 손실로 수신(Host B는 Leaf2 연결이라 Leaf1 카운터에는 Host A 흐름만 나타남). Host A 흐름은 Ethernet1 한 곳에 실림(Ethernet2 증가는 배경 수준)

![Leaf1 Ethernet1 전](images/10-load/leaf1-eth1-before-t1.png)

![Leaf1 Ethernet2 전](images/10-load/leaf1-eth2-before-t1.png)

![Leaf1 후](images/10-load/leaf1-after-t1.png)

![Host A 클라이언트](images/10-load/hosta-client-t1.png)

![Host B 클라이언트](images/10-load/hostb-client-t1.png)

![Host C 서버](images/10-load/hostc-server-t1.png)

![Host D 서버](images/10-load/hostd-server-t1.png)

## 시험 2: Host A -> C, 출발 포트가 다른 4개 흐름 (`-P 4`, 각 100 Kbit/s)

| 포트 | output 전 | output 후 | 증가 |
|---|---|---|---|
| Leaf1 Ethernet1 | 2,676 packets | 4,078 packets | +1,402 packets |
| Leaf1 Ethernet2 | 1,685 packets | 1,947 packets | +262 packets |

- 4개 흐름이 모두 Ethernet1로 나감. 합계 400 Kbit/s가 한계를 넘어 29% 손실(433/1500), 지터 약 510ms라 분산 판정에는 쓰지 않음

![-P 4 결과](images/10-load/hosta-p4-result-t2.png)

![Leaf1 전](images/10-load/leaf1-before-t2.png)

![Leaf1 후](images/10-load/leaf1-after-t2.png)

## 시험 3: Host A -> C, Host A -> D (목적지 IP가 다른 두 흐름, 각 100 Kbit/s)

| 포트 | output 전 | output 후 | 증가 |
|---|---|---|---|
| Leaf1 Ethernet1 | 4,160 packets | 5,944 packets | +1,784 packets |
| Leaf1 Ethernet2 | 2,032 packets | 2,362 packets | +330 packets |

- 두 흐름 모두 375개 중 0% 손실(지터 약 45 ~ 48ms). 두 흐름 모두 Ethernet1로 나감. 증가량이 두 흐름 합(약 750 packets)보다 큰 것은 붙여 넣기 실패 때 명령이 일부 중복 실행되었을 가능성으로 보이며 확인하지 못함

![Leaf1 전](images/10-load/leaf1-before-t3.png)

![Leaf1 후](images/10-load/leaf1-after-t3.png)

![Host C 서버](images/10-load/hostc-server-t3.png)

![Host D 서버](images/10-load/hostd-server-t3.png)

## 해석

- Leaf1은 Host, 포트, 목적지 IP와 관계없이 이 시험의 흐름을 모두 한 업링크(Spine1 쪽)로 보냄. Host A의 흐름은 모두 Leaf3·4 VTEP(10.1.1.34)로 가는 VXLAN이라 바깥 IP 쌍이 같음. 이 가상 환경(소프트웨어 포워딩)에서 ECMP 해시가 바깥 IP 쌍 중심이면 같은 VTEP 쌍은 같은 경로로 가므로 위 결과와 맞지만, 해시 방식은 확인하지 못함
- Leaf - Spine 구간은 L3 링크라 MSTP는 업링크 선택에 관여하지 않음. DC1의 MSTP로는 부하 분산을 보일 수 없고, VLAN별 경로 분산은 개발지사의 rapid-pvst에서 확인함([개발지사 RSTP 검증](../br/04-mstp-etherchannel.md))
- 서로 다른 VTEP 목적지(예: Host C와 Border Leaf 방향)로 가는 흐름에서 분산이 나타나는지는 시험하지 않음

## 결과 기록

| 일시 | 결과 (성공, 실패) | 비고 |
|---|---|---|
| 2026-11-14 | 성공 (3회) | 모든 시험에서 단일 업링크 사용. 분산은 확인하지 못함(해시 가설, 서로 다른 VTEP 목적지는 시험 안 함) |
