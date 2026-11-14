# 코어 관리망과 관리 접속 제한

누리텔레콤 코어(PE1~3)의 관리 접속을 DC1과 분리된 별도 관리망으로 두는 설계

샘플: [10-mgmt.md](../../samples/core/10-mgmt.md)

## 설계값

| 항목 | 값 |
|---|---|
| 관리 스위치 | MGMT-SW2 (Cisco IOSv), VLAN 910, `Vlan910` 10.9.1.2/24 |
| 관리망 | 10.9.1.0/24 (누리텔레콤 전용), DC1 관리망(10.9.0.0/24)과 분리 |
| 관리 PC | MGMT-PC2 10.9.1.10 |
| PE 관리 포트 | `Gi6/0`을 `ip vrf MGMT`에 두고 PE1 10.9.1.11, PE2 .12, PE3 .13 |
| 게이트웨이 | MGMT-RTR `Gi1/0` 10.9.1.1, PE는 `ip route vrf MGMT 0.0.0.0 0.0.0.0 10.9.1.1` |
| 접속 제한 | vty `access-class MGMT-ACL in vrf-also`(10.9.1.10만) + CoPP(`PM-CONTROL-PLANE`) |

## 접속 제한 구조

| 단계 | 방식 | 동작 |
|---|---|---|
| vty | 표준 ACL `MGMT-ACL`, `permit host 10.9.1.10` | 관리 PC 외 출발 주소의 로그인 차단 |
| CoPP 허용 | `ACL-COPP-ALLOW`(관리 PC의 SSH, 관리망 ICMP), 1Mbps police | 허용 대상만 통과 |
| CoPP 차단 | `ACL-COPP-DENY`(SSH, Telnet), drop | 허용 외 SSH, Telnet 폐기 |
| 그 밖 | `class-default` | OSPF, LDP, BGP 등 코어 제어 트래픽은 그대로 통과 |

## MGMT-RTR (두 관리망 연결)

| 포트 | 연결 | 주소 | 인터페이스 ACL |
|---|---|---|---|
| Gi0/0 | MGMT-SW1 Gi3/2 | 10.9.0.1/24 | `ACL-DC1-IN`: ICMP 허용, DC1에서 코어로 가는 그 밖의 트래픽 deny |
| Gi1/0 | MGMT-SW2 Gi3/2 | 10.9.1.1/24 | `ACL-CORE-IN`: ICMP 허용, 코어에서 DC1로 가는 그 밖의 트래픽 deny |

- MGMT-RTR 자체 접속도 CoPP로 두 관리 PC(10.9.0.10, 10.9.1.10)에서만 허용
- 두 관리망은 서로 ping만 되고, 상대 장비로의 SSH는 라우터에서 차단(책임 경계 분리)

## 알려진 동작

- c7200(IOS 12.4(24)T5)의 SSH 서버는 SHA-1 키 교환만 제시하므로, 최신 OpenSSH 클라이언트에는 호환 옵션이 필요: `ssh -o KexAlgorithms=+diffie-hellman-group14-sha1 -o HostKeyAlgorithms=+ssh-rsa -o Ciphers=+aes128-cbc admin@<IP>`
- SSH 서버는 RSA 키(`crypto key generate rsa modulus 2048`)를 만들어야 켜짐. 컨피그에 들어가지 않는 명령이라 장비마다 한 번 실행
- `ip vrf forwarding`을 인터페이스에 적용하면 IP가 지워지므로 VRF를 먼저 넣고 IP를 입력
- Hub, BGW(c7200)는 이번 범위에서 관리망에 연결하지 않음(콘솔)
