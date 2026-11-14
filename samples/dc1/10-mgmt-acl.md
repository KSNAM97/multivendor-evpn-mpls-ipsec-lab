# 관리 접속 제한 (control-plane ACL)

**목적**: 장비에 SSH로 접속할 수 있는 출발 주소를 관리 PC(`10.9.0.10`)와 MGMT-SW(`10.9.0.2`)로 제한하고, ping은 관리망(`10.9.0.0/24`)만 허용. 그 밖의 접속은 차단

**핵심**

- Arista vEOS에서는 데이터 포트의 인터페이스 ACL(`ip access-group ... in/out`)이 지원되지 않아서, 장비 CPU로 들어오는 트래픽을 거르는 **control-plane ACL**을 씀. 실제로 허용과 차단이 모두 동작함이 확인됨
- control-plane으로는 SSH, ping뿐 아니라 **OSPF, BGP, MLAG 제어 통신**도 들어옴. 마지막에 `deny ip any any`를 두면 이것들도 막히므로, 필요한 프로토콜을 위에서 먼저 허용
- 아래 샘플은 MLAG 쌍인 spine, leaf 기준. MLAG 피어가 없는 border-leaf는 규칙 `60 permit ip 10.1.254.0/24 any`가 없어 이후 번호가 하나씩 앞당겨짐(`60 permit icmp 10.0.0.0/8 any`, `70 deny ip any any log`)
- ARP, LACP, LLDP는 L2라서 IP ACL의 대상이 아님.
- 이름(`MGMT-ACL`)은 대문자, 명령어는 소문자로 씀
- 막힌 패킷은 `deny ... log` 때문에 로그에 남음. 설정이 없는 장비의 DHCP 요청(`udp 0.0.0.0(68) -> 255.255.255.255(67)`, ZTP)이 막히는 것은 정상이고 영향이 없음
- control-plane에는 기본 VRF용과 관리 VRF(`vrf MGMT`)용 두 줄을 모두 적용. 기본 VRF 줄이 없으면 언더레이 쪽 차단이 사라짐
- 잠겼을 때는 콘솔에서 `system control-plane` 아래의 `no ip access-group MGMT-ACL vrf MGMT in`으로 풀 수 있음

**확인 명령**: `show ip access-lists MGMT-ACL`, `show running-config section control-plane`, `show logging last 30 minutes | include ACL`

파일: `mgmt-acl.eos`

```text
! Arista EOS - 관리 접속 제한 (control-plane ACL) 샘플, 모든 spine, leaf 공통 (값은 예시)
vrf instance MGMT
!
interface management1
   vrf MGMT
   ip address 10.9.0.<N>/24
!
management ssh
   vrf MGMT
      no shutdown
!
ip access-list MGMT-ACL
   10 permit tcp host 10.9.0.10 any eq ssh
   11 permit tcp host 10.9.0.2 any eq ssh
   15 deny tcp 10.9.0.0/24 any eq ssh log
   20 permit icmp 10.9.0.0/24 any
   30 permit ospf any any
   40 permit tcp 10.1.0.0/24 any eq bgp
   50 permit tcp 10.1.0.0/24 eq bgp any
   60 permit ip 10.1.254.0/24 any
   70 permit icmp 10.0.0.0/8 any
   80 deny ip any any log
!
system control-plane
   ip access-group MGMT-ACL in
   ip access-group MGMT-ACL vrf MGMT in
!
```