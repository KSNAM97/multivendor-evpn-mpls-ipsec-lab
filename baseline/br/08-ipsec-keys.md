# IPsec 키 관리

IPsec 사전 공유 키(PSK)를 다루는 규칙과 실습 랩 전용 키 값. **이 값은 공개된 실습 랩 전용이며 실제 환경에 재사용하지 않음.** 계정과 enable 비밀번호도 같은 방식의 실습 값

## 키 목록

| 키 이름 | 사용처 | 양쪽 장비 | 값 | 컨피그 위치 |
|---|---|---|---|---|
| PSK-T0 | Tunnel0 | Hub1, BGW1 | `Fy2Wa7sRcCosSoXG5TXziEVq` | `crypto isakmp key <키> address <상대 언더레이 주소>` |
| PSK-T1 | Tunnel1 | Hub2, BGW2 | `a37GYcnFbHABwpTzXJcmNV2J` | `crypto isakmp key <키> address <상대 언더레이 주소>` |

### 입력 명령

| 장비 | 명령 |
|---|---|
| Hub1 | `crypto isakmp key Fy2Wa7sRcCosSoXG5TXziEVq address 10.0.30.5` |
| BGW1 | `crypto isakmp key Fy2Wa7sRcCosSoXG5TXziEVq address 10.0.30.1` |
| Hub2 | `crypto isakmp key a37GYcnFbHABwpTzXJcmNV2J address 10.0.30.7` |
| BGW2 | `crypto isakmp key a37GYcnFbHABwpTzXJcmNV2J address 10.0.30.3` |

- 주소는 **상대 장비의 언더레이 주소**(Hub1의 상대는 BGW1 10.0.30.5, BGW1의 상대는 Hub1 10.0.30.1)

## 예비 키 (현재 설계에는 적용하지 않음)

OSPF, VRRP, BGP 인증은 지금 설계에 없음. 필요해지면 아래 값을 쓰고, 적용 위치는 [비밀번호 지정 위치](../../samples/br/13-password.md)

| 키 이름 | 용도 | 값 |
|---|---|---|
| OSPF-BR | BGW-DSW OSPF 인증 | `saFY2ywRDdmxMGTkTTt5zhjd` |
| VRRP-50 | VRRP 인증 VLAN 50 | `Kih942NjumjWkVuqPw4ULUKG` |
| VRRP-60 | VRRP 인증 VLAN 60 | `c4QKqPeaW9Cd5xCT38pxd8pK` |
| BGP-TUN | 터널 위 eBGP 이웃 비밀번호 | `tnfXqgiE7GnYVZ6intVpYaFm` |

## 규칙

- 터널마다 서로 다른 키를 씀(2개).
- 양쪽 장비에 **같은 값**을 넣어야 함. 한 글자라도 다르면 IKE 인증이 실패
- 키는 영문 대소문자와 숫자 24자. `?`, 공백, `\` 같은 특수문자는 IOS 입력에서 문제가 될 수 있어 쓰지 않음
- 이 저장소의 값은 공개되어 있으므로 실제 환경에 쓸 때는 새 키를 만들어 바꿈
- 장비의 `service password-encryption`을 켜서 `show running-config`에는 암호화 형태(type 7)로 보이게 함

## 교체 절차

1. 새 키를 정함(위 24자 난수 생성 방식 사용).
2. 한쪽 장비에서 `crypto isakmp key`를 새 값으로 바꿈.
3. 다른 쪽 장비도 같은 값으로 바꿈.
4. `clear crypto isakmp`로 SA를 다시 맺고 [검증 문서](../../verification/br/09-ipsec-gre.md)로 확인
5. 이 문서의 키 목록과 샘플(`samples/br`)의 값도 같이 바꿈

## 키가 다를 때의 증상

- `show crypto isakmp sa`에 SA가 생기지 않거나 `MM_KEY_EXCH` 같은 중간 상태에서 멈춤.
- `debug crypto isakmp`에서 인증 실패 메시지가 나옴
