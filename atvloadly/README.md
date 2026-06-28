# ATVLoadly for Home Assistant

This custom add-on packages the prebuilt `atvloadly` `v0.4.5` Linux
`amd64` release for Home Assistant.

Repository URL:

```text
https://github.com/Shuangbing/atvloadly-hassio-addons
```

## What it does

- Runs `atvloadly` inside Home Assistant OS / Supervised
- Starts `dbus`, `avahi-daemon`, `usbmuxd2`, and `plumesign` dependencies
- Exposes the UI through Home Assistant Ingress
- Exposes the UI on the LAN through the host network
- Adds a sidebar entry named `ATVLoadly`

## Important notes

- `amd64` only
- Designed for Home Assistant OS / Supervised
- Uses `host_network: true` so mDNS discovery can work
- Default LAN port is `5533`
- `service_port` is configurable, but must not be `58080`
- Sidebar access still works through Home Assistant Ingress

## Install as a local add-on

Copy this directory to:

```text
/addons/local/atvloadly
```

Then in Home Assistant:

1. Restart the Supervisor or reboot Home Assistant
2. Open `Settings -> Add-ons`
3. Open `ATVLoadly`
4. Install and start it
5. Open it from the sidebar
