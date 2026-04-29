# ── OCI Managed Backup Policy Lookup ─────────────────────────────────────────
#
# OCI provides three pre-defined backup policies that are global resources
# (not compartment-scoped). We look them up by display name so that no
# hard-coded OCID is required in configuration.
#
# Policy schedules:
#   bronze — weekly full backup, retained 4 weeks
#   silver — daily incremental (retained 7 days) + weekly full (retained 4 weeks)
#   gold   — daily + weekly + monthly: daily retained 7 days, weekly 4 weeks, monthly 12 months
# ─────────────────────────────────────────────────────────────────────────────

data "oci_core_volume_backup_policies" "managed" {
  count = var.enable_boot_volume_backup ? 1 : 0

  filter {
    name   = "display_name"
    values = [var.boot_volume_backup_policy]
  }
}

locals {
  policy_id = (
    var.enable_boot_volume_backup
    ? data.oci_core_volume_backup_policies.managed[0].volume_backup_policies[0].id
    : null
  )
  all_boot_volume_ids = concat(var.cp_boot_volume_ids, var.compute_boot_volume_ids)
}

# ── Policy Assignments ────────────────────────────────────────────────────────
#
# One assignment per boot volume. Using a flat list index as the map key keeps
# the resource addresses stable when node counts change (new nodes are appended).
# ─────────────────────────────────────────────────────────────────────────────

resource "oci_core_volume_backup_policy_assignment" "boot_volume" {
  for_each = var.enable_boot_volume_backup ? { for i, v in local.all_boot_volume_ids : tostring(i) => v } : {}

  asset_id  = each.value
  policy_id = local.policy_id
}
