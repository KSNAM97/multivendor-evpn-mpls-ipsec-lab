# 기본 설정 검증 (CX1~CX3)

**선행 조건**: CX1, CX2, CX3이 켜져 있고 [기본 설정 샘플](../../samples/dc2/01-base.md)이 적용되어 있어야 함

기준 문서: [01-overview.md](../../baseline/dc2/01-overview.md) / 샘플: [01-base.md](../../samples/dc2/01-base.md)

## 확인 항목

| 순서 | 장비 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | CX1~CX3 | 콘솔 로그인 | 프롬프트가 `CX1#`, `CX2#`, `CX3#`처럼 노드 이름으로 보임 | `hostname` |
| 2 | CX1~CX3 | `show running-config` | hostname, `user admin group administrators`, `cli-session timeout 0`이 보임 | 입력 누락 |
| 3 | CX1~CX3 | `show interface mgmt` | 관리 주소(CX1 192.168.100.41, CX2 .42, CX3 .43)와 up | `interface mgmt`의 `ip static` |
| 4 | CX1~CX3 | `show ssh server` | `ssh server vrf mgmt`가 적용됨 | 입력 누락 |
| 5 | PC | `ssh admin@192.168.100.41` | 접속 가능 (MGMT-SW 연결 후) | MGMT-SW 포트, VMnet2 |

## 결과 기록

| 일시 | 장비 | 결과 (성공, 실패) | 비고 |
|---|---|---|---|
| | | | |