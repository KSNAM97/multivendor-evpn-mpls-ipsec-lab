# 코어 관리망 (MGMT-SW2, MGMT-RTR, PE 관리 VRF)

**목적**: 누리텔레콤 코어(PE1~3)를 DC1과 분리된 관리망(10.9.1.0/24)으로 관리하고, 접속을 관리 PC로 제한

**핵심**

- 관리 스위치 MGMT-SW2(IOSv)에 PE `Gi6/0`과 관리 PC를 연결하고, MGMT-RTR이 DC1 관리망과 코어 관리망을 연결
- PE는 `ip vrf MGMT`로 관리 경로를 코어 라우팅(OSPF, LDP, 고객 VRF)과 분리
- vty `access-class ... vrf-also`와 CoPP를 함께 사용. 코어 제어 트래픽은 `class-default`로 영향 없음
- 장비마다 RSA 키를 만들어야 SSH가 켜짐: `crypto key generate rsa modulus 2048`
- 클라이언트 호환 옵션: `ssh -o KexAlgorithms=+diffie-hellman-group14-sha1 -o HostKeyAlgorithms=+ssh-rsa -o Ciphers=+aes128-cbc admin@10.9.1.11`

**확인 명령**: `show ip route vrf MGMT`, `show access-lists MGMT-ACL`, `show policy-map control-plane`, `show ip ssh`

파일: `mgmt-sw2.ios`, `mgmt-rtr.ios`, `host/MGMT-PC2.sh`, PE 변경분은 `core/PE1.ios` ~ `PE3.ios`의 하단(관리 블록)

```text
! PE1 (PE2는 10.9.1.12, PE3은 10.9.1.13)
ip vrf MGMT
!
interface GigabitEthernet6/0
 description to-MGMT-SW2 (core management)
 ip vrf forwarding MGMT
 ip address 10.9.1.11 255.255.255.0
 no shutdown
!
ip route vrf MGMT 0.0.0.0 0.0.0.0 10.9.1.1
!
ip access-list standard MGMT-ACL
 permit host 10.9.1.10
!
line vty 0 4
 access-class MGMT-ACL in vrf-also
!
ip access-list extended ACL-COPP-ALLOW
 permit tcp host 10.9.1.10 any eq 22
 permit icmp 10.9.1.0 0.0.0.255 any
!
ip access-list extended ACL-COPP-DENY
 permit tcp any any eq 22
 permit tcp any any eq 23
!
class-map match-all CM-MGMT-ALLOW
 match access-group name ACL-COPP-ALLOW
class-map match-all CM-MGMT-DENY
 match access-group name ACL-COPP-DENY
!
policy-map PM-CONTROL-PLANE
 class CM-MGMT-ALLOW
  police 1000000 conform-action transmit exceed-action drop
 class CM-MGMT-DENY
  drop
!
control-plane
 service-policy input PM-CONTROL-PLANE
```
