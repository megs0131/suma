# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres/model"

class Suma::Vendor < Suma::Postgres::Model(:vendors)
  include Suma::AdminLinked

  plugin :timestamps

  many_to_one :organization, key: :organization_id, class: "Suma::Organization"
  one_to_one :payment_account, class: "Suma::Payment::Account"
  one_to_many :services, class: "Suma::Vendor::Service"

  def before_create
    self.slug ||= Suma.to_slug(self.name)
  end

  def after_create
    super
    self.payment_account ||= Suma::Payment::Account.create(vendor: self)
  end

  def rel_admin_link = "/vendor/#{self.id}"
end

# Table: vendors
# ----------------------------------------------------------------------------------------------------------
# Columns:
#  id              | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at      | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at      | timestamp with time zone |
#  name            | text                     | NOT NULL
#  slug            | text                     | NOT NULL
#  organization_id | integer                  | NOT NULL
# Indexes:
#  vendors_pkey                  | PRIMARY KEY btree (id)
#  vendors_organization_id_index | btree (organization_id)
# Foreign key constraints:
#  vendors_organization_id_fkey | (organization_id) REFERENCES organizations(id) ON DELETE CASCADE
# Referenced By:
#  payment_accounts | payment_accounts_vendor_id_fkey | (vendor_id) REFERENCES vendors(id)
#  vendor_services  | vendor_services_vendor_id_fkey  | (vendor_id) REFERENCES vendors(id) ON DELETE CASCADE
# ----------------------------------------------------------------------------------------------------------
