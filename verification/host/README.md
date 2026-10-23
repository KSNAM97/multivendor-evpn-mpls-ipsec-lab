# 호스트 검증

각 문서에는 선행 조건, 확인 명령, 기대 결과, 안 될 때 확인할 것, 결과 기록 표가 있음

기준 문서: [baseline/host](../../baseline/host/README.md) / 샘플: [samples/host](../../samples/host/README.md)

순서대로 진행

1. [게이트웨이 연결](01-gateway.md): 호스트가 자기 게이트웨이까지 통신되는지
2. [LACP bond (Host A)](02-bond-lacp.md)
3. [연결 확인 시나리오](03-connectivity.md): 같은 VLAN, 다른 VLAN, DC 간, Branch
4. [QoS 트래픽과 DSCP](04-qos-dscp.md)

- 호스트 쪽 증빙은 해당 기능의 지역 검증 문서에도 들어 있음(예: Host A bond는 [DC1 MLAG 검증](../dc1/02-mlag.md)). 이 폴더의 문서는 호스트 관점에서 모아 보는 용도이고, 같은 화면은 링크로 가져옴