# 관리 접속 제한 (ACL) 검증

**선행 조건**: [샘플](../../samples/dc1/10-mgmt-acl.md)의 `MGMT-ACL`이 장비에 적용되어 있고, PC(10.9.0.10)가 관리망(VLAN 900, `10.9.0.0/24`)에 연결되어 있어야 함

기준 문서: [07-mgmt-acl.md](../../baseline/dc1/07-mgmt-acl.md)

## 확인 항목

| 순서 | 장비 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | 적용 장비 | `show ip access-lists MGMT-ACL`, `show running-config section control-plane` | 규칙 10~80이 보이고 `system control-plane` 아래에 `ip access-group MGMT-ACL in`(기본 VRF)과 `ip access-group MGMT-ACL vrf MGMT in`(관리 VRF) | ACL 이름, `system control-plane` 적용 |
| 2 | PC | `ping 10.9.0.21`, `ssh admin@10.9.0.21` | 응답, 로그인 | 관리망 경로, 규칙 10, 20 |
| 3 | 적용 장비 | `show ip access-lists MGMT-ACL` (2번 직후) | 규칙 10, 20의 match 카운터가 올라 있음 | PC 출발 주소가 `10.9.0.0/24`인지 |
| 4 | spine1 | `ssh -l admin 10.1.10.1` (leaf1의 링크 주소로) | **연결 실패**(시간 초과, 허용 목록에 없는 출발 주소 `10.1.10.0`) | 규칙 순서, 적용 위치 |
| 5 | 적용 장비 | `show logging last 30 minutes \| include ACL` | `denied tcp 10.1.10.0(...) -> 10.1.10.1(22)` | deny 규칙의 `log` |
| 6 | leaf1, leaf2 | `show mlag` | **Active, Connected** 유지 | 규칙 60(`10.1.254.0/24`) |
| 7 | 모든 노드 | `show ip ospf neighbor`, `show bgp evpn summary` | OSPF FULL, BGP Established 유지 | 규칙 30, 40, 50 (OSPF, BGP 설정 후 확인) |
| 8 | MGMT-PC, MGMT-SW, leaf1 | PC와 MGMT-SW에서 `ssh -l admin 10.9.0.21`, leaf1에서 `ssh -l admin -vrf MGMT 10.9.0.21` 형식 등 장비 간 시도 | PC, MGMT-SW는 **로그인**, 다른 장비 출발은 **연결 실패**(규칙 15 `deny tcp 10.9.0.0/24 ... log`) | 규칙 10, 11(허용)이 15(차단)보다 앞인지 |

## 장애 시험

| 동작 | 기대 결과 |
|---|---|
| `system control-plane` 아래 `no ip access-group MGMT-ACL vrf MGMT in` | 제한이 풀려 어떤 출발 주소에서도 SSH가 됨 (잠겼을 때 복구용, 콘솔에서 실행) |

## 증빙 (leaf1, 2026-10-22)

### 허용: 관리망 PC에서 접속

![PC에서 leaf1로 ping, SSH](images/05-mgmt-acl/pc-ping-ssh-leaf1.png)

- ping 응답이 `TTL=64`로 오고(첫 요청의 시간 초과는 ARP 확인 중), SSH 로그인까지 됨

### ACL 카운터

![leaf1 MGMT-ACL 카운터](images/05-mgmt-acl/leaf1-acl-counters.png)

- 규칙 10(SSH) 100 packets, 규칙 20(ICMP) 3 packets: PC 접속이 허용 규칙으로 통과
- 규칙 60(MLAG 피어) 2127 packets: leaf2와의 MLAG 통신이 계속 통과
- 규칙 80(deny)에도 일치가 쌓임. 다음 두 로그가 그 내용

### 차단: 허용 목록에 없는 출발 주소

![leaf1 로그: spine1의 SSH 차단](images/05-mgmt-acl/leaf1-log-ssh-denied.png)

- `tcp 10.1.10.0(38168) -> 10.1.10.1(22)`가 `MGMT-ACL`에서 **denied** 됨(재시도까지 모두 차단). spine1의 링크 주소에서 leaf1로 가는 SSH

