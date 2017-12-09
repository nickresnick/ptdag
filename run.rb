# frozen_string_literal: true
require './pivotal_dag'
config = YAML.load_file('./config.yml')
dag = PivotalDag.new(
  api_key: config['PivotalSettings']['APIKey'],
  project_id: config['PivotalSettings']['ProjectID'],
  epic_name: config['PivotalSettings']['EpicName'],
  include_key: config['GraphSettings']['IncludeKey'],
)
dag.generate_dag(
  config['OutputSettings']['FileFormat'],
  config['OutputSettings']['FilePath'],
)
