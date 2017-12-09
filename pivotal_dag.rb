# frozen_string_literal: true
require "./pivotal_api_proxy"
require 'ruby-graphviz'
class PivotalDag
  attr_accessor :stories, :vertices, :dag
  def initialize(api_key:, project_id:, epic_name: nil, include_key: true)
    parse_config(YAML.load_file('./config.yml'))
    @proxy = PivotalApiProxy.new(api_key: api_key, project_id: project_id)
    @epic_name = epic_name
    @stories = @proxy.get_stories(@epic_name)
    @dag = GraphViz.new(
      :G,
      type: :digraph,
      label: @graph_settings['GraphLabel'] || "Graph for #{epic_name || @proxy.project_id}",
      fontsize: @graph_settings['FontSize'],
      labelloc: @graph_settings['LabelLocation'],
      fontname: @graph_settings['Verdana'],
      nodesep: @graph_settings['NodeSeparation'],
      ranksep: @graph_settings['RankSeparation'],
      rankdir: @graph_settings['RankDirection'],
    )
    add_key if include_key
  end

  def get_blockers(story_id)
    @proxy.get_blockers(story_id)
  end

  def vertices
    @vertices ||= @stories.map do |story|
      attributes = node_attributes(story)
      @dag.add_node(
        story["id"].to_s,
        attributes.merge(
          URL: @node_settings['IncludeURL'] ? story["url"] : nil,
          width: @node_settings['width'] || (story['estimate'] || 3) + 5,
          height:  @node_settings['height'] || (story['estimate'] || 3) + 5,
        ),
      )
    end
  end

  def generate_dag(file_format, file_path)
    vertices.each do |vertex|
      blockers = get_blockers(vertex.id)
      blockers.each do |blocker|
        @dag.add_edges(
          vertices.find { |v| v.id == blocker["description"][1..-1] },
          vertex, arrowsize: @edge_settings['ArrowSize']
        )
      end
    end
    @dag.output(file_format.to_sym => file_path)
  end

  private

  def node_title(story)
    title = story['name']
    split_counter = 0
    splits = []
    character_count = 0
    (0...title.length).each do |i|
      if (i - character_count >= 25 && title[i] == " ") || i == title.length - 1
        splits << title[character_count..i]
        split_counter += 1
        character_count = i
      end
    end
    splits.join("\n")
  end

  def node_label(story)
    <<~LABEL
      #{node_title(story)}

      #{story['id']}

      #{find_owners(story).join(', ')}

      Points: #{story['estimate']}
    LABEL
  end

  def node_color(story)
    case story["current_state"]
    when "unstarted"
      "grey" # grey
    when "started" || "finished"
      "deepskyblue" # blue
    when "delivered"
      "goldenrod"
    when "accepted"
      "mediumseagreen" # green
    end
  end

  def find_owners(story)
    owners = story['owner_ids'].map do |id|
      @proxy.people.find { |h| h['person']['id'] == id }['person']['name']
    end

    owners.empty? ? ["No Owner"] : owners
  end

  def add_key
    story_states = @stories.uniq { |story| story['current_state'] }
    key_line = proc { |story| [node_color(story), '=', story['current_state']].join(' ') }
    label = <<~LABEL
      Key
      #{story_states.map { |story| key_line.call(story) }.join('\n')}
    LABEL
    @dag.add_node("Key", label: label, color: "white", fontsize: 40, fontname: "Verdana")
  end

  def parse_config(yml)
    @pivotal_settings ||= yml['PivotalSettings']
    @output_sttings   ||= yml['OutputSettings']
    @graph_settings   ||= yml['GraphSettings']
    @node_settings    ||= yml['NodeSettings']
    @edge_settings    ||= yml['EdgeSettings']
  end

  def node_attributes(story)
    attribute_name = case story['story_type']
    when 'feature'
      'FeatureAttributes'
    when 'bug'
      'BugAttributes'
    when 'release'
      'ReleaseAttributes'
    when 'chore'
      'ChoreAttributes'
    else
      raise "Invalid node_type: #{node_type}"
    end
    attrs = @node_settings[attribute_name]
    {
      label: attrs['Label'] || node_label(story),
      fontsize: attrs['FontSize'] || (story['estimate'] || 3) * 2 + 25,
      fontname: attrs['FontType'],
      style: attrs['Style'],
      shape: attrs['Shape'],
      fillcolor: attrs['FillColor'] || node_color(story),
    }
  end
end
