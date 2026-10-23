# 0. 사전 준비

처음 진행하는 경우 이 순서대로 따라 할 수 있도록 구성

전체 토폴로지: [00-overview](../00-overview/README.md)의 그림과 표

## 환경

| 항목 | 값 |
|---|---|
| GNS3 | 2.2.61 (GNS3 VM 사용) |
| GNS3 VM | RAM 22GB, vCPU 14, KVM 사용 가능 |
| 스왑 | 8GB 스왑 파일을 만들어 둠 (메모리 부족 시 안전장치) |

## 이미지와 템플릿

| 장비 | 이미지 | 비고 |
|---|---|---|
| Arista | vEOS 4.29.2F | 포트 이름 형식 `Et{port1}`로 설정 (GNS3 템플릿의 Name format) |
| Aruba | ArubaOS-CX 10.07 시뮬레이터 | 포트 `1/1/1` 형식 |
| Cisco 라우터 | c7200 | 슬롯: `slot0 = C7200-IO-GE-E`, `slot1~5 = PA-GE`. Idle-PC 설정 |
| Cisco 스위치 | IOSvL3(DSW), IOSvL2(ASW) | 포트 이름은 4개 단위(`Gi0/0~3`, `Gi1/0~`) |
| 호스트 | Ubuntu Docker Guest | iperf3와 bond 동작 확인됨 |

## 노드별 어댑터 수 (관리 포함)

| 노드 | 어댑터 |
|---|---|
| spine1, spine2 | 5 |
| leaf1, leaf2 | 6 |
| leaf3, leaf4 | 8 |
| IOSv DSW1, DSW2 | 5 |
| IOSv ASW1 | 6 |
| Host A | 2 (나머지 호스트 1) |

## 작업 규칙

1. **한 번에 모든 노드를 켜지 않음.** 단계별로 필요한 노드만 켬([리소스 계획](../00-overview/04-resource-plan.md)).
2. 노드를 켤 때 2~3개씩 켜고, GNS3 VM에서 `watch -n 2 free -m`으로 `available`이 **2GB 아래로 내려가지 않게** 봄
3. 장비 이름(hostname)은 GNS3 노드 이름과 같게 함
4. 설정이 끝나면 `write memory`로 저장하고, 설정을 `configs/` 폴더의 해당 파일에 보관
5. **계정, enable 비밀번호와 IPsec 사전 공유 키는 공개된 실습 랩 전용 값.** 실제 환경에 재사용하지 않음. 키 목록은 [키 관리](../baseline/br/08-ipsec-keys.md)

## 문서 사용법

| 문서 종류 | 용도 |
|---|---|
| `baseline/` | 무엇을 설정하는지(값, 설계) |
| `samples/` | 어떻게 쓰는지(명령 문법 예시) |
| `configs/` | 실제 장비 컨피그 보관 |
| `verification/` | 제대로 되었는지 확인 |
| `guide/` | 단계별 진행 순서 (이 폴더) |

다음: [1단계 DC1](01-dc1.md)
