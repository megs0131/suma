# frozen_string_literal: true

require "suma/i18n"
require "suma/postgres"
require "suma/message"

class Suma::Message::Preferences < Suma::Postgres::Model(:message_preferences)
  plugin :timestamps

  many_to_one :member, class: Suma::Member

  def initialize(*)
    super
    self[:sms_enabled] = true if self[:sms_enabled].nil?
    self[:email_enabled] = false if self[:email_enabled].nil?
    self[:preferred_language] = "en" if self[:preferred_language].nil?
  end

  def sms_enabled? = self.sms_enabled
  def email_enabled? = self.email_enabled

  def dispatch(message)
    message.language = self.preferred_language
    to = self.member
    sent = []
    sent << Suma::Message.dispatch(message, to, :sms) if self.sms_enabled?
    sent << Suma::Message.dispatch(message, to, :email) if self.email_enabled?
    return sent
  end

  def validate
    super
    self.validates_includes Suma::I18n.enabled_locale_codes, :preferred_language
  end
end

# Table: message_preferences
# ---------------------------------------------------------------------------------------------
# Columns:
#  id                 | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at         | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at         | timestamp with time zone |
#  member_id          | integer                  | NOT NULL
#  preferred_language | text                     | NOT NULL
#  sms_enabled        | boolean                  | NOT NULL
#  email_enabled      | boolean                  | NOT NULL
# Indexes:
#  message_preferences_pkey          | PRIMARY KEY btree (id)
#  message_preferences_member_id_key | UNIQUE btree (member_id)
# Foreign key constraints:
#  message_preferences_member_id_fkey | (member_id) REFERENCES members(id)
# ---------------------------------------------------------------------------------------------
