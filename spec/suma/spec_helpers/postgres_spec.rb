# frozen_string_literal: true

require "rspec/matchers/fail_matchers"

require "suma/spec_helpers/postgres"

RSpec.describe Suma::SpecHelpers::Postgres, :db do
  include RSpec::Matchers::FailMatchers

  describe "have_row matcher" do
    let(:model) { Suma::Postgres::TestingPixie }

    before(:each) do
      model.create(name: "donna")
    end

    it "looks for a row with the given criteria" do
      expect(model).to have_row(name: "donna")

      expect do
        expect(model).to have_row(name: "ma")
      end.to fail_with(/Expected Suma::Postgres::TestingPixie to have a row matching criteria/)
    end

    it "matches found rows against attributes" do
      expect(model).to have_row(name: "donna").with_attributes(id: be_an(Integer))

      expect do
        expect(model).to have_row(name: "donna").with_attributes(id: be_an(String))
      end.to fail_with(/Row found but matcher failed with:/)
    end
  end

  describe "have_same_ids_as matcher" do
    def item(id)
      return [double(id:), {id:}, {"id" => id}].sample
    end

    def collection
      return Array.new(5) { |i| item(i) }
    end

    it "matches collects with the same IDs in whatever order" do
      expect(collection.shuffle).to have_same_ids_as(collection.shuffle)
    end

    it "fails if collections are not of the same length" do
      expect do
        expect(collection + [item(6)]).to have_same_ids_as(collection)
      end.to fail_with(/expected ids/)
    end

    it "can use variadic expected" do
      item1 = item(1)
      item2 = item(2)
      expect([item1, item2]).to have_same_ids_as(item1, item2)
    end
  end

  describe "check_transaction" do
    let(:db) { Suma::Postgres::TestingPixie.db }

    it "fails if in a transaction" do
      db.transaction do
        expect do
          Suma::Postgres.check_transaction(db, "")
        end.to raise_error(Suma::Postgres::InTransaction)
      end
    end

    it "can disable the transaction check", :no_transaction_check do
      db.transaction do
        expect do
          Suma::Postgres.check_transaction(db, "")
        end.to_not raise_error
      end
    end
  end
end
