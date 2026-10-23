# 관리 접속 제한 (control-plane ACL)

**목적**: 장비에 SSH, ping으로 접속할 수 있는 출발 주소를 관리망(`192.168.100.0/24`)으로 제한하고, 그 밖의 접속은 차단

**핵심**

- Arista vEOS에서는 데이터 포트의 인터페이스 ACL(`ip access-group ... in/out`)이 지원되지 않아서, 장비 CPU로 들어오는 트래픽을 거르는 **control-plane ACL**을 씀. 실제로 허용과 차단이 모두 동작함이 확인됨
- control-plane으로는 SSH, ping뿐 아니라 **OSPF, BGP, MLAG 제어 통신**도 들어옴. 마지막에 `deny ip any any`를 두면 이것들도 막히므로, 필요한 프로토콜을 위에서 먼저 허용
- ARP, LACP, LLDP는 L2라서 IP ACL의 대상이 아님.
- 이름(`MGMT-ACL`)은 대문자, 명령어는 소문자로 씀
- 막힌 패킷은 `deny ... log` 때문에 로그에 남음. 설정이 없는 장비의 DHCP 요청(`udp 0.0.0.0(68) -> 255.255.255.255(67)`, ZTP)이 막히는 것은 정상이고 영향이 없음
- 잠겼을 때는 콘솔에서 `system control-plane` 아래의 `no ip access-group MGMT-ACL in`으로 풀 수 있음

**확인 명령**: `show ip access-lists MGMT-ACL`, `show running-config section control-plane`, `show logging last 30 minutes | include ACL`

파일: `mgmt-acl.eos`

```text
! Arista EOS - 관리 접속 제한 (control-plane ACL) 샘플, 모든 spine, leaf 공통 (값은 예시)
ip access-list MGMT-ACL
   10 permit tcp 192.168.100.0/24 any eq ssh
   20 permit icmp 192.168.100.0/24 any
   30 permit ospf any any
   40 permit tcp 10.1.0.0/24 any eq bgp
   50 permit tcp 10.1.0.0/24 eq bgp any
   60 permit ip 10.1.254.0/24 any
   70 permit icmp 10.0.0.0/8 any
   80 deny ip any any log
!
system control-plane
   ip access-group MGMT-ACL in
!
```