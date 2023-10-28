# frozen_string_literal: true

namespace :import do
  desc 'Import PDF to CSV, usage: rake import:pdf_to_csv /path/to/input.pdf'

  task pdf_to_csv: :environment do
    reader = PDF::Reader.new(ARGV[1])
    tokenizer = Tokenizers.from_pretrained('gpt2')

    CSV.open("#{OpenAiConfig::CSV_PATH}.csv", 'wb') do |csv|
      csv << %w[title content tokens]

      reader.pages.each_with_index do |page, index|
        text = page.text.strip.gsub("\n", ' ')
        encoded = tokenizer.encode(text)
        puts "Processing page #{index + 1} / #{reader.pages.length}"
        csv << ["Page #{index + 1}", page.text.strip.gsub("\n", ' '), encoded.tokens.length]
      end
    end

    Rails.cache.delete OpenAiConfig::CACHE_KEY
  end

  task pdf_to_csv_embedding: :environment do
    embeddings = OpenAiEmbeddings.new
    reader = PDF::Reader.new(ARGV[1])
    embeddings.generate_embeddings_csv_from_pdf!(reader)
    Rails.cache.delete OpenAiConfig::CACHE_KEY
  end
end
