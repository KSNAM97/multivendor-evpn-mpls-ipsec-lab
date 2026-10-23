# MLAG

**목적**: 두 leaf를 하나의 논리 스위치처럼 묶어 호스트를 이중 연결

**핵심**

- peer-link는 Port-Channel1(Et3-4)이고, 제어용 VLAN 4094에 별도 trunk group을 둠
- 호스트 포트채널은 양쪽 leaf에 같은 `mlag` 번호를 씀
- MLAG는 벤더 독자 방식이라 Arista끼리만 묶임

- 호스트 포트의 멤버(`ethernet5`)에 `lacp timer fast`를 주면 leaf도 LACPDU를 1초 간격으로 보내서 호스트(`lacp_rate fast`)와 양쪽이 모두 빠른 감지를 함(적용 전 파트너 `port state` 61, 적용 후 63). 포트채널이 아니라 **멤버 포트**에 줌
- 호스트에 연결된 access 포트(MLAG 포트채널 포함)에는 `spanning-tree portfast`와 `spanning-tree bpduguard enable`을 줌. 호스트 한 대만 붙는 말단 포트라 STP 수렴을 기다리지 않고 바로 포워딩하며, BPDU가 들어오면 포트를 꺼서 루프를 막음. 스위치끼리 연결되는 포트(피어 링크, spine 링크)에는 쓰지 않음. `portfast`를 켜면 "should only be enabled on ports connected to a single host" 경고가 나오는데 정상

**확인 명령**: `show mlag`, `show mlag interfaces`, `show port-channel dense`

파일: `mlag.eos`

```text
! Arista EOS - MLAG 샘플 (leaf1 기준, leaf2는 IP를 .1 / peer .0 으로 바꿈)
! 확인: show mlag / show mlag interfaces / show port-channel dense
!
spanning-tree mode mstp
no spanning-tree vlan-id 4094
!
vlan 4094
   name MLAG-PEER
   trunk group MLAGPEER
!
vlan 999
   name NATIVE
!
interface port-channel1
   description MLAG-PEERLINK
   switchport mode trunk
   switchport trunk native vlan 999
   switchport trunk group MLAGPEER
!
interface ethernet3
   channel-group 1 mode active
!
interface ethernet4
   channel-group 1 mode active
!
interface vlan4094
   ip address 10.1.254.0/31
   no autostate
!
mlag configuration
   domain-id MLAG1
   local-interface vlan4094
   peer-address 10.1.254.1
   peer-link port-channel1
exit
!
! 호스트 연결 MLAG 포트채널 (양쪽 leaf에 같은 mlag 번호)
vlan 10
!
interface port-channel10
   description to-HostA
   spanning-tree portfast
   spanning-tree bpduguard enable
   switchport mode access
   switchport access vlan 10
   mlag 10
!
interface ethernet5
   channel-group 10 mode active
   lacp timer fast
!
```
