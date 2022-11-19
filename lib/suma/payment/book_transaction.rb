# frozen_string_literal: true

require "suma/admin_linked"
require "suma/payment"

class Suma::Payment::BookTransaction < Suma::Postgres::Model(:payment_book_transactions)
  include Suma::AdminLinked

  plugin :timestamps
  plugin :money_fields, :amount
  plugin :translated_text, :memo, Suma::TranslatedText

  many_to_one :originating_ledger, class: "Suma::Payment::Ledger"
  many_to_one :receiving_ledger, class: "Suma::Payment::Ledger"
  many_to_one :associated_vendor_service_category, class: "Suma::Vendor::ServiceCategory"
  one_to_many :funding_transactions, class: "Suma::Payment::FundingTransaction", key: :originated_book_transaction_id
  many_to_many :charges,
               class: "Suma::Charge",
               join_table: :charges_payment_book_transactions,
               right_key: :charge_id,
               left_key: :book_transaction_id

  def initialize(*)
    super
    self.opaque_id ||= Suma::Secureid.new_opaque_id("bx")
  end

  def rel_admin_link = "/book-transaction/#{self.id}"

  # Return a copy of the receiver, but with id removed, and amount set to be positive or negative
  # based on whether the receiver is the originating or receiving ledger.
  # This is used in places we need to represent book transactions
  # as ledger line items which have a directionality to them,
  # and we do not have a ledger as the time to determine directionality.
  #
  # The returned instance is frozen so cannot be saved/updated.
  def directed(relative_to_ledger)
    dup = self.values.dup
    case relative_to_ledger
      when self.originating_ledger
        dup[:amount_cents] *= -1
      when self.receiving_ledger
        nil
      else
        raise ArgumentError, "#{relative_to_ledger.inspect} is not associated with #{self.inspect}"
    end
    id = dup.delete(:id)
    inst = self.class.new(dup)
    inst.values[:_directed] = true
    inst.values[:id] = id
    inst.freeze
    return inst
  end

  # Return true if the received is an output of +directed+.
  def directed?
    return self.values.fetch(:_directed, false)
  end

  def debug_description
    return "BookTransaction[#{self.id}] for #{self.amount.format} from " \
           "#{self.originating_ledger.admin_label} to #{self.receiving_ledger.admin_label}"
  end

  UsageDetails = Struct.new(:code, :args)

  # @return [Array<UsageDetails>]
  def usage_details
    result = []
    result.concat(charges.map do |ch|
      code = "misc"
      service_name = self.memo.string
      if ch.mobility_trip
        code = "mobility_trip"
        service_name = ch.mobility_trip.vendor_service.external_name
      elsif ch.commerce_order
        code = "commerce_order"
        service_name = ch.commerce_order.checkout.cart.offering.description.string
      end
      UsageDetails.new(
        code, {
          discount_amount: Suma::Moneyutil.to_h(ch.discount_amount),
          service_name:,
        },
      )
    end)
    result.concat(self.funding_transactions.map do |fx|
      UsageDetails.new("funding", {account_label: fx.strategy.originating_instrument.simple_label})
    end)
    result << UsageDetails.new("unknown", {memo: self.memo.string}) if result.empty?
    return result
  end

  def validate
    super
    self.errors.add(:receiving_ledger_id, "originating and receiving ledgers cannot be the same") if
      self.receiving_ledger_id == self.originating_ledger_id
  end
end

# Table: payment_book_transactions
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                                    | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at                            | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at                            | timestamp with time zone |
#  apply_at                              | timestamp with time zone | NOT NULL
#  opaque_id                             | text                     | NOT NULL
#  originating_ledger_id                 | integer                  |
#  receiving_ledger_id                   | integer                  |
#  associated_vendor_service_category_id | integer                  |
#  amount_cents                          | integer                  | NOT NULL
#  amount_currency                       | text                     | NOT NULL
#  memo                                  | text                     | NOT NULL
# Indexes:
#  payment_book_transactions_pkey                        | PRIMARY KEY btree (id)
#  payment_book_transactions_originating_ledger_id_index | btree (originating_ledger_id)
#  payment_book_transactions_receiving_ledger_id_index   | btree (receiving_ledger_id)
# Check constraints:
#  amount_not_negative | (amount_cents >= 0)
# Foreign key constraints:
#  payment_book_transactions_associated_vendor_service_catego_fkey | (associated_vendor_service_category_id) REFERENCES vendor_service_categories(id)
#  payment_book_transactions_originating_ledger_id_fkey            | (originating_ledger_id) REFERENCES payment_ledgers(id)
#  payment_book_transactions_receiving_ledger_id_fkey              | (receiving_ledger_id) REFERENCES payment_ledgers(id)
# Referenced By:
#  charges_payment_book_transactions | charges_payment_book_transactions_book_transaction_id_fkey      | (book_transaction_id) REFERENCES payment_book_transactions(id)
#  payment_funding_transactions      | payment_funding_transactions_originated_book_transaction_i_fkey | (originated_book_transaction_id) REFERENCES payment_book_transactions(id) ON DELETE RESTRICT
# ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
