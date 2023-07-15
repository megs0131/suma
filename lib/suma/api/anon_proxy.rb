# frozen_string_literal: true

require "suma/api"

class Suma::API::AnonProxy < Suma::API::V1
  include Suma::API::Entities

  resource :anon_proxy do
    resource :vendor_accounts do
      get do
        member = current_member
        status 200
        present_collection Suma::AnonProxy::VendorAccount.for(member), with: AnonProxyVendorAccountEntity
      end

      params do
        requires :latest_vendor_account_ids_and_access_codes, type: Array[JSON] do
          requires :id, type: Integer
          requires :latest_access_code, type: String
        end
      end
      post :poll_for_new_access_codes do
        # See commit that added this code for an explanation.
        member = current_member
        latest_codes_by_id = params[:latest_vendor_account_ids_and_access_codes].
          to_h { |h| [h[:id], h[:latest_access_code]] }
        ds = member.anon_proxy_vendor_accounts_dataset.
          where(Sequel[id: latest_codes_by_id.keys] & Sequel.~(latest_access_code: nil)).
          where { latest_access_code_set_at > Suma::AnonProxy::VendorAccount::RECENT_ACCESS_CODE_CUTOFF.ago }.
          exclude(latest_access_code: latest_codes_by_id.values.compact)
        started_polling = Time.now
        found_change = false
        loop do
          found_change = !ds.empty?
          break if found_change
          elapsed = Time.now - started_polling
          break if elapsed > Suma::AnonProxy.access_code_poll_timeout
          Kernel.sleep(Suma::AnonProxy.access_code_poll_interval)
        end
        items = found_change ? Suma::AnonProxy::VendorAccount.for(member) : []
        status 200
        present({items:, found_change:}, with: AnonProxyVendorAccountPollResultEntity)
      end

      route_param :id, type: Integer do
        helpers do
          def lookup
            c = current_member
            apva = c.anon_proxy_vendor_accounts_dataset[params[:id]]
            merror!(403, "No anonymous proxy vendor account with that id", code: "resource_not_found") if
              apva.nil?
            merror!(409, "Anon proxy vendor config is not enabled", code: "resource_not_found") unless
              apva.configuration.enabled?
            return apva
          end
        end

        post :configure do
          apva = lookup
          apva.provision_contact
          status 200
          present(
            apva,
            with: MutationAnonProxyVendorAccountEntity,
            all_vendor_accounts: Suma::AnonProxy::VendorAccount.for(current_member),
          )
        end
      end
    end
  end

  class AnonProxyVendorAccountEntity < BaseEntity
    include Suma::API::Entities
    expose :id
    expose :email
    expose :email_required?, as: :email_required
    expose :sms
    expose :sms_required?, as: :sms_required
    expose :address
    expose :address_required?, as: :address_required
    expose :instructions do |va|
      txt = va.configuration.instructions.string
      txt % {address: va.address || ""}
    end
    expose :app_launch_link, &self.delegate_to(:configuration, :app_launch_link)
    expose :vendor_name, &self.delegate_to(:configuration, :vendor, :name)
    expose :vendor_slug, &self.delegate_to(:configuration, :vendor, :slug)
    expose :vendor_image, with: ImageEntity, &self.delegate_to(:configuration, :vendor, :images, :first)
    expose :latest_access_code_if_recent, as: :latest_access_code
  end

  class MutationAnonProxyVendorAccountEntity < AnonProxyVendorAccountEntity
    include Suma::API::Entities
    expose :all_vendor_accounts, with: AnonProxyVendorAccountEntity do |_inst, opts|
      opts.fetch(:all_vendor_accounts)
    end
  end

  class AnonProxyVendorAccountPollResultEntity < BaseEntity
    expose :found_change
    expose :items, with: AnonProxyVendorAccountEntity
  end
end
