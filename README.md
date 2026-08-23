# 🐘 Joplin Server Nix Flake

A feature-rich, production-grade Nix Flake providing a **NixOS Module** and **Package** for [Joplin Server](https://joplinapp.org/) note synchronization server.

> 📦 **Nixpkgs Ready**: This repository is structured and formatted for immediate porting/import into `NixOS/nixpkgs` (under `pkgs/by-name/jo/joplin-server` and `nixos/modules/services/web-apps/joplin-server.nix`).
> ⚖️ **License Notice**: According to the official Joplin project, Joplin Server is distributed under the **Joplin Server Personal Use License** (Personal / Non-Commercial Use Only). In Nixpkgs, it uses `lib.licenses.unfreeRedistributable`.

---

## ⚡ Features & Capabilities

- 🎛️ **Comprehensive Options & Toggles**: Modular toggles for runtime mode, databases, reverse proxies, mailers, and security hardening.
- 📦 **Dual Execution Backends**: Toggle between OCI Containers (`podman`/`docker`) or native Systemd service execution.
- 🐘 **PostgreSQL Auto-Provisioning**: Automated local PostgreSQL database creation toggle (`database.createLocally`).
- 🌐 **Reverse Proxy Toggles**: Instant 1-line reverse proxy configuration for **Nginx** (with Let's Encrypt SSL) or **Caddy**.
- 📧 **Mailer Toggles**: Integrated SMTP mailer flags for user invites and password resets.
- 🛡️ **Systemd Hardening**: Default systemd security sandboxing flags (`ProtectSystem`, `ProtectHome`, `PrivateTmp`, `NoNewPrivileges`).

---

## 🚀 Quickstart

### 1. Add to your Flake inputs

```nix
inputs = {
  nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  joplin-server.url = "github:Apollo-sudo767/joplin-server-flake";
};
```

### 2. Import module and configure in NixOS

```nix
{ config, pkgs, inputs, ... }:

{
  imports = [ inputs.joplin-server.nixosModules.default ];

  services.joplin-server = {
    enable = true;
    baseUrl = "https://joplin.example.com";

    # Option Toggles
    database.createLocally = true; # Toggles local PostgreSQL auto-setup
    nginx.enable = true;          # Toggles Nginx reverse proxy + SSL
    openFirewall = true;          # Toggles firewall port opening
  };
}
```

---

## 🎛️ Options & Toggles Reference

| Option | Type | Default | Description / Toggle Function |
| :--- | :--- | :--- | :--- |
| `services.joplin-server.enable` | `bool` | `false` | Master toggle to enable/disable Joplin Server |
| `services.joplin-server.baseUrl` | `str` | *required* | Public base URL (e.g. `https://joplin.example.com`) |
| `services.joplin-server.port` | `port` | `22300` | Port for Joplin Server |
| `services.joplin-server.host` | `str` | `"127.0.0.1"` | Listening host IP |
| `services.joplin-server.useContainer` | `bool` | `false` | Toggle between native systemd process (`false`) or OCI Container (`true`) |
| `services.joplin-server.containerImage` | `str` | `"docker.io/joplin/server:3.7.1"` | OCI container image tag |
| `services.joplin-server.database.type` | `enum` | `"postgres"` | Database type: `"postgres"` or `"sqlite"` |
| `services.joplin-server.database.createLocally` | `bool` | `true` | Toggle automatic local PostgreSQL db & user creation |
| `services.joplin-server.database.passwordFile` | `nullOr path` | `null` | Path to DB password file |
| `services.joplin-server.storage.driver` | `enum` | `"Database"` | Storage backend: `"Database"`, `"Filesystem"`, or `"S3"` |
| `services.joplin-server.storage.path` | `path` | `"/var/lib/joplin-server/data"` | File path when storage driver is `"Filesystem"` |
| `services.joplin-server.mailer.enable` | `bool` | `false` | Toggle SMTP email notification feature |
| `services.joplin-server.nginx.enable` | `bool` | `false` | Toggle automatic Nginx reverse proxy + ACME SSL setup |
| `services.joplin-server.caddy.enable` | `bool` | `false` | Toggle automatic Caddy reverse proxy setup |
| `services.joplin-server.openFirewall` | `bool` | `false` | Toggle opening port in firewall |
| `services.joplin-server.systemdHardening.enable` | `bool` | `true` | Toggle systemd security sandboxing flags |

---

## 💻 Example Configurations

### Example 1: Local PostgreSQL + Nginx SSL Reverse Proxy

```nix
services.joplin-server = {
  enable = true;
  baseUrl = "https://joplin.mydomain.com";

  database = {
    type = "postgres";
    createLocally = true; # Local DB setup
    passwordFile = "/var/lib/joplin-server/db-password";
  };

  nginx = {
    enable = true; # Automated Nginx virtual host with ACME SSL
    forceSSL = true;
    enableACME = true;
  };
};

security.acme.defaults.email = "admin@mydomain.com";
security.acme.acceptTerms = true;
```

### Example 2: Caddy + SMTP Email Mailer

```nix
services.joplin-server = {
  enable = true;
  baseUrl = "https://notes.company.com";

  caddy.enable = true; # Reverse proxy toggle

  mailer = {
    enable = true; # Enable email invites & password resets
    host = "smtp.mailgun.org";
    port = 587;
    security = "starttls";
    authUser = "postmaster@company.com";
    authPasswordFile = "/var/lib/joplin-server/smtp-password";
    fromName = "Joplin Sync";
    fromEmail = "no-reply@company.com";
  };
};
```

---

## 🛠️ Flake Commands & CLI

- **Run interactive test CLI**: `nix run .#joplin-server`
- **Check flake syntax & outputs**: `nix flake check`
- **Enter dev environment**: `nix develop`
- **Initialize from template**: `nix flake init -t github:Apollo-sudo767/joplin-server-flake#postgres-nginx`

---

## 🛠️ Porting to `NixOS/nixpkgs`

This codebase is 100% structured for direct porting into official `NixOS/nixpkgs`:

1. **Package Derivation**: Move `package.nix` → `pkgs/by-name/jo/joplin-server/package.nix` in `nixpkgs`.
2. **NixOS Service Module**: Move `module.nix` → `nixos/modules/services/web-apps/joplin-server.nix` in `nixpkgs`.
3. **Module Registration**: Add `./services/web-apps/joplin-server.nix` to `nixos/modules/module-list.nix`.
4. **Updating Version**: To update Joplin Server to a new upstream version, update `version`, `imageDigest`, and `sha256` in `package.nix`.

---

## 📄 License & Terms

* **Joplin Server Software**: Licensed under the **[Joplin Server Personal Use License](https://github.com/laurent22/joplin/blob/dev/packages/server/LICENSE.md)** (Personal / Non-Commercial Use Only).
* **Nix Flake & Module Packaging**: MIT License.
