variable "hostname" {
  description = "Host name of the mail server: the MX of every domain, the name in the SMTP greeting and the one clients connect to. It must be inside one of domains."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9]([a-z0-9-]*[a-z0-9])?(\\.[a-z0-9]([a-z0-9-]*[a-z0-9])?)+$", var.hostname))
    error_message = "hostname must be a lowercase fully qualified domain name."
  }

  validation {
    condition     = anytrue([for d in var.domains : endswith(var.hostname, ".${d}")])
    error_message = "hostname must be inside one of domains."
  }
}

variable "domains" {
  description = "Mail domains the server accepts mail for and signs mail from."
  type        = set(string)

  validation {
    condition     = length(var.domains) > 0
    error_message = "domains must name at least one domain."
  }
}

variable "mailboxes" {
  description = "Mailboxes every domain gets, by the part before the @; the first one of each domain also receives postmaster@ and abuse@. Passwords are generated and returned by the passwords output."
  type        = list(string)
  default     = ["info"]

  validation {
    condition     = alltrue([for m in var.mailboxes : can(regex("^[a-z0-9][a-z0-9._-]*$", m))])
    error_message = "mailboxes must be lowercase local parts, such as info or sales."
  }
}

variable "accounts" {
  description = "More mailboxes keyed by full address, each with the alias addresses it also receives, on top of mailboxes. An address that mailboxes also makes takes these aliases instead. Every address must be in one of domains."
  type = map(object({
    aliases = optional(set(string), [])
  }))
  default = {}

  validation {
    condition = alltrue(flatten([
      for address, account in var.accounts : [
        for a in concat([address], tolist(account.aliases)) : contains(var.domains, try(split("@", a)[1], ""))
      ]
    ]))
    error_message = "Every account and alias address must be in one of domains."
  }
}

variable "acme_email" {
  description = "Contact address for the ACME account."
  type        = string
}

variable "acme_ca_server" {
  description = "ACME directory URL."
  type        = string
  default     = "https://acme-v02.api.letsencrypt.org/directory"
}

variable "acme_ca_certificate" {
  description = "PEM CA the ACME server's own TLS certificate is signed by, for a private ACME server. Null trusts the system store."
  type        = string
  default     = null
}

variable "public_host_network" {
  description = "Nomad host network the SMTP, submission and IMAP ports bind to, on their standard numbers."
  type        = string
  default     = "public"
}

variable "internal_host_network" {
  description = "Nomad host network of the HTTPS listener Traefik passes TLS through to."
  type        = string
  default     = "default"
}

variable "traefik" {
  description = "Traefik entrypoint that passes TLS for the mail host names through to Stalwart, and the TCP servers transport that sends the PROXY protocol header."
  type = object({
    entrypoint        = optional(string, "public-https")
    servers_transport = optional(string, "proxy-protocol@file")
  })
  default = {}
}

variable "dns_comment" {
  description = "Comment on every record of the dns_records output, so the mail records stand out in the DNS provider's dashboard."
  type        = string
  default     = "Mail, managed by OpenTofu"
}

variable "dkim_selector" {
  description = "Prefix of the DKIM selectors; each domain signs with <prefix>-ed25519 and <prefix>-rsa. Change it to rotate the keys."
  type        = string
  default     = "s1"
}

variable "dmarc_policy" {
  description = "DMARC policy published for every domain."
  type        = string
  default     = "none"

  validation {
    condition     = contains(["none", "quarantine", "reject"], var.dmarc_policy)
    error_message = "dmarc_policy must be none, quarantine or reject."
  }
}

variable "mta_sts_mode" {
  description = "MTA-STS mode served for every domain."
  type        = string
  default     = "testing"

  validation {
    condition     = contains(["testing", "enforce"], var.mta_sts_mode)
    error_message = "mta_sts_mode must be testing or enforce."
  }
}

variable "stalwart" {
  description = "The image of Stalwart, pinned by the digest of its index for every architecture so that no retagging changes it, and the release of stalwart-cli the setup task applies the configuration with."
  type = object({
    image = string
    cli   = string
  })
  nullable = false
  default = {
    image = "stalwartlabs/stalwart:v0.16.23@sha256:be215678796691bc39bdda918ecc50d14a9032a099a1d1950e51950aec7e2592"
    cli   = "1.0.12"
  }

  validation {
    condition     = can(regex("@sha256:[0-9a-f]{64}$", var.stalwart.image))
    error_message = "stalwart.image must be pinned by its digest: name:tag@sha256:<64 hex digits>."
  }
}

variable "vault_kv_path" {
  description = "Path of the KV version 2 engine the workload-identity module mounts."
  type        = string
  default     = "secret"
}

variable "namespace" {
  description = "Nomad namespace of the job; also the first segment of its secret path in Vault."
  type        = string
  default     = "default"
}

variable "job_name" {
  description = "Name of the Nomad job and its Consul service; also the second segment of its secret path in Vault."
  type        = string
  default     = "mail"
}

variable "datacenters" {
  description = "Datacenters the job may run in."
  type        = list(string)
  default     = ["*"]
}
