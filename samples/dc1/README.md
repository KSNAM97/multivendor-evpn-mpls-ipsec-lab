# DC1 (Arista EOS) 샘플 컨피그 
프로토콜별로 문서를 나눴음. 같은 이름의 샘플 파일(원본, `.eos` `.ios` `.aos`)은 장비에 붙여 넣기 쉽게 그대로 두었음. 장비에서 검증한 컨피그가 아니라 문법 참고용 샘플

- [기본 설정 (장비 이름, 권한 모드, 세션)](01-base.md): 장비 이름, 계정과 권한 모드, 세션 유지, 관리 인터페이스를 설정
- [ZeroTouch(ZTP) 끄기](02-ztp-disable.md): vEOS 첫 부팅에서 ZTP를 끄고 hostname이 유지되게 함
- [기본 설정 - Hub (Cisco IOS)](03-base-hub.md): Hub1, Hub2(c7200)의 장비 이름, 권한 모드, domain-lookup, 세션을 설정
- [비밀번호 지정 위치](04-password.md): 계정, enable, BGP, OSPF 인증에 비밀번호와 키를 넣는 위치를 정리
- [OSPF underlay](05-ospf-underlay.md): leaf, spine 사이 점대점 /31 링크와 루프백 도달성을 만듦
- [MLAG](06-mlag.md): 두 leaf를 하나의 논리 스위치처럼 묶어 호스트를 이중 연결
- [iBGP EVPN-VXLAN (leaf)](07-evpn-vxlan-leaf.md): leaf에서 L2VNI, L3VNI(VRF)와 anycast gateway를 구성
- [iBGP EVPN Route Reflector (spine)](08-evpn-spine.md): spine이 Route Reflector로 leaf 경로를 모아서 전달
- [border leaf와 PE의 VRF eBGP](09-pe-ce-ebgp.md): border leaf가 MPLS 코어(PE1)와 TENANT-A VRF 경로를 교환
- [MGMT-SW (관리망 L2 스위치)](11-mgmt-sw.md): 관리 포트를 모으는 스위치의 설정과 ZTP 끄는 순서
- [관리 접속 제한 (control-plane ACL)](10-mgmt-acl.md): 관리망에서 오는 SSH, ping만 허용하고 나머지 접속은 차단
