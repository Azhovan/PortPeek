# PortPeek

A macOS menu bar app that shows which processes are listening on your network ports — and lets you kill them with one click.

![PortPeek screenshot](port-peek-screenshot.png)

## Why?

Finding what's using a port on macOS or Linux means remembering incantations like:

```bash
lsof -nP -iTCP -sTCP:LISTEN | grep 3000
netstat -tlnp | grep :8080
ss -tlnp sport = :5432
fuser 3000/tcp
```

PortPeek replaces all of that with a glance at your menu bar. Open the popover, see every listening port, search for the one you need, and terminate the process — no terminal required.

## Install

Requires macOS 15+ and Xcode.

```bash
make build
make run
```

## Usage

Click the stethoscope icon in the menu bar. The popover shows all listening TCP ports, the process name, and PID. Type in the search box to filter by port number or process name. Click the X button to send SIGTERM to a process.