### 막힌 나머지: DHCP 요청 (정상)

![leaf1 로그: DHCP 요청 차단](images/05-mgmt-acl/leaf1-log-dhcp-denied.png)

- `udp 0.0.0.0(68) -> 255.255.255.255(67)`은 설정이 없는 vEOS(ZTP)가 보내는 DHCP 요청. 우리가 쓰지 않는 트래픽이라 막혀도 영향이 없음

## 증빙 (spine1, spine2, leaf2~4, 2026-10-22)

### 관리망 PC에서 6대 접속 확인

![PC에서 6대 ping, SSH 포트 확인](images/05-mgmt-acl/pc-ping-ssh-all.png)

- 192.168.100.11, .12, .21, .22, .23, .24가 모두 `ping=True`, `ssh22=True`

### 장비별 ACL 적용 상태

| 장비 | 화면 | 볼 곳 |
|---|---|---|
| leaf2 | ![leaf2 ACL](images/05-mgmt-acl/leaf2-acl.png) | 규칙 10~80, `ip access-group MGMT-ACL in`, 규칙 60(MLAG) 199 packets |
| leaf3 | ![leaf3 ACL](images/05-mgmt-acl/leaf3-acl.png) | 같은 내용, 규칙 60 199 packets |
| leaf4 | ![leaf4 ACL](images/05-mgmt-acl/leaf4-acl.png) | 같은 내용, 규칙 60 177 packets |
| spine1 | ![spine1 ACL](images/05-mgmt-acl/spine1-acl.png) | 규칙 10, 20에 PC 접속 카운터 |
| spine2 | ![spine2 ACL](images/05-mgmt-acl/spine2-acl.png) | 규칙 10, 20에 PC 접속 카운터 |

- leaf2~4의 규칙 80(deny)은 1~2 packets로 작음. 설정이 없는 장비의 DHCP 요청 정도이고 정상
- leaf1~4 모두 `show mlag`가 **Active, Connected**, `peer-config: consistent`로 유지됨(leaf1 MLAG1, leaf2 MLAG1, leaf3 MLAG2, leaf4 MLAG2).
### 차단: spine에서 leaf로 SSH (허용 목록에 없는 출발 주소)

| 출발 | 대상 | 화면 |
|---|---|---|
| spine1 (10.1.10.6) | leaf4 (10.1.10.7) | ![spine1 to leaf4 ssh](images/05-mgmt-acl/spine1-ssh-leaf4-denied.png) |
| spine2 (10.1.10.10) | leaf2 (10.1.10.11) | ![spine2 to leaf2 ssh](images/05-mgmt-acl/spine2-ssh-leaf2-denied.png) |
| spine2 (10.1.10.12) | leaf3 (10.1.10.13) | ![spine2 to leaf3 ssh](images/05-mgmt-acl/spine2-ssh-leaf3-denied.png) |

- 세 경우 모두 `Connection timed out`. leaf1은 로그(`denied tcp 10.1.10.0 -> 10.1.10.1(22)`)로 확인됨. leaf1~4 모두 차단이 동작
## 증빙 (관리망 10.9.0.0/24 재구성, SVI 방식, 8대, 2026-11-14)

관리망을 192.168.100.0/24에서 `10.9.0.0/24`(VLAN 900, MGMT-SW `Vlan900` 10.9.0.2)로 바꾸고, Arista 관리 인터페이스를 `vrf MGMT`로 분리한 뒤 확인함. 게이트웨이(라우터) 없이 같은 서브넷에서 접속. 8대 전부 확인함. 기본 VRF 줄(`ip access-group MGMT-ACL in`)을 지웠다가 복원한 뒤 차단 시험과 OSPF, BGP, MLAG를 다시 확인함.

### MGMT-SW: VLAN 900과 Vlan900

![MGMT-SW VLAN 900, Vlan900](images/05-mgmt-acl/mgmtsw-vlan-ip-1114.png)

- VLAN 900에 Gi0/0~3, Gi1/0~3, Gi3/3이 속하고, `Vlan900`이 `10.9.0.2`로 up/up

### spine1: Management1

