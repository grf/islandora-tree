# islandora-tree
Some ruby/sparql code to construct an adjacency graph of islandora objects.

The idea is to list all of the Islandora objects and their interesting properties: parents, models and state (:active, :deleted, and :inactive) and build an adjacency data structure which describes the islandora object hierarchy (there may be cycles, but that's bad - it should, strcitly,  be a tree). We add some other states: :missing and :loop, for problem childrens.

Given that data, we can find orphaned and missing objects, perhaps other degenerate conditions.

## Get the Data, First

In the lib/ folder there are two files that give sparql queries: run them as so:

``scripts/ri-query lib/model-states.sparql > model-states.csv``

``scripts/ri-query lib/parents.sparql > parents.csv``

The ``ri-query`` program uses ``localhost:8080`` to find the Islandora RDF endpoint: normally, this means you need to execute the ``ri-timer`` script on the Islandora server.

## Crunch

Then use the utility scripts:

### Find Orphaned Objects:

``scripts/list-orphans model-states.csv parents.csv > orphans.out``

### List all Ancestors From Parent -> Child

``scripts/list-lineages model-states.csv parents.csv > lineages.out``

## Fix

Check the data in the ``out`` files and fix inconsistencies.

## Note

Each step may take several minutes (at the time of this writing we have > 800,000 objects): this is not an interactive process.
