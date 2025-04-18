# frozen_string_literal: true

require "suma/admin_linked"
require "suma/postgres"
require "suma/anon_proxy"

class Suma::AnonProxy::MemberContact < Suma::Postgres::Model(:anon_proxy_member_contacts)
  include Suma::AdminLinked
  include Suma::Postgres::HybridSearch

  plugin :hybrid_search
  plugin :timestamps

  many_to_one :member, class: "Suma::Member"
  one_to_many :vendor_accounts, class: "Suma::AnonProxy::VendorAccount", key: :contact_id

  def phone? = !!self.phone
  def email? = !!self.email

  def rel_admin_link = "/anon-member-contact/#{self.id}"

  def hybrid_search_fields
    return [:member, :phone, :email]
  end
end

# Table: anon_proxy_member_contacts
# ----------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id         | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at | timestamp with time zone |
#  phone      | text                     |
#  email      | text                     |
#  relay_key  | text                     | NOT NULL
#  member_id  | integer                  | NOT NULL
# Indexes:
#  anon_proxy_member_contacts_pkey                | PRIMARY KEY btree (id)
#  anon_proxy_member_contacts_email_relay_key_key | UNIQUE btree (email, relay_key)
#  anon_proxy_member_contacts_phone_relay_key_key | UNIQUE btree (phone, relay_key)
#  anon_proxy_member_contacts_member_id_index     | btree (member_id)
# Check constraints:
#  unambiguous_address | (phone IS NOT NULL AND email IS NULL OR phone IS NULL AND email IS NOT NULL)
# Foreign key constraints:
#  anon_proxy_member_contacts_member_id_fkey | (member_id) REFERENCES members(id) ON DELETE CASCADE
# Referenced By:
#  anon_proxy_vendor_accounts | anon_proxy_vendor_accounts_contact_id_fkey | (contact_id) REFERENCES anon_proxy_member_contacts(id) ON DELETE SET NULL
# ----------------------------------------------------------------------------------------------------------------------------------------------------
