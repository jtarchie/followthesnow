require 'kramdown'

module Builder::Markdown
  def markdown_render(text)
    Kramdown::Document.new(
      text,
      input: 'GFM',
      gfm_emojis: true,
      hard_wrap: false
    ).to_html
  end
end