# Changelog

All notable changes to this module are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

## [0.3.0] - 2026-10-06

### Changed

- Stalwart runs on the `docker` driver with the official image, pinned by its
  digest, instead of the release tarball on `exec`: after a reboot it starts
  from the image on the host, in seconds, with nothing to download. It runs
  as `nobody` with a read-only root and every capability dropped but
  `net_bind_service`.
- The job has a network of its own (`bridge`); the mail ports map to the same
  ports inside, keeping the address of every sender.
- **Breaking:** `stalwart` is `{image, cli}`: the image by its digest, and the
  release of stalwart-cli. `version` and `sha256` are gone.

## [0.2.0] - 2026-10-04

### Added

- The meta `backup = "stop"` on the job: a backup of the platform stops it
  while it copies the volume, since a running RocksDB store cannot be copied
  consistently. Changing the meta restarts the job once.

## [0.1.0] - 2026-09-27

### Added

- The Stalwart mail server as an app on the hashistack platform, moved out of
  `eugene-panin/hashistack/nomad` 0.5, where it was `modules/mail` and the
  `mail` input of the root module. Inside, the resources keep their names:
  moving an existing server here is a `moved` block, with nothing replaced.
- `mailboxes`: the mailboxes every domain gets, `["info"]` by default, the
  first also receiving `postmaster@` and `abuse@`, as the root module of the
  platform did. `accounts` now adds to them.
- The `mailboxes` output, and a `comment` on every record of `dns_records`,
  "Mail, managed by OpenTofu" unless `dns_comment` says otherwise.
- `tofu test` with mocked providers for the mailboxes and the records, with
  negative controls.
