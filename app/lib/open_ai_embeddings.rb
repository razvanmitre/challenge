# frozen_string_literal: true

# Uses OpenAi to extract embeddings information.
class OpenAiEmbeddings
  def initialize
    @openai_client = OpenAI::Client.new
  end

  def answer_query_with_context(query)
    prompt = construct_prompt(query)
    response = @openai_client.completions(
      parameters: {
        prompt: prompt[:prompt],
        # We use temperature of 0.0 because it gives the most predictable, factual answer.
        temperature: 0.0,
        max_tokens: 150,
        model: OpenAiConfig::COMPLETIONS_MODEL
      }
    )

    {
      answer: response['choices'][0]['text'].strip,
      context: prompt[:context]
    }
  end

  def generate_embeddings_csv_from_pdf!(pdf_reader)
    CSV.open(OpenAiConfig::CSV_EMBEDDINGS_PATH, 'wb') do |csv|
      csv << ['title'] + (0..OpenAiConfig::MAX_COLS).to_a

      pdf_reader.pages.each_with_index do |page, index|
        csv << ["Page #{index + 1}"] + get_embedding(page.text.strip.gsub("\n", ' '), OpenAiConfig::DOC_EMBEDDINGS_MODEL)
      end
    end
  end

  private

  def get_embedding(text, model)
    response = @openai_client.embeddings(
      parameters: {
        model:,
        input: text
      }
    )
    response.dig('data', 0, 'embedding')
  end

  def load_embeddings_csv
    book = []

    CSV.foreach(OpenAiConfig::CSV_PATH, headers: true) do |row|
      row_hash = row.to_hash

      book.push({
                  title: row_hash['title'],
                  content: row_hash['content'],
                  tokens: row_hash['tokens']
                })
    end

    CSV.foreach(OpenAiConfig::CSV_EMBEDDINGS_PATH, headers: true) do |row|
      book_row = book.find { |el| el[:title] == row['title'] }
      book_row[:embedding] = []

      (0..OpenAiConfig::MAX_COLS).each do |col|
        book_row[:embedding].push(row[col.to_s])
      end
    end

    book
  end

  def construct_prompt(query)
    context_embeddings = Rails.cache.fetch(OpenAiConfig::CACHE_KEY) do
      load_embeddings_csv
    end

    ordered_document_sections = order_document_sections_by_query_similarity(query, context_embeddings)

    chosen_sections = []
    chosen_sections_len = 0

    ordered_document_sections.each do |section|
      chosen_sections.append(OpenAiConfig::SEPARATOR + section[:content])
      chosen_sections_len += section[:tokens].to_i + OpenAiConfig::SEPARATOR.length
      break if chosen_sections_len > OpenAiConfig::MAX_SECTION_LEN
    end

    header = OpenAiConfig::HEADER
    quetions = OpenAiConfig::QUESTIONS.join('')

    {
      prompt: "#{header} #{chosen_sections.join('')} #{quetions}\n\n\nQ: #{query}\n\nA: ",
      context: chosen_sections.join('')
    }
  end

  def order_document_sections_by_query_similarity(query, context_embeddings)
    query_embedding = get_embedding(query, OpenAiConfig::QUERY_EMBEDDINGS_MODEL)

    context_embeddings.each do |context|
      context[:similarity] = vector_similarity(query_embedding, context[:embedding])
    end

    context_embeddings.sort_by { |context| -1 * context[:similarity] }
  end

  def vector_similarity(arr1, arr2)
    a = Vector.elements(arr1.map(&:to_f))
    b = Vector.elements(arr2.map(&:to_f))
    a.inner_product(b)
  end
end
