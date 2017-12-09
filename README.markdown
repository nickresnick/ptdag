# Description
ptdag is an application for generating [directed acyclic graph](https://en.wikipedia.org/wiki/Directed_acyclic_graph) visualizations of PivotalTracker projects or epics.

At [custora](https://custora.com/), we use [PivotalTracker](https://www.pivotaltracker.com) to scope, plan, and manage engineering projects across our software development and data science teams. One thing that always frustrated me about Pivotal is that it's really hard to grasp certain aspects of a project from the UI: How big is the scope of the project? Where are the bottlenecks? Are there any unhashed dependencies? Can we parallelize tasks?

I built ptdag to help answer these questions. Each node in the graph represents a pivotal story, and each edge that points from node A to node B signifies that node B depends on the completion of node A. The app includes features for scaling the size of the node based on the amount of points on the story, as well as color encoding based on story status and story type.

ptdag runs on the robust [GraphViz](http://www.graphviz.org/) infrastructure through the [ruby-graphviz gem](https://github.com/glejeune/Ruby-Graphviz). I recommend looking through the examples directory of that gem for some cool implementations of graph visualizations.

# Generating a Graph
Generating a graph is easy. All you need is...
1. Your PivotalTracker API token. You can find this by clicking on Profile under your username in the top right corner of the Pivotal home screen after signing in.
2. The id of the project. You can find this most easily by clicking into the project of interest and looking at the seven digit number in the URL.
3. (Optional) If you want to generate a DAG for a particular epic, you can supply the epic name _exactly_ as it appears on the Pivotal UI.
4. A file path and file format for your sweet new graph

Place these values under the PivotalSettings and OutputSettings headers in config.yml, like so:
```
PivotalSettings:
  APIKey: f00bar
  ProjectID: 0000000
  EpicName: My Epic

OutputSettings:
  FileFormat: pdf
  FilePath: ~/pivotal_dag.pdf
```

config.yml is your home for all graph settings. It includes GraphAttributes, NodeAttributes, and EdgeAttributes, all of which are passed through to GraphViz. As of writing, only a small subset of GraphViz's configs are supported in this app, and I plan to make it more flexible over time.

To run the script after config.yml has been updated, simply run
```
ruby run.rb
```
in the ptdag directory. This will create a file according to the file format and
file path you entered in the config file.

# Specs and Dependencies
Generated automatically by bundler (see Gemfile.lock)
```
GEM
  remote: https://rubygems.org/
  specs:
    httparty (0.15.6)
      multi_xml (>= 0.5.2)
    json (2.1.0)
    multi_xml (0.6.0)
    ruby-graphviz (1.2.3)

PLATFORMS
  ruby

DEPENDENCIES
  httparty
  json
  ruby-graphviz

BUNDLED WITH
   1.16.0
```
