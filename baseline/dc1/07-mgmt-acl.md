# 관리 접속 제한 (ACL)

장비 관리 접속을 관리망으로 제한하는 설계. SSH는 관리 PC(MGMT-PC)와 관리 스위치(MGMT-SW1)에서만 허용

샘플: [10-mgmt-acl.md](../../samples/dc1/10-mgmt-acl.md)

## 설계값

| 항목 | 값 |
|---|---|
| ACL 이름 | `MGMT-ACL` |
| 방식 | control-plane ACL. `system control-plane`에 기본 VRF용(`ip access-group MGMT-ACL in`)과 관리 VRF용(`ip access-group MGMT-ACL vrf MGMT in`) 두 줄로 적용 |
| 관리 인터페이스 | `Management1`을 `vrf MGMT`에 두고 `10.9.0.x/24`(MGMT-SW1 VLAN 900, SVI 방식, 게이트웨이 없음) |
| 허용 출발 주소 | SSH는 관리 PC `10.9.0.10`과 MGMT-SW1 `10.9.0.2`만, ICMP는 관리망 `10.9.0.0/24` |
| 같이 허용 | OSPF, BGP(`10.1.0.0/24` 루프백끼리), MLAG 피어(`10.1.254.0/24`), 장비 간 ICMP(`10.0.0.0/8`) |
| 차단 | 그 밖의 모든 IP (`deny ip any any log`) |

## 규칙

| 순서 | 동작 | 대상 | 용도 |
|---|---|---|---|
| 10 | permit | tcp `10.9.0.10` -> SSH(22) | 관리 PC만 SSH |
| 11 | permit | tcp `10.9.0.2` -> SSH(22) | 관리 스위치 SSH |
| 15 | deny | tcp `10.9.0.0/24` -> SSH(22) (log) | 그 밖의 관리망 장비 간 SSH 차단 |
| 20 | permit | icmp `10.9.0.0/24` | 관리망 ping |
| 30 | permit | ospf any any | 언더레이 이웃 |
| 40 | permit | tcp `10.1.0.0/24` -> BGP(179) | EVPN 이웃(요청) |
| 50 | permit | tcp `10.1.0.0/24` 출발 BGP(179) | EVPN 이웃(응답) |
| 60 | permit | ip `10.1.254.0/24` | MLAG 피어 통신 (border-leaf1, 2에는 없음) |
| 70 | permit | icmp `10.0.0.0/8` | 장비 간 ping 확인 |
| 80 | deny | ip any any (log) | 나머지 차단 |

## 적용 장비

| 장비 | 관리 IP | 적용 방식 | 상태 (2026-10-22) |
|---|---|---|---|
| leaf1 | 10.9.0.21 | control-plane ACL `MGMT-ACL` | **적용과 검증 완료 (2026-11-14, 관리망 10.9.0.0/24 기준)** |
| leaf2 | 10.9.0.22 | 같음 | 장비 적용과 검증 완료 |
| leaf3 | 10.9.0.23 | 같음 | 장비 적용과 검증 완료 |
| leaf4 | 10.9.0.24 | 같음 | 장비 적용과 검증 완료 |
| spine1 | 10.9.0.11 | 같음 | 장비 적용과 검증 완료 |
| spine2 | 10.9.0.12 | 같음 | 장비 적용과 검증 완료 |
| border-leaf1, border-leaf2 | 10.9.0.25, 10.9.0.26 | 같음 | 장비 적용과 검증 완료 (2026-11-14) |
| DSW1, DSW2, ASW1 (Cisco IOSv) | 192.168.100.44 ~ .46 | vty `access-class`로 제한할 예정 | 미작성 |
| CX1, CX2, CX3 (Aruba) | 192.168.100.41 ~ .43 | mgmt 인터페이스 ACL로 제한할 예정 | 미작성 |
| PE1~PE3, Hub1, Hub2, BGW1, BGW2 (c7200) | 없음 | 관리망에 연결하지 않고 콘솔로만 접속 | 해당 없음 |
| MGMT-SW1 (Cisco IOSv) | 없음(VTY `login local`, SSH) | VLAN 900 L2 스위치, `Vlan900` 10.9.0.2 | 해당 없음 |
| CX1~3, DSW1·2, ASW1 | 없음 | 별도 관리망이 없어 관리 포트를 연결하지 않고 콘솔로만 접속 | 해당 없음 |

## 알려진 동작

- 설정이 없는 vEOS(ZTP 중인 장비)가 보내는 DHCP 요청이 규칙 80에 걸려 로그에 남음. 영향은 없음
- 규칙 80 앞에 허용을 추가하는 경우 순서 번호를 10 단위로 띄워 두면 중간에 끼워 넣기 쉬움
- SSH는 관리 PC(`10.9.0.10`)와 MGMT-SW1(`10.9.0.2`)에서만 됨. 같은 관리망의 다른 장비나 spine1의 링크 주소(`10.1.10.0`)에서 leaf1로 가는 SSH는 차단됨
- 규칙 10, 11, 15는 컨피그에 반영됨. 장비 적용 후 검증은 [검증](../../verification/dc1/05-mgmt-acl.md) 참조
- border-leaf1, border-leaf2는 MLAG 피어가 없어 규칙 60(MLAG 피어 통신)이 없고, 이후 규칙 번호가 하나씩 앞당겨짐(장비 간 ICMP 60, deny 70). 번호로 규칙을 지울 때는 장비마다 `show ip access-lists MGMT-ACL`로 확인
- 기본 VRF 줄을 빼면 언더레이 쪽 차단이 사라지므로 두 줄을 모두 유지
- 라우터(게이트웨이)가 없는 SVI 방식에서는 VRF 분리의 이점이 작음. 관리 라우터(MGMT-RTR)를 추가할 예정이라 그때를 대비해 VRF를 유지하는 구조이고, 장비 간 SSH 시험은 `bash`의 `sudo ip netns exec ns-MGMT ssh ...`로 함