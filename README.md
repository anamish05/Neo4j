# Neo4j

Part 1   

<img width="881" height="377" alt="image" src="https://github.com/user-attachments/assets/df4c5715-ecbc-457f-b8be-f6865b3a712f" />  

1. Which entities became nodes and which - edges?
   Nodes are nouns - user, movie, genre, occupation. They are autonomous objects.
   Edges - are relationships, actions. Rated, in genre, has occupation. They connect nodes.  
2. User's rate for a movie — is an edge (User)-[:RATED]->(Movie) or node (Rating)? Explain. Both approaches have real trade-off
   First approach (chosen by me) allows quickly traveres a graph, takes less memory, but does not allow create history of
   changes for reviews or comments to reviews. Second approach allows this, but takes more memory.
3. Why it is more convenient to store genres as nodes and not as list of characteristics of movie?
   For example to find movies with a particular genre DB has to traverse each node to check its genre, so it's O(N).
   However if genre is a node, it's just 1 operation (O(1)).

Part 2  

