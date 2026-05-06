# Server Commands

Server commands are host-configured commands that can be invoked by a paired client during a stream.
The client does not choose the executable directly. It selects one of the commands configured on the
host, and Apollo runs that command on the host.

## Configuration

Server commands are configured in the web UI under **Configuration > General > Server Commands**.
Each command has:

| Field | Description |
|-------|-------------|
| Command Name | The label advertised to clients. |
| Command Value | The host command to execute. |
| Run as Admin | Windows-only option to run the command elevated. |
| Client Args | Allows the client to append an argument string to this command. |

The equivalent config file entry is:

```text
server_cmd = [{"name":"Open Profile","cmd":"C:\\Tools\\launcher.exe","elevated":false,"allow-client-args":true}]
```

`allow-client-args` defaults to `false`. Existing commands keep their old behavior unless this is
enabled for that specific command.

## Client Protocol

Clients invoke a server command with the `IDX_EXEC_SERVER_CMD` control packet.

The payload format is:

```text
payload[0]      = server command index (uint8)
payload[1..end] = optional UTF-8 argument string
```

To run command index `2` without arguments:

```text
[0x02]
```

To run command index `2` with arguments:

```text
[0x02] + "--profile living-room --fullscreen"
```

When client arguments are present and allowed, Apollo executes:

```text
<host configured command> <client argument string>
```

For example, with this host command:

```text
C:\Tools\launcher.exe
```

and this client payload:

```text
[0x00] + "--profile living-room"
```

Apollo runs:

```text
C:\Tools\launcher.exe --profile living-room
```

## Safety Rules

The client must have the `server_cmd` permission.

If the command does not have `allow-client-args` enabled, Apollo ignores requests that include
client arguments.

Client argument strings are limited to 4096 bytes. Payloads with embedded NUL bytes are ignored.

Client arguments are appended as a raw command-line string. The client is responsible for sending
arguments with the quoting expected by the host platform and target command.
