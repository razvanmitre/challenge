# frozen_string_literal: true

module V1
  class BookController < ApplicationController
    def question
      return head :unprocessable_entity if params[:q].blank?

      query = params[:q].squeeze(' ').strip.tr("\n", ' ').downcase

      question = Question.find_by(query:)

      if question.nil?
        embeddings = OpenAiEmbeddings.new
        answer = embeddings.answer_query_with_context(query)[:answer]
        question = Question.create(query:, answer:)
      end

      render json: { answer: question.answer }
    end
  end
end
