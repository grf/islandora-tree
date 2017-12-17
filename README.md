# islandora-tree
ruby/sparql code to construct an adjacency graph of islandora objects 

The idea is to list all of the Islandora objects and their interesting properties: parents, models and state (active, deleted, inactive) and build an adjacency data structure which describes the islandora object hierarchy (there may be cycles, but that's bad - it should, strcitly,  be a tree).

Given that data, we can find orphaned and missing objects, perhaps other degenerate conditions.
