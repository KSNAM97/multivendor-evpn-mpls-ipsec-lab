# QoS 트래픽과 DSCP

호스트가 DSCP를 마킹하고, c7200(PE)이 분류하고 큐잉. Arista vEOS는 ACL 기반 분류를 쓰지 않음(인터페이스 ACL 미지원)

샘플: [03-iperf-dscp.md](../../samples/host/03-iperf-dscp.md)

## 클래스와 DSCP

| 클래스 | DSCP | 값 | `ping -Q` (DSCP x 4) | MPLS TC |
|---|---|---|---|---|
| VOICE | EF | 46 | 184 | 5 |
| CRITICAL | AF31 | 26 | 104 | 3 |
| BUSINESS | AF21 | 18 | 72 | 2 |
| SCAVENGER | CS1 | 8 | 32 | 1 |
| 기본 | 0 | 0 | 0 | 0 |

## 트래픽 생성 방식

| 목적 | 방법 |
|---|---|
| 서버 | 수신 호스트에서 `iperf3 -s` |
| DSCP 지정 UDP | `iperf3 -c <서버> -u -b 200k -l 1200 --dscp 26 -t 30` (TCP는 이 랩에서 끊겨 쓰지 않음) |
| 혼잡 만들기 | `iperf3 -c <서버> -u -b 800k -l 1200 -t 60` (UDP). 경로 용량이 약 1Mbit/sec라 코어에서 400Kbit/sec로 shaping해 혼잡을 만듦 |
| 지연, 손실 | `ping -Q 184 -c 100 -i 0.2 <서버>` |
| 부하 분산 | `iperf3 -c <서버> -u -b 200k -l 1200 -P 4 -t 30` (ECMP와 LACP 해시는 흐름 단위로 나뉨) |

- 서버는 코어를 지나는 **Host D(192.168.110.101)** 를 씀. 1478바이트 이상의 패킷은 DC1에서 DC2로 가지 못하므로 데이터그램을 1200바이트로 고정

## 검증 위치

- 코어(PE1) 인터페이스에서 `show policy-map interface <인터페이스>`로 클래스별 패킷과 드롭 수를 봄
- 와이어샤크로는 코어 링크에서 `ip.dsfield.dscp == 46`(안쪽 IP)과 `mpls.exp == 5`(MPLS TC)를 비교함([캡처 계획](../../00-overview/08-wireshark-capture.md)).