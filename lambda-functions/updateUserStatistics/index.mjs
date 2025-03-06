// Import the Redis client
import { Redis } from '@upstash/redis';

// Initialize the Redis client using environment variables
const redis = new Redis({
  url: process.env.UPSTASH_REDIS_REST_URL,
  token: process.env.UPSTASH_REDIS_TOKEN,
});

// Export the handler function
export const handler = async (event) => {
  try {
    // Parse the request body
    const body = JSON.parse(event.body);
    const {
      userID,
      highestScore,
      longestWord,
      longestWordScore,
      highestScoringWord,
      highestScoringWordScore,
    } = body;

    if (
      !userID ||
      highestScore === undefined ||
      !longestWord ||
      longestWordScore === undefined ||
      !highestScoringWord ||
      highestScoringWordScore === undefined
    ) {
      return {
        statusCode: 400,
        body: JSON.stringify({ error: 'Missing required user statistics' }),
      };
    }

    // Use Redis commands via the client
    // Update highestScore leaderboard
    await redis.zadd('leaderboard:highestScore', {
      score: highestScore,
      member: userID,
    });

    // Update longestWord leaderboard
    await redis.zadd('leaderboard:longestWord', {
      score: longestWordScore,
      member: userID,
    });

    // Update user's stats in a hash
    await redis.hset(`user:${userID}:stats`, {
      longestWord: longestWord,
      highestScoringWord: highestScoringWord,
      highestScoringWordScore: highestScoringWordScore.toString(),
    });

    return {
      statusCode: 200,
      body: JSON.stringify({ message: 'User statistics updated successfully' }),
    };
  } catch (error) {
    console.error('Error updating user statistics:', error);
    return {
      statusCode: 500,
      body: JSON.stringify({ error: error.message }),
    };
  }
};
