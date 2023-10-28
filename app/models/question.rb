# frozen_string_literal: true

class Question < ApplicationRecord
  validates :query, :answer, presence: true, length: { maximum: 65_535 }
end
