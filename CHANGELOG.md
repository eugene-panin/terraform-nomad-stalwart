# Changelog

All notable changes to this module are documented here.
This project adheres to [Semantic Versioning](https://semver.org/).

## [Unreleased]

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
