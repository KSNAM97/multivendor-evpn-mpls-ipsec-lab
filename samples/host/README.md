# 호스트 (Ubuntu Docker Guest) 샘플

프로토콜(기능)별로 문서를 나눴음. 같은 이름의 `.sh` 파일은 원본

- [IP 설정](01-ip-config.md): 호스트 인터페이스에 IP와 기본 게이트웨이를 지정
- [LACP bond (Host A)](02-bond-lacp.md): Host A를 MLAG 쌍(leaf1, leaf2)에 LACP로 이중 연결
- [iperf3 트래픽 생성과 DSCP 마킹](03-iperf-dscp.md): QoS와 부하 분산 검증용 트래픽을 만들고 DSCP를 마킹
- [연결 확인](04-connectivity.md): 같은 VLAN, 다른 VLAN, 다른 지역, Branch 순으로 도달성을 확인
