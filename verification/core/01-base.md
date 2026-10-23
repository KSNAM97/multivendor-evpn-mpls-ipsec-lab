# 기본 설정 검증 (PE1~PE3)

**선행 조건**: PE1~PE3가 켜져 있고 [기본 설정 샘플](../../samples/core/01-base.md)이 적용되어 있어야 함

기준 문서: [개요](../../baseline/core/01-overview.md) / 샘플: [01-base.md](../../samples/core/01-base.md)

## 확인 항목

| 순서 | 장비 | 명령 | 기대 결과 | 안 될 때 확인 |
|---|---|---|---|---|
| 1 | PE1~PE3 | 콘솔 접속 | 로그인 후 프롬프트가 `PE1#`, `PE2#`, `PE3#`처럼 권한 모드(`#`)로 바로 열림 | `line con 0`의 `privilege level 15` |
| 2 | PE1~PE3 | `show running-config \| include hostname\|domain\|enable\|username` | hostname이 노드 이름과 같고 `ip domain-name lab.local`, `enable secret`, `username admin privilege 15 secret`이 보임 | 입력 누락 |
| 3 | PE1~PE3 | `show running-config \| begin banner` | `LAB PE<번호> - authorized use only` 배너가 구분자 `#` 안에 보임 | 배너 구분자 |
| 4 | PE1~PE3 | `show running-config \| include timestamps\|password-encryption\|clock` | `service timestamps`, `service password-encryption`, `clock timezone KST 9 0`이 보임 | 입력 누락 |
| 5 | PE1~PE3 | 존재하지 않는 단어 입력 (예: `abc`) | DNS 조회로 멈추지 않고 바로 오류 | `no ip domain-lookup` |

SSH는 exec 모드에서 `crypto key generate rsa modulus 2048`로 키를 만든 뒤에 사용 가능. c7200은 관리 포트가 없어 콘솔로 접속

## 결과 기록

| 일시 | 장비 | 결과 (성공, 실패) | 비고 |
|---|---|---|---|
| | | | |