![spine1 Management1 10.9.0.11](images/05-mgmt-acl/spine1-mgmt1-ip-1114.png)

- `Management1`이 `10.9.0.11/24`, up/up

### 허용: 관리망 PC에서 접속

![PC에서 spine1로 ping, SSH](images/05-mgmt-acl/pc-ping-ssh-spine1-1114.png)

- 10.9.0.11로 ping 3개 전송, 3개 수신, 손실 0%. SSH 로그인까지 됨(`SPINE1>`)

### ACL 카운터와 control-plane 적용

![spine1 MGMT-ACL 카운터, control-plane](images/05-mgmt-acl/spine1-acl-vrf-1114.png)

- 규칙 20(ICMP) 3 packets(ping 3개와 일치), 규칙 10(SSH) 29 packets
- `system control-plane` 아래 `ip access-group MGMT-ACL in`(기본 VRF)과 `ip access-group MGMT-ACL vrf MGMT in`(VRF MGMT) 두 줄이 적용되어, VRF로 들어온 트래픽에 ACL 카운터가 올라감

### 8대 접속과 카운터

![PC에서 8대 포트 22 확인](images/05-mgmt-acl/pc-ssh-open-all.png)

- 10.9.0.11, .12, .21~.26이 모두 `ssh-open`. ping 8대도 손실 0%

| 장비 | Management1, control-plane | ACL 카운터 (접속 후) |
|---|---|---|
| spine1 | ![](images/05-mgmt-acl/spine1-ip-cp.png) | ![](images/05-mgmt-acl/spine1-acl-after.png) |
| spine2 | ![](images/05-mgmt-acl/spine2-ip-cp.png) | ![](images/05-mgmt-acl/spine2-acl-after.png) |
| leaf1 | ![](images/05-mgmt-acl/leaf1-ip-cp.png) | ![](images/05-mgmt-acl/leaf1-acl-after.png) |
| leaf2 | ![](images/05-mgmt-acl/leaf2-ip-cp.png) | ![](images/05-mgmt-acl/leaf2-acl-after.png) |
| leaf3 | ![](images/05-mgmt-acl/leaf3-ip-cp.png) | ![](images/05-mgmt-acl/leaf3-acl-after.png) |
| leaf4 | ![](images/05-mgmt-acl/leaf4-ip-cp.png) | ![](images/05-mgmt-acl/leaf4-acl-after.png) |
| border-leaf1 | ![](images/05-mgmt-acl/border-leaf1-ip-cp.png) | ![](images/05-mgmt-acl/border-leaf1-acl-after.png) |
| border-leaf2 | ![](images/05-mgmt-acl/border-leaf2-ip-cp.png) | ![](images/05-mgmt-acl/border-leaf2-acl-after.png) |

- `Management1`이 10.9.0.11, .12, .21~.26(up/up). 왼쪽 화면의 control-plane 줄은 기본 VRF 줄 복원 전의 캡처라 `vrf MGMT in` 한 줄만 보임
- 규칙 20(ICMP)은 ping 2개(spine1은 이전 3개 포함 5), 규칙 10(SSH)은 포트 점검 접속만큼 올라 있음

### 복원 후 차단 시험

![spine1에서 leaf1로 SSH 시간 초과](images/05-mgmt-acl/spine1-ssh-leaf1-timeout-1114.png)

![leaf1 로그: 차단](images/05-mgmt-acl/leaf1-log-ssh-denied-1114.png)

- spine1(10.1.10.0) → leaf1(10.1.10.1) SSH가 `Connection timed out`, leaf1 로그에 `list MGMT-ACL denied tcp 10.1.10.0(51606) -> 10.1.10.1(22)`. 기본 VRF 줄을 지운 상태에서는 이 줄이 없어 차단이 보장되지 않음

### 기존 서비스 유지 (OSPF, BGP, MLAG)

