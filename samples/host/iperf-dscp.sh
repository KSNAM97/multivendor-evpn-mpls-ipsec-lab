# Ubuntu Docker Guest (GNS3) - iperf3 트래픽 생성과 DSCP 마킹 샘플 (값은 예시)
# QoS 검증: 호스트가 DSCP를 마킹하고, c7200이 분류, 큐잉한다 (Arista vEOS는 ACL 분류를 쓰지 않는다)
# DSCP 값: EF=46, AF31=26, AF21=18, CS1=8, 기본=0  (ping -Q 는 TOS 값 = DSCP x 4)
# 확인: show policy-map interface <인터페이스> (c7200)

# 1. 서버 (수신 호스트)
iperf3 -s

# 2. 클라이언트 - TCP, DSCP 지정 (예: AF31)
iperf3 -c 192.168.20.101 --dscp 26 -t 30

# 3. UDP 트래픽으로 혼잡 만들기 (best-effort 2Mbps)
iperf3 -c 192.168.20.101 -u -b 2M -t 60

# 4. 지연과 손실 확인용 프로브 (EF = TOS 184)
ping -Q 184 -c 100 -i 0.2 192.168.20.101

# 5. 여러 흐름으로 부하 분산 확인 (ECMP, LACP 해시는 흐름 단위로 나뉜다)
iperf3 -c 192.168.20.101 -P 8 -t 30

# 6. 양방향 테스트 (iperf3 3.7 이상)
iperf3 -c 192.168.20.101 --bidir -t 30
