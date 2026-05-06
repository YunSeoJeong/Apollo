# 서버 명령

서버 명령은 호스트에 미리 설정해 둔 명령을 스트리밍 중 페어링된 클라이언트가 호출할 수 있게 하는 기능입니다.
클라이언트가 실행 파일을 직접 고르는 방식이 아닙니다. 클라이언트는 호스트에 설정된 명령 중 하나를 선택하고,
Apollo가 그 명령을 호스트에서 실행합니다.

## 설정

서버 명령은 웹 UI의 **Configuration > General > Server Commands**에서 설정합니다.
각 명령에는 다음 항목이 있습니다.

| 항목 | 설명 |
|------|------|
| Command ID | 클라이언트가 명령을 호출할 때 사용하는 고정 식별자입니다. |
| Command Name | 클라이언트에 표시되는 명령 이름입니다. |
| Command Value | 호스트에서 실행할 명령입니다. |
| Run as Admin | Windows에서만 사용하는 관리자 권한 실행 옵션입니다. |
| Client Args | 클라이언트가 이 명령에 인수 문자열을 제공할 수 있게 허용합니다. |

설정 파일에서는 다음처럼 표현됩니다.

```text
server_cmd = [{"id":"open-profile","name":"Open Profile","cmd":"C:\\Tools\\launcher.exe","elevated":false,"allow-client-args":true}]
```

각 서버 명령에는 비어 있지 않은 `id`가 있어야 합니다. Apollo는 기존 명령의 ID를 자동 생성하거나 마이그레이션하지 않습니다.

`allow-client-args`의 기본값은 `false`입니다. 이 옵션이 없는 명령은 클라이언트 인수 없이 실행됩니다.

## 클라이언트 프로토콜

클라이언트는 `IDX_EXEC_SERVER_CMD` 제어 패킷으로 서버 명령을 호출합니다.

payload 형식은 다음과 같습니다.

```text
payload = command_id + '\0' + 선택 사항인 UTF-8 인수 문자열
```

`open-profile` 명령을 인수 없이 실행하려면 다음처럼 보냅니다.

```text
"open-profile"
```

`open-profile` 명령에 인수를 붙여 실행하려면 다음처럼 보냅니다.

```text
"open-profile" + [0x00] + "--profile living-room --fullscreen"
```

클라이언트 인수가 있고 해당 명령에서 인수를 허용한 경우, Apollo는 기본적으로 다음 형태로 명령 뒤에 인수를 붙여 실행합니다.

```text
<호스트에 설정된 명령> <클라이언트 인수 문자열>
```

예를 들어 호스트 명령이 다음과 같고:

```text
C:\Tools\launcher.exe
```

클라이언트 payload가 다음과 같다면:

```text
"open-profile" + [0x00] + "--profile living-room"
```

Apollo는 호스트에서 다음 명령을 실행합니다.

```text
C:\Tools\launcher.exe --profile living-room
```

클라이언트 인수를 끝이 아닌 중간에 넣고 싶다면, 호스트 명령에 `{client_args}`를 포함합니다.
Apollo는 모든 `{client_args}` placeholder를 클라이언트 인수 문자열로 치환합니다.

예를 들어 호스트 명령이 다음과 같고:

```text
C:\Tools\launcher.exe --profile {client_args} --fullscreen
```

클라이언트 payload가 다음과 같다면:

```text
"open-profile" + [0x00] + "living-room"
```

Apollo는 호스트에서 다음 명령을 실행합니다.

```text
C:\Tools\launcher.exe --profile living-room --fullscreen
```

## 안전 규칙

클라이언트에는 `server_cmd` 권한이 있어야 합니다.

Apollo는 목록 인덱스가 아니라 `id`로 명령을 찾습니다. 서버 명령 목록의 순서를 바꿔도 클라이언트가 호출하는 명령은 바뀌지 않습니다.

명령에 `allow-client-args`가 켜져 있지 않으면, Apollo는 클라이언트 인수가 포함된 요청을 무시합니다.

명령 ID는 최대 128바이트까지 허용됩니다.

클라이언트 인수 문자열은 최대 4096바이트까지 허용됩니다. 문자열 중간에 NUL 바이트가 포함된 payload는 무시됩니다.

클라이언트 인수는 원본 명령줄 문자열 그대로 사용됩니다. 호스트 명령에 `{client_args}`가 있으면 Apollo는 그 위치에 원본 문자열을 치환합니다. `{client_args}`가 없으면 Apollo는 명령 끝에 원본 문자열을 붙입니다. 따라서 클라이언트는 호스트 플랫폼과 대상 명령이 기대하는 quoting 규칙에 맞춰 인수를 보내야 합니다.

## 검색

페어링된 클라이언트에 `server_cmd` 권한이 있으면 Apollo는 호스트 정보 응답에서 서버 명령을 알려줍니다.
새 클라이언트는 `ServerCommandId`와 `ServerCommand` 항목을 순서대로 읽고, 명령을 호출할 때 ID 값을 사용해야 합니다.
