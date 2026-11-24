# Tester environment

Upstream tag `v2.73.0` (`d46d79ec7646c6df351b6d9d61aab1726148f8a0`), built from
editable source in Docker. Two services: PHP 8.5/Apache app and MariaDB 10.11.
Upstream ships no compose file, so this fork owns the deployment path.

Use `v2.73.0`: it is the latest stable release (2026-11-23) and equals
`origin/main` HEAD. Fallback if a release regression shows up: `2.72.1`
(`b4ac77a622ffa060a534424cbb02540d2e8ff690`).

## Quick start

```bash
./tester-env deploy       # build image from source, start app + db, install schema, create admin
./tester-env seed         # create the seeded users + apply tester-env.d/seed.sql
./tester-env verify       # seeded counts, HTML visibility, logins without wizard
./tester-env wizard-off   # mark the first-login wizard as seen for all existing users
./tester-env reset        # compose down -v (db + var volumes), image kept
./tester-env stop         # stop containers, keep volumes
./tester-env start        # start existing containers, no rebuild
./tester-env status|logs|url|help
```

`--run-id <id>` scopes the compose project, containers and volumes;
`--port <port>` / `PORT` moves the published port (default `18280`).

URL: `http://localhost:18280/` (browser MCP:
`http://host.docker.internal:18280/`, bridge gateway on this host:
`http://172.16.0.1:18280/`). Login: `admin` / `tester-env-password`
(`admin@example.com`).

## Build topology

- `Dockerfile` (upstream, unchanged) `--target base --build-arg BASE=apache`
  is built once and tagged `tester-env-kimai-base:dev`: PHP 8.5 + Apache, the
  gd/intl/ldap/pdo_mysql/zip/xsl extensions, ICU tzdata, `/entrypoint.sh`,
  `/dbtest.php`. It contains no app source, so it is shared by every patch.
- `tester-env.d/Containerfile` builds the app image from that base:
  - `deps` stage copies only `composer.json`/`composer.lock`/`symfony.lock` and
    runs `composer install --no-dev --optimize-autoloader --no-scripts`. A source
    mutation does not invalidate this layer.
  - `prod` stage copies `vendor` from `deps`, then `COPY . /opt/kimai` as the
    last layer, applies upstream's prod php.ini/opcache settings, writes
    `version.txt`, runs `assets:install` and drops `var/cache`.
- `mariadb:10.11` with `healthcheck.sh --connect --innodb_initialized`.
- Only `${PORT}` is published (Apache listens on 8001 inside the image);
  MariaDB 3306 stays on the compose default bridge, no subnet is pinned.

### Measured cost

- Base image (cold): apt 32 s, six extension compiles 12-37 s each, ICU tzdata
  26 s, composer install 65 s on the first app build. Full cold chain a few
  minutes; it is cached for all later runs, including other variants.
- Source-only mutation (`deploy` after editing a Twig/PHP file): build RUN 69 s
  + export 5 s; composer layers report `CACHED`, no dependency reinstall.
  `deploy` end-to-end on a running stack: 1 min 35 s (build, container
  recreate, idempotent install, login check).
- `reset` + `deploy` on a fresh database: 1 min 54 s (82 migrations replayed by
  `kimai:install`).

## Mutation path and opcache

Prod keeps upstream's `opcache.validate_timestamps=0`; the source is baked into
the image, so an edit is picked up by `./tester-env deploy` (rebuild + container
recreate, fresh PHP process, empty opcache), not by `stop`/`start`. Verified by
appending an HTML comment to `templates/security/login.html.twig`, rebuilding,
observing it in `GET /en/login`, then reverting the file and rebuilding.

Prefer mutating PHP/Twig: `public/build` is committed upstream, so a JS/CSS
change would need pnpm/encore.

## First-login wizard

`src/EventSubscriber/WizardSubscriber.php` redirects every authenticated request
to the first wizard step the user has not seen (steps `intro` and `profile`,
tracked per user in the `__wizards__` preference). `kimai:user:create` cannot
mark them seen, and the `user.wizard` system toggle alone only exempts regular
users, so a fresh admin still lands on `/en/wizard/intro`.

