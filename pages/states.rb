# frozen_string_literal: true

module Builder
  # builds each state page
  class States < Page
    include Builder::Renderer
    include ERB::Util

    def build!
      states_dir = File.join(build_dir, 'states')

      states.each do |state|
        Builder::Index.new(
          build_dir: states_dir,
          fetcher: fetcher,
          resorts: resorts_for_state(state),
          source_dir: source_dir
        ).build!(output_filename: "#{state.downcase.gsub(/\W+/, '-')}.html")
      end
    end

    private

    def states
      resorts_by_state.keys.sort
    end

    def resorts_for_state(state)
      resorts_by_state[state]
    end

    def resorts_by_state
      @resorts_by_state ||= resorts.group_by(&:state)
    end
  end
end
