# frozen_string_literal: true
require 'httparty'
require 'json'
class PivotalApiProxy
  include HTTParty
  REQUEST_TIMEOUT = 4800
  attr_accessor :api_key, :project_id, :people, :me
  def initialize(api_key:, project_id:)
    @api_key = api_key
    @project_id = project_id
    @me = get("me")
    if @me['code'] == "invalid_authentication"
      raise "Error: Unrecognized API token: " + @me['possible_fix']
    end

    @people = get("my/people?project_id=#{@project_id}")
    if @people['code'] == "unauthorized_operation"
      raise "Error: Bad project ID: " + @pesona['possible_fix']
    end

    @people += [{ "person" => @me }]
  end

  def get(action, query = {})
    query = { query: query }.merge(headers: { "X-TrackerToken" => @api_key })
    JSON.parse(self.class.get(base_url + action, query).body)
  end

  def get_stories(epic_name)
    get("projects/#{project_id}/stories", epic_name ? { "filter" => "epic:\"#{epic_name}\"" } : {})
  end

  def get_blockers(story_id)
    get("projects/#{project_id}/stories/#{story_id}/blockers")
  end

  private

  def base_url
    "https://www.pivotaltracker.com/services/v5/"
  end
end