`deploy` applies `tester-env.d/wizard-off.sql` after the install: inserts
`__wizards__ = 'intro,profile'` for every existing user (additive, so a
half-seen list is completed, never overwritten) and pins `user.wizard = 0`.
`wizard-off` re-runs it, and `seed` calls it after a seed file so users created
by seed data are covered too. Verified both ways: with the preference removed,
`GET /en/timesheet/` redirects to `/en/wizard/profile`; after `wizard-off` it
returns 200.

## Seeded data (data_seed)

Sequence for a clean, populated environment: `./tester-env reset && ./tester-env deploy && ./tester-env seed && ./tester-env verify`.

`seed` is app-supported and idempotent: it creates four users with
`kimai:user:create --ignore-existing` (the CLI hashes the password and creates
the per-user preference rows), then applies `tester-env.d/seed.sql`, then
re-applies `wizard-off.sql` so the new users skip the first-login wizard.
`seed.sql` deletes and re-inserts every fixture row in the fixed id range
1001-1099, so re-running it reproduces the same state and never touches other
records. Users are referenced by username, never by id.

Theme: "Northwind Studio", a small Berlin web studio tracking client work.
All dates are frozen in UTC 2026-10-05 .. 2026-11-20; nothing uses `NOW()`,
`rand()` or wall-clock-relative dates.

Credentials (all seeded users, fixed):

| login  | role             | alias          | noted as            |
|--------|------------------|----------------|---------------------|
| admin  | ROLE_SUPER_ADMIN | -              | site admin          |
| lena   | ROLE_ADMIN       | Lena Fischer   | 8 timesheets        |
| mara   | ROLE_TEAMLEAD    | Mara Hoffmann  | 8 timesheets, teamlead of Delivery |
| jonas  | ROLE_USER        | Jonas Weber    | 12 timesheets       |
| priya  | ROLE_USER        | Priya Nair     | 14 timesheets       |

Password for all five: `tester-env-password`. Emails are `<login>@example.com`.

Stable entities (ids in the DB, names in the UI):

- Customers (3, EUR, visible): Harborline Media `0101` (rate 95/h),
  Northstar Logistics `0102` (110/h), Copperline Bakery `0103` (75/h).
- Projects (5): Website Relaunch (`1001`, time budget 100:00, 51:00 used),
  Monthly Retainer (`1002`, time budget 40:00, 18:30 used), Brand Refresh
  (`1003`), Fleet Portal (`1004`, money budget EUR 12,000.00, 2,587.50 used),
  Warehouse Audit (`1005`, ended 2026-09-30, no entries).
- Activities (11): Development, Design (85/h, 20:00 budget, 13:00 used),
  Code Review (95/h, EUR 1,500 budget, 380 used), Support, Project Management,
  Content Writing (75/h), Audit Preparation, plus the global Internal Meeting.
  Fleet Portal overrides the rate at 115/h.
- Tags (6): frontend 5, backend 8, design 10, code-review 2, maintenance 1,
  client-meeting 6 links; 16 entries carry no tag.
- Team (1): `Delivery` with the four seeded users, mara as teamlead. Every
  seeded customer/project/activity is assigned to the team so regular users
  see the data.
- Timesheets (48, all stopped, ids 1001-1048): 45 billable / 3 non-billable,
  115:00 total, EUR 10,260.00 billable and EUR 665.00 non-billable. Split by
  owner: admin 6, jonas 12, priya 14, mara 8, lena 8. Fixed date range
  2026-10-05 .. 2026-11-20 on 28 working days.
- `./tester-env verify` asserts all counts/sums above, greps seeded records from
  the authenticated HTML (`/en/timesheet/`, `/en/admin/customer/`) and logs in
  as mara, jonas and priya to prove seeded users see their own entries with no
  wizard redirect.

### Budget vs working-time numbers (read before asserting)

Kimai's time-budget card (`templates/embeds/budgets.html.twig`) renders the
quota bar and the "used" percentage from `stats.durationBillable` only, while
the project list's working-hours column and the card's "working time" row use
the total duration. Both numbers are therefore correct, they just differ:

