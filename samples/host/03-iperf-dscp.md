# iperf3 트래픽 생성과 DSCP 마킹

**목적**: QoS와 부하 분산 검증용 트래픽을 만들고 DSCP를 마킹

**핵심**

- 이 랩은 TCP 처리량이 불안정하고 1478바이트 이상의 패킷이 DC1에서 DC2로 가지 못함. 시험은 `ping -Q`와 UDP(`-l 1200`)로 하고 대상은 코어를 지나는 **Host D(192.168.110.101)** 를 씀
- DSCP 값: EF=46, AF31=26, AF21=18, CS1=8.
- `ping -Q`는 TOS 값(DSCP x 4)을 씀. EF는 184
- 부하 분산 확인에는 `-P`로 여러 흐름을 만듦. ECMP와 LACP 해시는 흐름 단위로 나뉨

**확인 명령**: `iperf3 -c <서버> --dscp 26`, `show policy-map interface <인터페이스>`

파일: `iperf-dscp.sh`

```bash
# Ubuntu Docker Guest (GNS3) - iperf3 트래픽 생성과 DSCP 마킹 샘플 (값은 예시)
# QoS 검증: 호스트가 DSCP를 마킹하고, c7200이 분류, 큐잉한다 (Arista vEOS는 ACL 분류를 쓰지 않는다)
# DSCP 값: EF=46, AF31=26, AF21=18, CS1=8, 기본=0  (ping -Q 는 TOS 값 = DSCP x 4)
# 확인: show policy-map interface <인터페이스> (c7200)

# 1. 서버 (수신 호스트)
iperf3 -s

# 2. 클라이언트 - UDP, DSCP 지정 (예: AF31). 데이터그램은 1200바이트로 고정
iperf3 -c 192.168.110.101 -u -b 200k -l 1200 --dscp 26 -t 30

# 3. UDP 트래픽으로 혼잡 만들기 (best-effort 800Kbps, 경로 용량 약 1Mbps 이하)
iperf3 -c 192.168.110.101 -u -b 800k -l 1200 -t 60

# 4. 지연과 손실 확인용 프로브 (EF = TOS 184). 혼잡 트래픽과 동시에 다른 창에서 실행
ping -Q 184 -c 100 -i 0.2 192.168.110.101

# 5. 여러 흐름으로 부하 분산 확인 (ECMP, LACP 해시는 흐름 단위로 나뉜다)
iperf3 -c 192.168.110.101 -u -b 200k -l 1200 -P 4 -t 30

# 6. TCP(`iperf3 -c <서버> --dscp 26`)는 이 랩에서 끊겨 처리량 시험에 쓰지 않음
```
