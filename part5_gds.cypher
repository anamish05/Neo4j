// 3.1. Запуск та запис PageRank у базу даних
CALL gds.pageRank.write(
  'movieGraph',
  {
    relationshipWeightProperty: 'weight',
    writeProperty: 'pageRank',
    dampingFactor: 0.85,
    maxIterations: 20
  }
)
YIELD nodePropertiesWritten, computeMillis;

// 3.2. Виведення Top-10 найвпливовіших фільмів
MATCH (m:Movie)
WHERE m.pageRank IS NOT NULL
RETURN m.title AS title, m.pageRank AS score
ORDER BY score DESC
LIMIT 10;

CALL gds.graph.project(
  'userSimilarity',
  ['User'],
  ['SIMILAR'],
  {
    relationshipProperties: ['weight'],
    memory: '2GB'
  }
)
YIELD graphName, nodeCount, relationshipCount;

CALL gds.louvain.stream('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
WITH gds.util.asNode(nodeId) AS user, communityId

// Шукаємо фільми з високими оцінками для кожного користувача спільноти
MATCH (user)-[r:RATED]->(m:Movie)-[:IN_GENRE]->(g:Genre)
WHERE r.rating >= 4

// Агрегуємо жанри за спільнотами
WITH communityId, g.name AS genre, count(*) AS score
ORDER BY score DESC
WITH communityId, collect(genre)[..3] AS top3Genres

RETURN communityId, top3Genres
LIMIT 10;

CALL gds.louvain.stats('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD modularity, communityCount;

CALL gds.louvain.stream('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
WITH gds.util.asNode(nodeId) AS user, communityId

// Рахуємо кількість користувачів у кожному кластері
WITH communityId, collect(user) AS users, count(user) AS clusterSize
WHERE clusterSize > 10 // Аналізуємо лише достатньо великі кластери

UNWIND users AS user
MATCH (user)-[r:RATED]->(m:Movie)-[:IN_GENRE]->(g:Genre)
WHERE r.rating >= 4

// Збираємо популярні фільми та жанри всередині кластера
WITH communityId, clusterSize, 
     g.name AS genre, count(DISTINCT g) AS genreCount,
     m.title AS movieTitle, count(DISTINCT user) AS movieWatchers

ORDER BY movieWatchers DESC

RETURN communityId,
       clusterSize,
       collect(DISTINCT movieTitle)[..5] AS topMoviesInCluster,
       collect(DISTINCT genre)[..5] AS topGenres
ORDER BY clusterSize DESC
LIMIT 5;

CALL gds.louvain.stream('userSimilarity', {
  relationshipWeightProperty: 'weight'
})
YIELD nodeId, communityId
WITH gds.util.asNode(nodeId) AS user, communityId

// Рахуємо кількість користувачів у кожному кластері
WITH communityId, collect(user) AS users, count(user) AS clusterSize
WHERE clusterSize > 10 // Аналізуємо лише достатньо великі кластери

UNWIND users AS user
MATCH (user)-[r:RATED]->(m:Movie)-[:IN_GENRE]->(g:Genre)
WHERE r.rating >= 4

// Збираємо популярні фільми та жанри всередині кластера
WITH communityId, clusterSize, 
     g.name AS genre, count(DISTINCT g) AS genreCount,
     m.title AS movieTitle, count(DISTINCT user) AS movieWatchers

ORDER BY movieWatchers DESC

RETURN communityId,
       clusterSize,
       collect(DISTINCT movieTitle)[..5] AS topMoviesInCluster,
       collect(DISTINCT genre)[..5] AS topGenres
ORDER BY clusterSize DESC
LIMIT 5;

// 3.2. Перевірка спільних фільмів між першою парою користувачів у ланцюжку
MATCH (u1:User {userId: 65})-[r1:RATED]->(m:Movie)<-[r2:RATED]-(u2:User {userId: 207})
WHERE r1.rating >= 4 AND r2.rating >= 4
RETURN m.title AS sharedMovie, r1.rating AS ratingUser1, r2.rating AS ratingUser2
LIMIT 5;
