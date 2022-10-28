# frozen_string_literal: true

require "grape"

require "suma/admin_api"

class Suma::AdminAPI::FundingTransactions < Suma::AdminAPI::V1
  include Suma::AdminAPI::Entities

  resource :funding_transactions do
    params do
      use :pagination
      use :ordering, model: Suma::Payment::FundingTransaction
      use :searchable
    end
    get do
      ds = Suma::Payment::FundingTransaction.dataset
      if (memo_like = search_param_to_sql(params, :memo))
        ds = ds.where(memo_like)
      end
      ds = order(ds, params)
      ds = paginate(ds, params)
      present_collection ds, with: FundingTransactionEntity
    end

    desc "Create a funding transaction and book transfer for the given instrument and its owner's cash ledger."
    params do
      use :payment_instrument
      requires :amount, allow_blank: false, type: JSON do
        use :funding_money
      end
    end
    post :create_for_self do
      instrument_ds = case params[:payment_method_type]
        when "bank_account"
          Suma::Payment::BankAccount.dataset
        else
          raise "Invalid payment_method_type"
      end
      (instrument = instrument_ds[params[:payment_instrument_id]]) or forbidden!
      c = instrument.member
      fx = Suma::Payment::FundingTransaction.start_and_transfer(
        Suma::Payment.ensure_cash_ledger(c),
        amount: params[:amount],
        vendor_service_category: Suma::Vendor::ServiceCategory.find_or_create(name: "Cash"),
        instrument:,
      )
      created_resource_headers(fx.id, fx.admin_link)
      status 200
      present fx, with: DetailedFundingTransactionEntity
    end

    route_param :id, type: Integer do
      helpers do
        def lookup_funding_transaction!
          (o = Suma::Payment::FundingTransaction[params[:id]]) or forbidden!
          return o
        end
      end

      get do
        o = lookup_funding_transaction!
        present o, with: DetailedFundingTransactionEntity
      end
    end
  end

  class DetailedFundingTransactionEntity < FundingTransactionEntity
    include Suma::AdminAPI::Entities
    include AutoExposeDetail
    expose :memo
    expose :platform_ledger, with: SimpleLedgerEntity
    expose :originated_book_transaction, with: BookTransactionEntity
    expose :audit_logs, with: AuditLogEntity
  end
end
