# Arista ZeroTouch(ZTP) 끄기

**목적**: vEOS가 첫 부팅에서 ZeroTouch Provisioning 모드로 들어가 hostname이 `localhost`로 남거나 설정이 적용되지 않는 것을 막음

**증상**

- 프롬프트가 `localhost>` 또는 `localhost#`이고 `hostname`을 바꿔도 재부팅 후 돌아옴
- 로그에 ZTP 관련 메시지가 반복됨

**끄는 방법 (exec 모드)**

```text
zerotouch cancel
```

- ZTP를 중단하고 재부팅. 부팅이 끝난 뒤 아래로 영구 비활성화

```text
enable
zerotouch disable
write memory
```

- `zerotouch disable`을 하면 다시 재부팅될 수 있음. 끝난 뒤 `show zerotouch`로 상태를 확인

**대안**: 부팅 직후 ZTP 모드에서 안 되면, Aboot 쉘이나 `bash`에서 플래시에 `zerotouch-config` 파일을 만들고 `DISABLE=True`를 넣는 방법도 알려져 있음(이미지에서 확인 필요).

**확인 명령**: `show zerotouch`, `show running-config`, `show version`

노드를 새로 만들 때마다(처음 부팅할 때) 한 번만 하면 되고, `write memory` 후에는 유지됨
