# frozen_string_literal: true

module Builder
  # builds each state page
  class Resorts < Page
    include Builder::Renderer

    def build!
      resort_path = File.join(build_dir, 'resorts')
      FileUtils.mkdir_p(resort_path)

      layout_path = File.join(source_dir, '_layout.html.erb')
      resort_file = File.join(source_dir, 'resort.md.erb')

      resorts.each do |resort|
        @resort = resort
        File.write(
          File.join(resort_path, "#{slug(resort.name)}.html"),
          render(
            layout: layout_path,
            page: resort_file
          )
        )
      end
    end

    private

    attr_reader :resort

    def slug(name)
      name.downcase.gsub(/\W+/, '-')
    end
  end
end
