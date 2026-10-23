# GRE over IPsec (IKEv1)

**목적**: Hub와 BGW 사이에 GRE 터널을 만들고 IPsec으로 보호

**핵심**

- 이 프로젝트의 c7200 이미지(IOS 12.4(24)T5)는 `show crypto ?`에 `isakmp`가 있고 `ikev2`가 없어 IKEv1(ISAKMP)을 씀
- ISAKMP `hash sha256`은 이 이미지에서 `% Invalid input`으로 거부되어 `hash sha`(SHA-1)를 씀. `group 14`와 `encryption aes 256`은 지원됨
- 오버헤드에 맞춰 `ip mtu 1400`과 `ip tcp adjust-mss 1360`을 줌
- 사전 공유 키는 실습 랩 전용 값을 [키 관리](../../baseline/br/08-ipsec-keys.md)에 정리. Tunnel0은 `Fy2Wa7sRcCosSoXG5TXziEVq`, Tunnel1은 `a37GYcnFbHABwpTzXJcmNV2J`이고 양쪽 같은 값
- **양끝 설정은 대칭**: `crypto isakmp key`의 address는 상대의 언더레이 주소, 터널 source와 destination은 서로 바뀜. Hub1 `source 10.0.30.1 / destination 10.0.30.5`, BGW1 `source 10.0.30.5 / destination 10.0.30.1`
- 장애 시험을 위해 DPD(`crypto isakmp keepalive 10 3 periodic`)를 줌. 지원 여부와 형식은 `?`로 확인
- 터널 위 eBGP, 재귀 경로 방지 `prefix-list`, Branch LAN 광고는 [터널 위 eBGP](10-bgp-over-tunnel.md)

**확인 명령**: `show crypto isakmp sa`, `show crypto ipsec sa`, `show crypto session`, `show interface tunnel 0`

파일: `ipsec-gre.ios`

```text
! Cisco IOS (c7200) - GRE over IPsec(IKEv1, ISAKMP) 샘플 (Hub1, Hub2, BGW1, BGW2, 값은 예시)
! 이 프로젝트의 c7200 이미지는 "show crypto ?" 에 isakmp 가 있고 ikev2 가 없어서 IKEv1을 쓴다
! 확인: show crypto isakmp sa / show crypto ipsec sa / show crypto session / show interface tunnel 0
! 사전 공유 키는 실습 랩 전용 값이다 (Tunnel0 Fy2Wa7sRcCosSoXG5TXziEVq, Tunnel1 a37GYcnFbHABwpTzXJcmNV2J, 양쪽 같은 값). 목록은 baseline/br/08-ipsec-keys.md
! 이 c7200 이미지(IOS 12.4(24)T5)는 isakmp hash sha256 을 지원하지 않아(% Invalid input) hash sha(SHA-1)를 쓴다. group 14 는 지원된다
! 터널 위 eBGP와 prefix-list는 "터널 위 eBGP" 샘플(bgp-over-tunnel.ios)에 있다
!
!   Tunnel0: Hub1 10.0.40.0/31 (source 10.0.30.1) <-> BGW1 10.0.40.1/31 (source 10.0.30.5), 키 Fy2Wa7sRcCosSoXG5TXziEVq
!   Tunnel1: Hub2 10.0.40.2/31 (source 10.0.30.3) <-> BGW2 10.0.40.3/31 (source 10.0.30.7), 키 a37GYcnFbHABwpTzXJcmNV2J
!
! [공통: Hub1, Hub2, BGW1, BGW2] ISAKMP 정책, DPD, transform-set, profile
crypto isakmp policy 10
    encryption aes 256
    hash sha
    authentication pre-share
    group 14
    lifetime 86400
!
! DPD (장애 시험에서 상대가 죽은 것을 감지). 지원 여부와 형식은 ? 로 확인
crypto isakmp keepalive 10 3 periodic
!
crypto ipsec transform-set TS esp-aes 256 esp-sha-hmac
    mode transport
!
crypto ipsec profile IPSEC-PROF
    set transform-set TS
!
! [Hub1] peer(BGW1)의 언더레이 주소 기준 (Hub2는 a37GYcnFbHABwpTzXJcmNV2J, address 10.0.30.7)
crypto isakmp key Fy2Wa7sRcCosSoXG5TXziEVq address 10.0.30.5
!
interface tunnel 0
    description GRE-over-IPsec-to-BGW1
    ip address 10.0.40.0 255.255.255.254
    ip mtu 1400
    ip tcp adjust-mss 1360
    tunnel source 10.0.30.1
    tunnel destination 10.0.30.5
    tunnel protection ipsec profile IPSEC-PROF
!
! (Hub2는 interface tunnel 1, 10.0.40.2/31, source 10.0.30.3, destination 10.0.30.7)
!
! [BGW1] peer(Hub1)의 언더레이 주소 기준 (BGW2는 a37GYcnFbHABwpTzXJcmNV2J, address 10.0.30.3)
crypto isakmp key Fy2Wa7sRcCosSoXG5TXziEVq address 10.0.30.1
!
interface tunnel 0
    description GRE-over-IPsec-to-HUB1
    ip address 10.0.40.1 255.255.255.254
    ip mtu 1400
    ip tcp adjust-mss 1360
    tunnel source 10.0.30.5
    tunnel destination 10.0.30.1
    tunnel protection ipsec profile IPSEC-PROF
!
! (BGW2는 interface tunnel 1, 10.0.40.3/31, source 10.0.30.7, destination 10.0.30.3)
!
```
