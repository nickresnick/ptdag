# frozen_string_literal: true
require './pivotal_dag'
# Need to use ERB to evaluate the FilePath field
config = YAML.safe_load(ERB.new(File.read('./config.yml')).result)

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
