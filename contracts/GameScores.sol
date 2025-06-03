// SPDX-License-Identifier: MIT
pragma solidity ^0.8.28;
import "@openzeppelin/contracts/access/Ownable.sol";

contract GameScores is Ownable {
    constructor(address initialOwner) Ownable(initialOwner) {}

    struct ScoreEntry {
        string playerId;
        string username;
        uint256 score;
        uint256 timestamp;
    }

    uint256 private constant MAX_SCORES_PER_PLAYER = 50;
    
    mapping(string => ScoreEntry[]) public scoreHistory;
    mapping(string => uint256) public highestScore;
    mapping(string => bool) public playerExists;
    uint256 public totalPlayers;

    event ScoreSubmitted(string playerId, string username, uint256 score, uint256 timestamp);
    event ScoreRemoved(string playerId, string username, uint256 score, uint256 timestamp);

    function submitScore(string memory _playerId, string memory _username, uint256 _score) external onlyOwner {
        require(_score > 0, "Score must be greater than 0");
        require(bytes(_playerId).length > 0, "Player ID cannot be empty");
        require(bytes(_username).length > 0, "Username cannot be empty");
        
        ScoreEntry[] storage playerScores = scoreHistory[_playerId];
        
        // Update highest score if needed
        if (_score > highestScore[_playerId]) {
            highestScore[_playerId] = _score;
        }

        // If this is a new player, increment total players
        if (!playerExists[_playerId]) {
            playerExists[_playerId] = true;
            totalPlayers++;
        }

        // If we haven't reached the limit, insert in sorted order
        if (playerScores.length < MAX_SCORES_PER_PLAYER) {
            // Find the correct position to insert
            uint256 insertIndex = playerScores.length;
            for (uint256 i = 0; i < playerScores.length; i++) {
                if (_score < playerScores[i].score) {
                    insertIndex = i;
                    break;
                }
            }
            
            // Add a new element to the array
            playerScores.push(ScoreEntry({
                playerId: _playerId,
                username: _username,
                score: 0,
                timestamp: 0
            }));
            
            // Shift elements to make room for new score
            for (uint256 i = playerScores.length - 1; i > insertIndex; i--) {
                playerScores[i] = playerScores[i - 1];
            }
            
            // Insert new score
            playerScores[insertIndex] = ScoreEntry({
                playerId: _playerId,
                username: _username,
                score: _score,
                timestamp: block.timestamp
            });
        } else {
            // If we're at the limit, only insert if score is lower than the highest score
            if (_score < playerScores[MAX_SCORES_PER_PLAYER - 1].score) {
                // Find the correct position to insert
                uint256 insertIndex = MAX_SCORES_PER_PLAYER - 1;
                for (uint256 i = 0; i < MAX_SCORES_PER_PLAYER - 1; i++) {
                    if (_score < playerScores[i].score) {
                        insertIndex = i;
                        break;
                    }
                }
                
                // Emit event for the score being removed
                emit ScoreRemoved(
                    _playerId,
                    playerScores[MAX_SCORES_PER_PLAYER - 1].username,
                    playerScores[MAX_SCORES_PER_PLAYER - 1].score,
                    playerScores[MAX_SCORES_PER_PLAYER - 1].timestamp
                );
                
                // Shift elements to make room for new score
                for (uint256 i = MAX_SCORES_PER_PLAYER - 1; i > insertIndex; i--) {
                    playerScores[i] = playerScores[i - 1];
                }
                
                // Insert new score
                playerScores[insertIndex] = ScoreEntry({
                    playerId: _playerId,
                    username: _username,
                    score: _score,
                    timestamp: block.timestamp
                });
            }
        }

        emit ScoreSubmitted(_playerId, _username, _score, block.timestamp);
    }

    function getScoreCountForPlayer(string memory _playerId) external view returns (uint256) {
        return scoreHistory[_playerId].length;
    }

    function getScoreByIndexForPlayer(string memory _playerId, uint256 index) external view returns (uint256, uint256) {
        require(index < scoreHistory[_playerId].length, "Invalid score index");
        ScoreEntry memory entry = scoreHistory[_playerId][index];
        return (entry.score, entry.timestamp);
    }

    function getAllScoresForPlayer(string memory _playerId) external view returns (uint256[] memory scores, uint256[] memory timestamps) {
        ScoreEntry[] storage playerScores = scoreHistory[_playerId];
        uint256 length = playerScores.length;
        
        scores = new uint256[](length);
        timestamps = new uint256[](length);
        
        // Copy scores in ascending order
        for (uint256 i = 0; i < length; i++) {
            scores[i] = playerScores[i].score;
            timestamps[i] = playerScores[i].timestamp;
        }
        
        return (scores, timestamps);
    }

    function getLatestScore(string memory _playerId) external view returns (uint256 score, uint256 timestamp, string memory username) {
        require(playerExists[_playerId], "Player does not exist");
        ScoreEntry[] storage playerScores = scoreHistory[_playerId];
        require(playerScores.length > 0, "No scores found");
        
        ScoreEntry memory latestScore = playerScores[playerScores.length - 1];
        return (latestScore.score, latestScore.timestamp, latestScore.username);
    }

    function getTopScores(uint256 count) external view returns (
        string[] memory playerIds,
        string[] memory usernames,
        uint256[] memory scores,
        uint256[] memory timestamps
    ) {
        require(count > 0, "Count must be greater than 0");
        
        // Create arrays to store the top scores
        playerIds = new string[](count);
        usernames = new string[](count);
        scores = new uint256[](count);
        timestamps = new uint256[](count);
        
        // Initialize arrays with zeros
        for (uint256 i = 0; i < count; i++) {
            scores[i] = 0;
        }
        
        // Iterate through all players to find top scores
        // Note: This is a simplified version. In a production environment,
        // you might want to maintain a separate sorted list of top scores
        for (uint256 i = 0; i < totalPlayers; i++) {
            string memory playerId = bytes32ToString(bytes32(i)); // This is a placeholder
            if (playerExists[playerId]) {
                uint256 playerHighestScore = highestScore[playerId];
                
                // Find position to insert this score
                for (uint256 j = 0; j < count; j++) {
                    if (playerHighestScore > scores[j]) {
                        // Shift scores
                        for (uint256 k = count - 1; k > j; k--) {
                            scores[k] = scores[k - 1];
                            timestamps[k] = timestamps[k - 1];
                            playerIds[k] = playerIds[k - 1];
                            usernames[k] = usernames[k - 1];
                        }
                        
                        // Insert new score
                        scores[j] = playerHighestScore;
                        playerIds[j] = playerId;
                        
                        // Find the score entry with this score
                        ScoreEntry[] storage playerScores = scoreHistory[playerId];
                        for (uint256 k = 0; k < playerScores.length; k++) {
                            if (playerScores[k].score == playerHighestScore) {
                                timestamps[j] = playerScores[k].timestamp;
                                usernames[j] = playerScores[k].username;
                                break;
                            }
                        }
                        break;
                    }
                }
            }
        }
        
        return (playerIds, usernames, scores, timestamps);
    }

    // Helper function to convert bytes32 to string
    function bytes32ToString(bytes32 _bytes32) internal pure returns (string memory) {
        uint8 i = 0;
        while(i < 32 && _bytes32[i] != 0) {
            i++;
        }
        bytes memory bytesArray = new bytes(i);
        for (i = 0; i < 32 && _bytes32[i] != 0; i++) {
            bytesArray[i] = _bytes32[i];
        }
        return string(bytesArray);
    }
}