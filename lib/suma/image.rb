# frozen_string_literal: true

require "suma/postgres/model"
require "suma/translated_text"

class Suma::Image < Suma::Postgres::Model(:images)
  plugin :timestamps
  plugin :soft_deletes
  plugin :translated_text, :caption, Suma::TranslatedText

  many_to_one :commerce_offering, class: "Suma::Commerce::Offering"
  many_to_one :commerce_product, class: "Suma::Commerce::Product"
  many_to_one :uploaded_file, class: "Suma::UploadedFile"

  class << self
    def no_image_available
      return @no_image_available if @no_image_available
      @no_image_available = self.new(ordinal: 0)
      @no_image_available.associations[:uploaded_file] = Suma::UploadedFile::NoImageAvailable.new
      @no_image_available.freeze
      return @no_image_available
    end
  end

  module AssociatedMixin
    def self.included(m)
      key = m.name.gsub("Suma::", "").gsub("::", "_").underscore + "_id"
      m.one_to_many :images, key: key.to_sym, class: "Suma::Image", order: [:ordinal, :id]
      m.define_method(:images?) do
        if self.images.empty?
          [Suma::Image.no_image_available]
        else
          self.images
        end
      end
    end
  end
end

# Table: images
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
# Columns:
#  id                   | integer                  | PRIMARY KEY GENERATED BY DEFAULT AS IDENTITY
#  created_at           | timestamp with time zone | NOT NULL DEFAULT now()
#  updated_at           | timestamp with time zone |
#  soft_deleted_at      | timestamp with time zone |
#  ordinal              | double precision         | NOT NULL DEFAULT 0
#  uploaded_file_id     | integer                  | NOT NULL
#  commerce_product_id  | integer                  |
#  commerce_offering_id | integer                  |
#  caption_id           | integer                  | NOT NULL
#  vendor_id            | integer                  |
# Indexes:
#  images_pkey                       | PRIMARY KEY btree (id)
#  images_commerce_offering_id_index | btree (commerce_offering_id)
#  images_commerce_product_id_index  | btree (commerce_product_id)
#  images_vendor_id_index            | btree (vendor_id)
# Check constraints:
#  unambiguous_relation | (commerce_product_id IS NOT NULL AND commerce_offering_id IS NULL AND vendor_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NOT NULL AND vendor_id IS NULL OR commerce_product_id IS NULL AND commerce_offering_id IS NULL AND vendor_id IS NOT NULL)
# Foreign key constraints:
#  images_caption_id_fkey           | (caption_id) REFERENCES translated_texts(id)
#  images_commerce_offering_id_fkey | (commerce_offering_id) REFERENCES commerce_offerings(id)
#  images_commerce_product_id_fkey  | (commerce_product_id) REFERENCES commerce_products(id)
#  images_uploaded_file_id_fkey     | (uploaded_file_id) REFERENCES uploaded_files(id)
#  images_vendor_id_fkey            | (vendor_id) REFERENCES vendors(id)
# ----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------