- Website Relaunch: 51:00 total working time (project list column), 44:00
  billable, 7:00 non-billable (Sprint 42 planning 2:00, Quarterly team retro
  3:00, Internal planning 2:00) - the quota bar reads **44:00 / 100:00 used**
  (44 % is billable/quota; the "billable" bar reads 44:00 / 51:00).
- Monthly Retainer: 18:30 total, all billable, quota bar 18:30 / 40:00.
- Fleet Portal money budget: revenue is billable rate only, EUR 2,587.50 /
  EUR 12,000.00, matching the seeded SUM(rate).
- Activity Design: 13:00 / 20:00 time budget; activity Code Review: EUR 380.00
  / EUR 1,500.00 money budget.

Do not assert the quota bar equals the working-time column. `verify` pins
those three derived values (WR total 183,600 s, WR billable 158,400 s, Fleet
Portal revenue 2,587.50) so a seed change that breaks the semantics is caught.

Note for scenario authors: the Kimai dashboard's "today / this week" widgets
read the system clock, so they show 0:00 between runs and the fixed dates. The
timesheet list is the populated surface (`/en/timesheet/` defaults to the
current user's entries; admins can pick users in the toolbar). Add
scenario-specific near-today records with a fixed anchor if a scenario targets
those widgets.

## Browser evidence

- browser-checker, 2026-11-24: logged in as `admin` / `tester-env-password` at
  `http://host.docker.internal:18280/`, opened the timesheet list
  (`/en/timesheet/`), then created the customer `Browser Smoke Customer`
  through the UI; it persisted after a page reload, so the write path and the
  read-back are proven in a real browser.
- `./tester-env reset` removed that browser-created artifact: after
  `reset` + `deploy`, `kimai2_customers = 0`, so the documented reset path
  covers records created through the UI, not just seeded rows.
- Seeded UI verified in the same browser session: admin's own 6 entries on
  `/en/timesheet/` (search `CMS template integration` matches one), 3
  customers on `/en/admin/customer/`, 5 projects on `/en/admin/project/`
  (Warehouse Audit ended, Website Relaunch 51:00 working time / 100:00 quota,
  Fleet Portal EUR 2,587.50 / 12,000), `Delivery` with 4 members on
  `/en/admin/teams/`, 6 tags on `/en/admin/tags/`, and `mara` logging in with
  no wizard redirect and seeing her 8 entries.
- Fork-tree replay (clean checkout, no `.work` dependency): `./tester-env
  deploy`, `seed` and `verify` all exit 0 from this repository root.

## Determinism notes

- Admin comes from `ADMINMAIL`/`ADMINPASS` (`kimai:user:create --ignore-existing`),
  so the password is only applied on the first start against an empty database.
  Changing the credentials requires `./tester-env reset`.
- `APP_SECRET` is fixed in compose, so sessions/remember-me cookies stay valid
  across `stop`/`start`; `reset` (volume delete) clears them, sessions are
  DB-backed (`kimai2_sessions`).
- `TIMEZONE=UTC` keeps times and the container clock aligned.
- `MAILER_URL=null://localhost`: password reset, invitations and mail test have
  no observable side effect.
- Login throttling is on (5 attempts / 5 min per user+IP): repeated failed
  login script loops in a scenario can lock the account briefly.
- The prod image has no fixtures bundle (`doctrine-fixtures-bundle` and
  `fakerphp/faker` are require-dev, registered only for dev/test), and
  `src/DataFixtures` is nondeterministic. The baseline seed is therefore
  fork-owned: `tester-env.d/seed.sql` plus the CLI user creation above.
- Seed determinism check: two full `reset -> deploy -> seed -> verify` cycles
  produced identical 228-row canonical snapshots (business tables, users,
  preferences and configuration; password hashes, `last_login` and sessions
  excluded), and re-running `seed` on the same volume produced an identical
  snapshot again.

## Run scoping and safety

`IMAGE_TAG` (set by `scripts/rl-env`) names the app image; `RUN_ID` only scopes
the compose project, containers and named volumes, and the shared
`tester-env-kimai-base:dev` base image is never scoped. Nothing here touches
`alevern/chromium-browser` images or `chromium-ls*` containers, and no docker
prune runs.
