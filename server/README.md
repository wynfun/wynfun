# Server notes (not published to the website)

Server: Hetzner CPX32, Nuremberg, Ubuntu. Site: https://wyn.fun  Staging: https://staging.wyn.fun

## How publishing works
- Branch `staging` is published to staging.wyn.fun within about a minute of each push.
- Branch `main` is published to wyn.fun within about a minute of each push.
- Each publish is a new numbered folder in /srv/wynfun/releases/<live|staging>, last 10 are kept.

## Commands on the server (rarely needed)
- `wyn-rollback live`     go back to the previous version of the live site
- `wyn-rollback staging`  same for staging
- `wyn-deploy live --force`  publish main again right now
- `cat /srv/wynfun/deploy.log`  history of publishes
- `systemctl status caddy`  web server status
