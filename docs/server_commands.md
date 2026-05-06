# Server Commands

Server commands are host-configured commands that can be invoked by a paired client during a stream.
The client does not choose the executable directly. It selects one of the commands configured on the
host, and Apollo runs that command on the host.

## Configuration

Server commands are configured in the web UI under **Configuration > General > Server Commands**.
Each command has:

| Field | Description |
|-------|-------------|
| Command ID | The stable identifier clients use to invoke the command. |
| Command Name | The label advertised to clients. |
| Command Value | The host command to execute. |
| Run as Admin | Windows-only option to run the command elevated. |
| Client Args | Allows the client to provide an argument string for this command. |

The equivalent config file entry is:

```text
server_cmd = [{"id":"open-profile","name":"Open Profile","cmd":"C:\\Tools\\launcher.exe","elevated":false,"allow-client-args":true}]
```

Each server command must have a non-empty `id`. Apollo does not generate or migrate IDs for existing
commands.

`allow-client-args` defaults to `false`. Commands without this option still run without client
arguments.

## Client Protocol

Clients invoke a server command with the `IDX_EXEC_SERVER_CMD` control packet.

The payload format is:

```text
payload = command_id + '\0' + optional UTF-8 argument string
```

To run `open-profile` without arguments:

```text
"open-profile"
```

To run `open-profile` with arguments:

```text
"open-profile" + [0x00] + "--profile living-room --fullscreen"
```

When client arguments are present and allowed, Apollo appends them to the host command by default:

```text
<host configured command> <client argument string>
```

For example, with this host command:

```text
C:\Tools\launcher.exe
```

and this client payload:

```text
"open-profile" + [0x00] + "--profile living-room"
```

Apollo runs:

```text
C:\Tools\launcher.exe --profile living-room
```

To insert client arguments somewhere other than the end, include `{client_args}` in the host command.
Apollo replaces every `{client_args}` placeholder with the client argument string.

For example, with this host command:

```text
C:\Tools\launcher.exe --profile {client_args} --fullscreen
```

and this client payload:

```text
"open-profile" + [0x00] + "living-room"
```

Apollo runs:

```text
C:\Tools\launcher.exe --profile living-room --fullscreen
```

## Safety Rules

The client must have the `server_cmd` permission.

Apollo looks up commands by `id`, not by list index. Reordering the server command list does not
change which command a client invokes.

If the command does not have `allow-client-args` enabled, Apollo ignores requests that include
client arguments.

Command IDs are limited to 128 bytes.

Client argument strings are limited to 4096 bytes. Payloads with embedded NUL bytes are ignored.

Client arguments are used as a raw command-line string. If the host command contains
`{client_args}`, Apollo substitutes the raw string there. Otherwise, Apollo appends the raw string
to the end of the command. The client is responsible for sending arguments with the quoting expected
by the host platform and target command.

## Discovery

When a paired client has the `server_cmd` permission, Apollo advertises server commands in the host
info response. New clients should read `ServerCommandId` and `ServerCommand` entries in order and
use the ID value when invoking the command.
