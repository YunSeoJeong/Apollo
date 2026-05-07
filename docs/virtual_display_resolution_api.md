# Virtual Display Resolution API

Apollo exposes an authenticated Web UI API endpoint for changing the mode of the currently active Windows virtual display.

## Endpoint

```http
POST /api/virtual-display/resolution
Content-Type: application/json
```

The endpoint uses the same HTTPS host, port, and authentication session as the Web UI API.

Non-Web-UI clients must first authenticate with `POST /api/login` using the Web UI username and password,
then reuse the returned `auth` cookie when calling this endpoint. Basic authentication is not supported by
this endpoint in the current implementation.

Example login request:

```http
POST /api/login
Content-Type: application/json
```

```json
{
  "username": "admin",
  "password": "password"
}
```

On success, the server returns a `Set-Cookie` header containing the `auth` cookie. Include that cookie in
subsequent API requests.

## Request Body

```json
{
  "width": 2560,
  "height": 1440,
  "fps": 120
}
```

Fields:

- `width`: Target display width in pixels. Valid range: `320` to `16384`.
- `height`: Target display height in pixels. Valid range: `240` to `16384`.
- `fps`: Target refresh rate in frames per second. Valid range: `1` to `1000`.

All fields are required and must be unsigned JSON numbers.

## JavaScript Example

```js
async function resizeVirtualDisplay(host, width, height, fps) {
  const response = await fetch(`https://${host}:47990/api/virtual-display/resolution`, {
    method: "POST",
    credentials: "include",
    headers: {
      "Content-Type": "application/json",
    },
    body: JSON.stringify({ width, height, fps }),
  });

  const body = await response.json();
  if (!response.ok || !body.status) {
    throw new Error(body.error || "Failed to resize virtual display");
  }

  return body;
}
```

## Success Response

```json
{
  "status": true,
  "width": 2560,
  "height": 1440,
  "fps": 120
}
```

## Failure Response

```json
{
  "status": false,
  "width": 2560,
  "height": 1440,
  "fps": 120,
  "error": "Failed to apply virtual display mode",
  "error_code": -2
}
```

Common failure reasons:

- The request is not authenticated.
- The request body is missing `width`, `height`, or `fps`.
- The selected value is outside the accepted range.
- The virtual display driver is not ready.
- There is no running virtual display session.
- The virtual display name is not available yet.
- Windows failed to apply the requested display mode.

## Client UI Guidance

Clients can expose this as a pair of selectors: one for resolution and one for FPS. For example:

```js
const resolutions = [
  { label: "1920 x 1080", width: 1920, height: 1080 },
  { label: "2560 x 1440", width: 2560, height: 1440 },
  { label: "3840 x 2160", width: 3840, height: 2160 },
];

const fpsOptions = [30, 60, 90, 120, 144];
```

When the user confirms the selection, send the selected numeric values to the API. The server validates the request and returns whether the mode was applied.

## Manual Test Page

For local testing, open the authenticated Web UI page:

```text
https://HOST:47990/virtual-display-test
```

The page provides width, height, and FPS fields, a few presets, and the raw JSON response from the API.
