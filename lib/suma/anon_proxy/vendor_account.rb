# frozen_string_literal: true

require "suma/anon_proxy"
require "suma/postgres"
require "suma/eligibility/has_constraints"

class Suma::AnonProxy::VendorAccount < Suma::Postgres::Model(:anon_proxy_vendor_accounts)
  plugin :timestamps

  # @!attribute member
  # @return [Suma::Member]

  # @!attribute configuration
  # @return [Suma::AnonProxy::VendorConfiguration]

  # @!attribute contact
  # @return [Suma::AnonProxy::MemberContact]

  many_to_one :member, class: "Suma::Member"
  many_to_one :configuration, class: "Suma::AnonProxy::VendorConfiguration"
  many_to_one :contact, class: "Suma::AnonProxy::MemberContact"
  one_to_many :messages, class: "Suma::AnonProxy::VendorAccountMessage"

  class << self
    # Return existing or newly created vendor accounts for the member,
    # using all configured services. Exclude vendor accounts for disabled services.
    # @param member [Suma::Member]
    # @return [Array<Suma::AnonProxy::VendorAccount>]
    def for(member)
      return [] unless member.onboarding_verified?

      ds = Suma::AnonProxy::VendorConfiguration.enabled.eligible_to(member)
      valid_configs = ds.
        all.
        index_by(&:id)
      accounts = member.anon_proxy_vendor_accounts_dataset.where(configuration_id: valid_configs.keys).all
      accounts.each { |a| valid_configs.delete(a.configuration_id) }
      unless valid_configs.empty?
        self.db.transaction do
          valid_configs.each_value do |configuration|
            accounts << member.add_anon_proxy_vendor_account(configuration:)
          end
        end
      end
      return accounts
    end
  end

  def contact_phone = self.contact&.phone
  def contact_email = self.contact&.email

  def sms = self.configuration.uses_sms? ? self.contact_phone : nil
  def sms_required? = self.configuration.uses_sms? && self.contact_phone.nil?

  def email = self.configuration.uses_email? ? self.contact_email : nil
  def email_required? = self.configuration.uses_email? && self.contact_email.nil?

  def address = self.email || self.sms
  def address_required? = self.email_required? || self.sms_required?

  # Ensure that the right member contacts exist for what the vendor configuration needs.
  # For example, this may create a phone number in our SMS provider if needed,
  # and the member does not have one; or insert a database object with the member's email.
  def provision_contact
    self.db.transaction do
      self.lock!
      if self.email_required?
        unless (contact = self.member.anon_proxy_contacts.find(&:email?))
          email = Suma::AnonProxy::Relay.active_email_relay.provision(self.member)
          contact = Suma::AnonProxy::MemberContact.create(
            member: self.member,
            email:,
            relay_key: Suma::AnonProxy::Relay.active_email_relay_key,
          )
        end
        self.contact = contact
        self.save_changes
      end
    end
    return self.contact
  end

  RECENT_MESSAGE_CUTOFF = 5.minutes

  # Return the text/plain bodies of outbound message deliveries sent as part of this vendor account.
  # This is useful for when users cannot get messages sent to them, like on non-production environments.
  def recent_message_text_bodies
    # We could select bodies directly, but we'd need to re-sort them.
    # It's not worth it, let's just select VendorAccountMessages and process that ordered list.
    messages = self.messages_dataset.
      where { created_at > RECENT_MESSAGE_CUTOFF.ago }.
      order(Sequel.desc(:created_at)).
      limit(5).
      all
    bodies = []
    messages.each do |m|
      body = m.outbound_delivery.bodies.find { |b| b.mediatype == "text/plain" }
      bodies << body.content if body
    end
    return bodies
  end
end
