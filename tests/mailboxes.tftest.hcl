mock_provider "nomad" {}
mock_provider "random" {}
mock_provider "tls" {}
mock_provider "vault" {}

override_resource {
  target = tls_private_key.dkim_ed25519
  values = {
    public_key_pem        = "-----BEGIN PUBLIC KEY-----\nMCowBQYDK2VwAyEAGb9ECWmEzf6FQbrBZ9w7lshQhqowtrbLDFw4rXAxZuE=\n-----END PUBLIC KEY-----\n"
    private_key_pem_pkcs8 = "ed25519-private"
  }
}

override_resource {
  target = tls_private_key.dkim_rsa
  values = {
    public_key_pem        = "-----BEGIN PUBLIC KEY-----\nMIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEA\n-----END PUBLIC KEY-----\n"
    private_key_pem_pkcs8 = "rsa-private"
  }
}

variables {
  hostname   = "mail.example.com"
  domains    = ["example.com", "example.org"]
  acme_email = "postmaster@example.com"
}

run "every_domain_gets_every_mailbox" {
  command = apply

  variables {
    mailboxes = ["info", "sales"]
  }

  assert {
    condition = jsonencode(output.mailboxes) == jsonencode({
      "info@example.com"  = ["abuse@example.com", "postmaster@example.com"]
      "info@example.org"  = ["abuse@example.org", "postmaster@example.org"]
      "sales@example.com" = []
      "sales@example.org" = []
    })
    error_message = "Every domain should get every mailbox, and only the first one postmaster@ and abuse@."
  }

  assert {
    condition     = jsonencode(nonsensitive(keys(output.passwords))) == jsonencode(keys(output.mailboxes))
    error_message = "A mailbox has no generated password."
  }
}

run "info_is_the_default_mailbox" {
  command = apply

  assert {
    condition     = keys(output.mailboxes) == ["info@example.com", "info@example.org"]
    error_message = "Without mailboxes, every domain should get info@."
  }
}

run "accounts_add_to_mailboxes_and_override_their_aliases" {
  command = apply

  variables {
    accounts = {
      "jane@example.org" = { aliases = ["sales@example.org"] }
      "info@example.com" = {}
    }
  }

  assert {
    condition     = output.mailboxes["jane@example.org"] == ["sales@example.org"] && output.mailboxes["info@example.com"] == [] && output.mailboxes["info@example.org"] == ["abuse@example.org", "postmaster@example.org"]
    error_message = "accounts do not add mailboxes, or do not replace the aliases of a mailbox of the same address."
  }
}

run "records_are_in_the_dns_module_shape_with_a_comment" {
  command = apply

  assert {
    condition     = alltrue(flatten([for d, rs in output.dns_records : [for r in rs : r.comment == "Mail, managed by OpenTofu" && contains(["MX", "TXT", "CNAME"], r.type)]]))
    error_message = "A mail record lacks the mail comment or has an unexpected type."
  }

  assert {
    condition     = anytrue([for r in output.dns_records["example.org"] : r.type == "MX" && r.name == "example.org" && r.content == "mail.example.com" && r.priority == 10])
    error_message = "A domain lost its MX record pointing at hostname."
  }
}

run "bad_mailbox_names_are_refused" {
  command = plan

  variables {
    mailboxes = ["Info Desk"]
  }

  expect_failures = [var.mailboxes]
}
