$LOAD_PATH.unshift File.dirname(__FILE__)
require 'islandora-object-node'

class IslandoraGraph

  # We start with two simple CSVs file: first, model data:
  #
  #     "object-pid,content-model,model-state"
  #
  # and a second that lists parental data:
  #
  #     "object-pid,parent-pid"
  #
  # There can be muliple entries for a given "object-pid".
  # Then produce an adjacency hash that captures the graph structure,
  # it looks as so:
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

  # clean_model(str) returns these kinds of symbols from the RDF database
  #
  # :binaryObjectCModel      :intermediateSerialCModelStub   :rootSerialCModel
  # :bookCModel              :newspaperCModel                :sp-audioCModel
  # :citationCModel          :newspaperIssueCModel           :sp_basic_image
  # :collectionCModel        :newspaperPageCModel            :sp_large_image_cmodel
  # :compoundCModel          :organizationCModel             :sp_pdf
  # :entityCModel            :pageCModel                     :sp_videoCModel
  # :intermediateCModel      :personCModel                   :thesisCModel

  def clean_model(str)
    return str.sub(/.*:/, '').intern
  end

  # clean_state(str) typical returns these kinds of symbols from the RDF data:
  #
  #    :active, :inactive, :deleted
  #
  # and we add
  #
  #    :missing and :loop

  def clean_state(str)
    return str.sub(/.*model#/, '').downcase.intern
  end


  # list of lists of IslandoraObjectNode's, specifically a list of
  # lineages [ grandparent -> parent -> child ], we add parents on the
  # left hand side, finally completing the collection of lineages for
  # the leaf node (lineage.last) when there are no more parents.

  def ancestries_helper(collections, *lineage)
    our_parents = parents(lineage.first)
    if our_parents.empty? # we're at the top of one of the ancestry chains for this child (lineage.last), bail.
      collections.push lineage
    else
      our_parents.each do |parent|
        if lineage.member? parent # strictly speaking, the islandora graph is a tree.. but shit (cycles) do happen...
          lineage.unshift create_psuedo_node(parent.pid, :loop) # add a special inicator node, bail.
          collections.push lineage
        else
          ancestries_helper(collections, parent, *lineage) # keep looking for ancestors, adding new lineages for additional parents.
        end
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
        next unless line =~ /^info:fedora\/.*,info:fedora\//
        child_pid, parent_pid = line.strip.split(',').map { |pid| clean_pid(pid) }
        @adjacency_list[child_pid] = IslandoraObjectNode.new(child_pid, :missing)  unless @adjacency_list[child_pid]
        @adjacency_list[child_pid].add_parent parent_pid
      end
    end
  end

  def load_models(filename)
    open(filename) do |fh|
      while line = fh.gets
        next unless line =~ /^info:fedora\//
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

  def ancestries(node)
    list = []
    ancestries_helper(list, node)
    return list
  end

  # return a list of IslandoraObjectNodes. We create a special missing
  # node for a declared pareent, when we don't find that parent in the
  # model data files.

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
