$LOAD_PATH.unshift File.dirname(__FILE__)
require 'islandora-object-node'



class IslandoraGraph

  # We start with a simple sorted CSV file of
  # "object-pid,content-model,model-state".
  #
  # Here's one way to generate the CSV files (we could also trundle
  # through the FoXML files on-disk):
  #
  # SELECT DISTINCT ?member ?model ?state
  #            FROM <#ri> WHERE
  #          { ?member  <info:fedora/fedora-system:def/model#hasModel> ?model ;
  #                     <fedora-model:state> ?state
  #            FILTER ( ?model != <info:fedora/fedora-system:FedoraObject-3.0> )
  #          }


  # maintain an adjacency hash

  # {
  #   pid => <#node  pid, state, [ content-model* ], [ parent-pid* ]>
  #   pid => <#node  pid, state, [ content-model* ], [ parent-pid* ]>
  # ...
  # }

  def initialize()
    @adjacency_list = {}
  end

  def clean_pid(str)
    return str.sub('info:fedora/','')
  end

  def clean_model(str)
    return str.sub(/.*:/, '').intern
  end

  def clean_state(str)
    return str.sub(/.*model#/, '').downcase.intern
  end

  def load_relationships(filename)
    open(filename) do |fh|
      while line = fh.gets
        next unless line =~ /^.*:.*,.*:.*/
        child_pid, parent_pid = line.strip.split(',')
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

  def lookup(pid)
    return @adjacency_list[pid]
  end

  def create_psuedo_node(pid, sym)
    return IslandoraObjectNode.new(pid, sym)
  end

  # return a list of IslandoraObjectNodes. We create a special missing node, if we don't find one listed.

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