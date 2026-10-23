# QoS (DiffServ)

호스트가 DSCP를 마킹하고, PE(c7200)가 DSCP를 MPLS TC로 매핑한 뒤 코어 출구에서 큐잉과 shaping을 함. 터널 구간(Hub, BGW)에서는 DSCP가 보존되는지만 확인

기준 문서: [00-overview](../../00-overview/README.md) / 샘플: [QoS 샘플](../../samples/core/08-qos.md) / 검증: [QoS 검증](../../verification/core/08-qos.md)

## 클래스

| 클래스 | DSCP | 값 | `ping -Q` (DSCP x 4) | MPLS TC | 처리 |
|---|---|---|---|---|---|
| Voice | EF | 46 | 184 | 5 | 우선 큐(LLQ) 20% |
| Network control | CS6 | 48 | 192 | 6 | 최소 대역폭 5% (BGP, OSPF, LDP 보호) |
| Critical | AF31 | 26 | 104 | 3 | 최소 대역폭 30% |
| Business | AF21 | 18 | 72 | 2 | 최소 대역폭 20% |
| Scavenger | CS1 | 8 | 32 | 1 | 혼잡 시 먼저 폐기 |
| Best-effort | 0 | 0 | 0 | 0 | 나머지 |

- DSCP 상위 3비트(IP precedence)가 TC로 기본 복사되어 5, 3, 2, 1이 자동으로 같은 값이 됨. 샘플은 의도를 드러내려고 `set mpls experimental imposition`을 명시

## 적용 위치

| 위치 | 동작 | 인터페이스 |
|---|---|---|
| 호스트 | `ping -Q`, `iperf3 --dscp`로 마킹 | Host A, D, F |
| DSW, ASW, leaf, CX | 마킹을 바꾸지 않고 통과(IOSv와 vEOS, AOS-CX는 QoS 정책을 쓰지 않음) | 해당 없음 |
| Hub, BGW 터널 | DSCP가 GRE와 ESP 바깥 IP 헤더로 복사됨. 별도 정책 없이 값 보존만 확인(**이 랩에서는 아직 캡처로 확인하지 않음**) | `tunnel 0`, `tunnel 1` |
| PE 입구 (**구현: PE1**) | DSCP를 MPLS TC로 매핑 | PE1 `Gi2/0`, `Gi3/0`(leaf) |
| PE 출구 (**구현: PE1**) | TC 기준 큐잉과 shaping | PE1 `Gi0/0`(PE2 방향) |

- 구현 범위는 **PE1 한 방향**(Host A -> Host D)이고 시험도 그 범위에서 함. PE2와 PE3, 반대 방향, Branch 쪽에는 정책이 없음
- 확장 후보: PE1 `Gi4/0`, `Gi5/0`(Hub)과 PE2 `Gi2/0`, `Gi3/0`(CX), PE3 `Gi2/0`, `Gi3/0`(BGW)에 `PE-IN`, PE2 `Gi0/0`(PE1 방향)에 출구 정책을 같은 방식으로 적용
- 시험 경로: **Host A(DC1) -> PE1 -> PE2 -> Host D(DC2)**. 코어 링크 PE1 `Gi0/0` 출구가 혼잡 지점
- 터널 구간 DSCP 보존 확인(Host F -> 터널 0 -> Hub1 -> PE1 -> Host A에서 바깥 ESP 패킷의 DSCP)은 후속 확인 항목

## 터널과 DSCP

- GRE는 안쪽 IP의 ToS(DSCP)를 바깥 IP 헤더로 복사하고, 전송 모드 ESP도 같은 바깥 헤더를 유지함. 그래서 PE는 터널 안 트래픽의 DSCP를 분류에 쓸 수 있음
- `qos pre-classify`는 안쪽 헤더의 주소나 포트로 분류할 때만 필요함. DSCP로만 분류하므로 쓰지 않음
- 터널 인터페이스의 기본 `bandwidth`는 100Kbit/sec라 퍼센트 기준 큐에 쓰면 비율이 어긋남. 터널에는 큐 정책을 걸지 않음

## 제약

- Arista vEOS는 ACL의 인터페이스 적용이 되지 않아 분류에 쓰지 않음. 분류는 c7200에서만 함
- 이 랩은 호스트와 스위치 에뮬레이션의 처리 능력이 낮아 **TCP 처리량 시험이 불안정함**(iperf3 TCP는 터널이 없는 Branch 안에서도 끊김). 시험은 **ping(`-Q`)과 UDP 저속 전송**으로 하고 TCP 처리량은 쓰지 않음
- 경로 용량을 Host A -> Host D로 측정함([QoS 검증](../../verification/core/08-qos.md)의 사전 측정): UDP 1Mbit/sec 전송은 평균 약 0.75Mbit/sec 수신에 손실 10%, 2Mbit/sec는 평균 1.13Mbit/sec 수신에 손실 34%. **경로 용량은 약 1Mbit/sec**이고 기존의 10Mbps shaping은 혼잡을 만들지 못함. shaping은 **400Kbit/sec**, 혼잡 트래픽은 UDP 800Kbit/sec로 정함(경로 용량 이하이면서 shaping의 2배)
- 이 경로에서 **IP 패킷 1478바이트(ping `-s 1450`)는 100% 손실**이고 1400바이트(`-s 1372`)는 통과함. DC1 VXLAN 헤더(50바이트)와 언더레이 MTU 1500 때문으로 추정하며 위치는 확정하지 않음. 시험 트래픽은 **UDP 데이터그램 1200바이트(`iperf3 -l 1200`)** 로 고정
- BGP hold가 9초라 부하가 크면 세션이 끊길 수 있음(앞선 시험에서 hold 만료 1회 발생). 시험 중 `show ip bgp summary`로 이웃 상태를 확인

## 순서

| 순서 | 할 일 |
|---|---|
| 1 | 경로 용량 측정: Host A에서 Host D로 UDP 속도를 올려 가며 손실이 시작되는 속도를 기록 |
| 2 | DSCP 보존 확인: 터널 앞, 뒤와 코어에서 EF 프로브의 DSCP와 TC를 캡처로 확인 |
| 3 | 혼잡 없음, 혼잡 정책 없음, 혼잡 정책 적용 세 상태를 같은 트래픽으로 비교 |
| 4 | `show policy-map interface`로 클래스별 패킷과 드롭 수 확인 |
