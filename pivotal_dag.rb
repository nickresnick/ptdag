require "./pivotal_api_proxy"
gem 'byebug'
gem 'ruby-graphviz'
require 'ruby-graphviz'
require 'byebug'
class PivotalDag
  attr_accessor :stories, :vertices, :dag
  def initialize(api_key:, project_id:, epic_name: nil)
    @proxy = PivotalApiProxy.new(api_key: api_key, project_id: project_id)
    @epic_name = epic_name
    @stories = @proxy.get_stories(@epic_name)
    @dag = GraphViz.new(
      :G,
      {
        type: :digraph,
        label: "Graph for #{epic_name || @proxy.project_id}",
        fontsize: 60,
        labelloc: "t",
        fontname: "Verdana",
        nodesep: 2,
        ranksep: 2,
        rankdir: "LR"
      },
    )
    add_key
  end

  def get_blockers(story_id)
    @proxy.get_blockers(story_id)
  end

  def vertices
    @vertices ||= @stories.map do |story|
      attributes = case story["story_type"]
      when "feature"
        feature_attributes(story)
      when "chore"
        chore_attributes(story)
      when "bug"
        bug_attributes(story)
      when "release"
        release_attributes(story)
      end
      @dag.add_node(
        story["id"].to_s,
        attributes.merge(URL: story["url"], width: (story['estimate'] || 3) + 5, height: (story['estimate'] || 3) + 5),
      )
    end
  end

  def generate_dag
    vertices.each do |vertex|
      blockers = get_blockers(vertex.id)
      blockers.each do |blocker|
        @dag.add_edges(
          vertices.find { |v| v.id == blocker["description"][1..-1] },
          vertex,
          {
            arrowsize: 3,
          }
        )
      end
    end
    @dag
  end

  private

  def feature_attributes(story)
    {
      label: node_label(story),
      fontsize: (story['estimate'] || 3) * 2 + 25,
      fontname: "Verdana",
      style: :filled,
      shape: :record,
      fillcolor: node_color(story),
    }
  end

  def bug_attributes(story)
    feature_attributes(story).merge(fillcolor: "red")
  end

  def release_attributes(story)
    feature_attributes(story).merge(
      label: node_title(story),
      shape: :circle,
      fillcolor: story['current_state'] == "accepted" ? node_color(story) : "maroon",
      fontname: "Comic Sans MS",
    )
  end

  def chore_attributes(story)
    feature_attributes(story)
  end

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

      #{find_owners(story).join(", ")}

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
end
