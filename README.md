# ATVLoadly Hass.io Add-ons

Home Assistant add-on repository for running
[bitxeno/atvloadly](https://github.com/bitxeno/atvloadly) on Home Assistant
OS / Home Assistant Supervised.

## Included add-on

- `atvloadly`: Apple TV sideload service with Home Assistant sidebar support
  and LAN access

## Highlights

- Uses the prebuilt upstream release binary `v0.4.5` for `linux/amd64`
- Runs on `host_network` so Bonjour / mDNS discovery can work properly
- Exposes ATVLoadly on the LAN, default port `5533`
- Keeps Home Assistant sidebar access through Ingress

## Add repository to Home Assistant

Use this GitHub repository URL in `Settings -> Add-ons -> Add-on Store ->
Repositories`:

```text
https://github.com/Shuangbing/atvloadly-hassio-addons
```

Then install the `ATVLoadly` add-on from the store.

## Upstream

- Upstream project: [bitxeno/atvloadly](https://github.com/bitxeno/atvloadly)
- Upstream release used by this add-on:
  [v0.4.5](https://github.com/bitxeno/atvloadly/releases/tag/v0.4.5)