| 장비 | OSPF, BGP EVPN |
|---|---|
| spine1 | ![](images/05-mgmt-acl/spine1-ospf-bgp.png) |
| spine2 | ![](images/05-mgmt-acl/spine2-ospf-bgp.png) |
| leaf1 | ![](images/05-mgmt-acl/leaf1-ospf-bgp.png) |
| leaf2 | ![](images/05-mgmt-acl/leaf2-ospf-bgp.png) |
| leaf3 | ![](images/05-mgmt-acl/leaf3-ospf-bgp.png) |
| leaf4 | ![](images/05-mgmt-acl/leaf4-ospf-bgp.png) |
| border-leaf1 | ![](images/05-mgmt-acl/border-leaf1-ospf-bgp.png) |
| border-leaf2 | ![](images/05-mgmt-acl/border-leaf2-ospf-bgp.png) |

- 모든 장비에서 OSPF 이웃 FULL, BGP EVPN Established(spine 6개, leaf 2개 30 prefix, border-leaf 2개 35 prefix)

![leaf1 MLAG](images/05-mgmt-acl/leaf1-mlag-1114.png)

![leaf2 MLAG](images/05-mgmt-acl/leaf2-mlag-1114.png)

![leaf3 MLAG](images/05-mgmt-acl/leaf3-mlag-1114.png)

![leaf4 MLAG](images/05-mgmt-acl/leaf4-mlag-1114.png)

- leaf1~4(MLAG1, MLAG2) 모두 `Active, Connected`, `peer-config: consistent`

### SSH 허용 대상 제한 (규칙 10, 11, 15, spine1, 2026-11-14)

SSH는 관리 PC(`10.9.0.10`)와 MGMT-SW(`10.9.0.2`)에서만 허용하고, 관리망의 나머지 장비에서 오는 SSH는 규칙 15로 차단. leaf1에서 `10.9.0.0/24` 전체 허용 규칙 10을 `host 10.9.0.10`으로 바꾼 상태의 ACL

![leaf1 MGMT-ACL 순서](images/05-mgmt-acl/leaf1-acl-rule10-15.png)

- 순서가 10(`host 10.9.0.10`), 11(`host 10.9.0.2`), 15(`deny tcp 10.9.0.0/24 ... log`), 20(ICMP)

| 출발 | 대상 | 화면 |
|---|---|---|
| MGMT-PC | spine1 | ![PC SSH](images/05-mgmt-acl/pc-ssh-spine1-rule10.png) |
| MGMT-SW | spine1 | ![MGMT-SW SSH](images/05-mgmt-acl/mgmtsw-ssh-spine1-rule11.png) |
| leaf1 (VRF MGMT, `bash`에서 `sudo ip netns exec ns-MGMT ssh admin@10.9.0.11`) | spine1 | ![leaf1 SSH 시도](images/05-mgmt-acl/leaf1-bash-ssh-spine1.png) |

- PC와 MGMT-SW는 로그인됨. leaf1에서의 SSH는 접속되지 않고 대기함

![spine1 MGMT-ACL 카운터](images/05-mgmt-acl/spine1-acl-rule15-match.png)

- 규칙 10(PC) 23 packets, 규칙 11(MGMT-SW) 30 packets, **규칙 15(차단) 4 packets**(leaf1 시도 직후). 장비 간 SSH는 막히고 PC, MGMT-SW는 허용됨
- spine1에서 확인한 뒤, 차단 로그와 8대의 ACL 순서까지 확인함

### 장비 간 SSH 차단 확인

![leaf1에서 spine1로 SSH 시간 초과](images/05-mgmt-acl/leaf1-ssh-spine1-timeout-1114.png)

![spine1 로그: leaf1의 SSH 차단](images/05-mgmt-acl/spine1-log-ssh-denied-leaf1-1114.png)

- leaf1(VRF MGMT)에서 spine1로 SSH가 `Connection timed out`. spine1 로그에 `list MGMT-ACL denied tcp 10.9.0.21(60182) -> 10.9.0.11(22)`가 5건 남음(규칙 15 카운터 5 packets와 일치)

### 8대 ACL 순서

