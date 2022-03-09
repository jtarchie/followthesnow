# frozen_string_literal: true

require 'active_support'
require 'active_support/time'
require 'erb'
require 'fileutils'
require_relative 'prediction'

Builder = Struct.new(:resorts, :build_dir, :source_dir, :fetcher, keyword_init: true) do
  include ERB::Util

  def build!
    FileUtils.mkdir_p(build_dir)

    file = ERB.new(File.read(File.join(source_dir, 'index.html.erb')))
    File.write(File.join(build_dir, 'index.html'), file.result(binding))
  end

  private

  def by_state
    @by_state ||= predictions.group_by do |prediction|
      prediction.resort.state
    end
  end

  def predictions
    @predictions ||= resorts.sort_by { |r| [r.state, r.name] }.map do |resort|
      Prediction.new(
        fetcher: fetcher,
        resort: resort
      )
    end
  end

  def current_timestamp
    Time.zone = 'Eastern Time (US & Canada)'
    Time.zone.now.strftime(' %a %b %e, %Y %l:%M%p %Z')
  end
end
