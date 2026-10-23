# GRE over IPsec

Hub와 BGW 사이에 GRE 터널 2개를 만들고 IPsec(IKEv1, ISAKMP)으로 보호

키 관리: [ipsec-keys](08-ipsec-keys.md)

기준 문서: [00-overview](../../00-overview/README.md)

## 터널

| 터널 | 양 끝 | 터널 주소 | source / destination |
|---|---|---|---|
| Tunnel0 | Hub1 - BGW1 | 10.0.40.0/31 (Hub1 .0, BGW1 .1) | 10.0.30.1 / 10.0.30.5 |
| Tunnel1 | Hub2 - BGW2 | 10.0.40.2/31 (Hub2 .2, BGW2 .3) | 10.0.30.3 / 10.0.30.7 |

## IPsec 파라미터

| 항목 | 값 |
|---|---|
| IKE | IKEv1 (ISAKMP). c7200 이미지의 `show crypto ?`에 `ikev2`가 없음 |
| 암호화 / 해시 / DH | AES-256 / SHA-1 (이 이미지의 ISAKMP는 sha256 미지원) / group 14 |
| IPsec 모드 | transport (GRE를 보호) |
| 인증 | 사전 공유 키 (값은 [ipsec-keys](08-ipsec-keys.md) 참고) |
| 터널 MTU / MSS | ip mtu 1400 / tcp adjust-mss 1360 |

## 터널 위 eBGP

[터널 위 eBGP](10-bgp-over-tunnel.md)에서 다룸. 터널이 올라온 뒤(이 문서의 내용이 검증된 뒤)에 진행

- 이 c7200 이미지는 IKEv2가 없어 IKEv1(ISAKMP)을 씀. 지원 알고리즘은 이미지에 따라 다르므로 `crypto isakmp policy`에서 확인