| 장비 | 화면 |
|---|---|
| spine1 | ![](images/05-mgmt-acl/spine1-acl-order.png) |
| spine2 | ![](images/05-mgmt-acl/spine2-acl-order.png) |
| leaf1 | ![](images/05-mgmt-acl/leaf1-acl-order.png) |
| leaf2 | ![](images/05-mgmt-acl/leaf2-acl-order.png) |
| leaf3 | ![](images/05-mgmt-acl/leaf3-acl-order.png) |
| leaf4 | ![](images/05-mgmt-acl/leaf4-acl-order.png) |
| border-leaf1 | ![](images/05-mgmt-acl/border-leaf1-acl-order.png) |
| border-leaf2 | ![](images/05-mgmt-acl/border-leaf2-acl-order.png) |

- 8대 모두 10(`host 10.9.0.10`), 11(`host 10.9.0.2`), 15(`deny tcp 10.9.0.0/24 ... log`), 20(ICMP) 순서. border-leaf는 MLAG 피어가 없어 규칙 60(MLAG)이 없고, 장비 간 ICMP가 60번, deny가 70번

### 관리 VRF 기본 경로와 MGMT-SW1 (MGMT-RTR 추가 후, 2026-11-14)

MGMT-RTR(게이트웨이 10.9.0.1)을 추가하고 Arista 8대의 `vrf MGMT`에 기본 경로를 넣은 뒤 확인함. 장비 이름은 MGMT-SW에서 MGMT-SW1로 바뀜

| 장비 | `show ip route vrf MGMT` |
|---|---|
| spine1 | ![](images/05-mgmt-acl/spine1-vrf-mgmt-route.png) |
| spine2 | ![](images/05-mgmt-acl/spine2-vrf-mgmt-route.png) |
| leaf1 | ![](images/05-mgmt-acl/leaf1-vrf-mgmt-route.png) |
| leaf2 | ![](images/05-mgmt-acl/leaf2-vrf-mgmt-route.png) |
| leaf3 | ![](images/05-mgmt-acl/leaf3-vrf-mgmt-route.png) |
| leaf4 | ![](images/05-mgmt-acl/leaf4-vrf-mgmt-route.png) |
| border-leaf1 | ![](images/05-mgmt-acl/border-leaf1-vrf-mgmt-route.png) |
| border-leaf2 | ![](images/05-mgmt-acl/border-leaf2-vrf-mgmt-route.png) |

- 8대 모두 `S 0.0.0.0/0 via 10.9.0.1, Management1`, `C 10.9.0.0/24 Management1`. 아래에 `! IP routing not enabled`가 나오는 것은 관리 VRF에서 전달(라우팅)을 쓰지 않기 때문이며 관리 접속에는 영향 없음

![MGMT-SW1 VLAN 900](images/05-mgmt-acl/mgmt-sw1-vlan.png)

![MGMT-SW1 인터페이스](images/05-mgmt-acl/mgmt-sw1-ip.png)

- VLAN 900에 Gi0/0~0/3, Gi1/0~1/3, **Gi3/2(MGMT-RTR)**, Gi3/3(MGMT-PC1)이 속하고 `Vlan900` 10.9.0.2 up/up. 코어 관리망과 MGMT-RTR은 [코어 관리 검증](../core/08-mgmt.md) 참조

## 결과 기록

| 일시 | 결과 (성공, 실패) | 비고 |
|---|---|---|
| 2026-10-22 | 성공 (leaf1~4, spine1, spine2) | 적용, 관리망 접속, MLAG 유지, spine 출발 SSH 차단(leaf1~4) 모두 확인. OSPF, BGP 유지(7번)는 설정 후 확인 |
| 2026-11-14 | 성공 (8대) | 관리망 10.9.0.0/24, SVI 방식, `vrf MGMT` 적용. 접속, ACL 카운터, spine1에서 leaf1 SSH 차단, OSPF, BGP, MLAG(leaf1~4) 모두 확인 |
| 2026-11-14 | 성공 (8대) | 8번(SSH를 관리 PC, MGMT-SW만 허용) | 규칙 10, 11, 15 적용(8대 ACL 순서 확인). PC, MGMT-SW 로그인, leaf1 출발 SSH는 시간 초과와 차단 로그로 확인. 나머지 장비 출발 차단은 같은 규칙이라 개별 시험은 안 함 |
