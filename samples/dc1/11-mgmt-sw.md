# MGMT-SW (관리망 L2 스위치)

**목적**: Arista와 Aruba, Cisco 일부의 관리 포트를 한 스위치에 모으고, 마지막 포트로 PC(GNS3 Cloud)에 연결

**핵심**

- 관리 IP가 없고 모든 포트가 기본 VLAN 1. 설정 없이도 L2 스위치로 동작하므로 필요한 것은 장비 이름, 계정, 세션 유지 정도
- 첫 부팅에서 ZTP가 돌고 있으면 hostname이 `localhost`로 남음. 먼저 `zerotouch cancel`(재부팅)을 하고, 부팅 후 `zerotouch disable`과 `write memory`를 함([ZTP 끄기](02-ztp-disable.md)). `zerotouch cancel`은 즉시 재부팅하므로 같은 붙여넣기에 다른 설정을 이어 붙이지 않음
- 포트 배치(`Et1`~`Et12` 장비, `Et13` Cloud)는 [포트 매핑](../../00-overview/01-port-mapping.md)을 따름
- 설정이 없는 장비(ZTP 중)가 보내는 DHCP 요청이 다른 장비의 관리 ACL 로그에 남을 수 있지만 영향은 없음. MGMT-SW의 ZTP를 끄면 줄어듬.

**확인 명령**: `show interfaces status`, `show mac address-table`

파일: `mgmt-sw.eos`

```text
hostname MGMT-SW
service routing protocols model multi-agent
username admin privilege 15 role network-admin secret <PASSWORD>
management console
   idle-timeout 0
logging buffered 64000
clock timezone Asia/Seoul
```