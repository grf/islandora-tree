$LOAD_PATH.unshift File.dirname(__FILE__)
require 'islandora-object-node'

class IslandoraGraph

  # We start with two simple CSVs file: first, model data:
  #
  # "object-pid,content-model,model-state"
  #
  # and a second that lists parental data:
  #
  # "object-pid,parent-pid"
  #
  # There can be muliple entries for a given "object-pid".
  #
  # Produce an adjacency hash that captures the graph structure, it looks as so:
  #
  # {
  #   pid => <#node  pid, state, [ content-model* ], [ parent-pid* ]>
  #   pid => <#node  pid, state, [ content-model* ], [ parent-pid* ]>
  # ...
  # }

  def initialize()
    @adjacency_list = {}
  end

  private

  def clean_pid(str)
    return str.sub('info:fedora/','')
  end

  def clean_model(str)
    return str.sub(/.*:/, '').intern
  end

  def clean_state(str)
    return str.sub(/.*model#/, '').downcase.intern
  end

  # list of lists of IslandoraObjectNode's, as in [ grandparent -> parent -> child ], we add parents on the left hand side.

  def ancestry_helper(collections, *lineage)
    ancestors = parents(lineage.first)
    collections.push lineage if ancestors.empty?
    ancestors.each do |parent|
      if lineage.member? parent
        lineage.unshift create_psuedo_node(parent.pid, :loop)
        collections.push lineage
      else
        ancestry_helper(collections, parent, *lineage)
      end
    end
  end

  def create_psuedo_node(pid, sym)
    return IslandoraObjectNode.new(pid, sym)
  end

  public

  def lookup(pid)
    return @adjacency_list[pid]
  end

  def load_relationships(filename)
    open(filename) do |fh|
      while line = fh.gets
        next unless line =~ /^.*:.*,.*:.*/
        child_pid, parent_pid = line.strip.split(',').map { |pid| clean_pid(pid) }
        @adjacency_list[child_pid] = IslandoraObjectNode.new(child_pid, :missing)  unless @adjacency_list[child_pid]
        @adjacency_list[child_pid].add_parent parent_pid
      end
    end
  end

  def load_models(filename)
    open(filename) do |fh|
      while line = fh.gets
        next unless line =~ /^info:fedora/
        pid, model, state = line.strip.split(',')
        pid   = clean_pid(pid)
        model = clean_model(model)
        state = clean_state(state)
        if node = @adjacency_list[pid]
          node.add_content_model model
          node.content_models.delete_if { |redundant| redundant == :entityCModel }
        else
          @adjacency_list[pid] = IslandoraObjectNode.new(pid, state, model)
        end
      end
    end
  end

  def node_count
    return @adjacency_list.count
  end

  def edge_count
    count = 0
    @adjacency_list.each { |k, v| count += v.parents.length }
    return count
  end

  def ancestry(node)
    list = []
    ancestry_helper(list, node)
    return list
  end

  # return a list of IslandoraObjectNodes. We create a special missing node, if we don't find one from the model data files.

  def parents(node)
    plist = []
    node.parents.each do |pid|
      parent = lookup(pid)
      unless parent
        parent = create_psuedo_node(pid, :missing)
        @adjacency_list[pid] = parent
      end
      plist.push parent
    end
    return plist
  end

  def each()
    @adjacency_list.values.each { |val| yield val }
  end

end
