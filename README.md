# islandora-tree
Some ruby/sparql code to construct an adjacency graph of islandora objects.

The idea is to list all of the Islandora objects and their interesting properties: parents, models and state (active, deleted, inactive) and build an adjacency data structure which describes the islandora object hierarchy (there may be cycles, but that's bad - it should, strcitly,  be a tree).

Given that data, we can find orphaned and missing objects, perhaps other degenerate conditions.

## Get the Data, First

In the lib/ folder there are two files that give sparql queries: run them as so:

'''scripts/ri-query model-states.sparql > model-states.csv'''

'''scripts/ri-query parents.sparql > parents.csv'''

## Crunch

Then use the utility scripts:

### Find Orphaned Objects:

'''scripts/list-orphans model-states.sparql parents.sparql > orphans.out'''

### List all Ancestors From Parent -> Child

'''scripts/list-lineages model-states.sparql parents.sparql > lineages.out'''

Check the data and fix inconsistencies.
