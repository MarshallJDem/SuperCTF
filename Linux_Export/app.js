const https = require('https');
const http = require('http');
const url = require('url');
const fs = require('fs');
const mysql = require('mysql');
const nanoid = require('nanoid');

// Players DB : "CREATE TABLE players (name VARCHAR(15) NOT NULL, password VARCHAR(20) NOT NULL, mmr int NOT NULL, uid int NOT NULL AUTO_INCREMENT, PRIMARY KEY (uid));";
// Add Player : "INSERT INTO players (name, password, mmr) VALUES ('Carshalljd', '1412014120', 0);"
// Modify Player Column : queryDB(`ALTER TABLE players MODIFY COLUMN mmr int NOT NULL DEFAULT 0`);
var con = mysql.createPool({
  host: "localhost",
  user: "root",
  password: "",
  database: "ctfdb"
});

//const hostname = '192.168.0.123';
const hostname = '172.26.3.161';
const port = 42401;

var MMqueue = {};
var AvailableServers = {};

/* Re-enable for https stuff. Probably eventually have to do this...
const options = {
  key: fs.readFileSync('HTTPSKeys/server.key'),
  cert: fs.readFileSync('HTTPSKeys/server.cert')
};*/

const server = http.createServer((req, res) => {
  var q = url.parse(req.url, true);
  if (req.headers['access-control-request-headers'] != null){
    res.writeHead(200, {'Content-Length': '0', 'Access-Control-Allow-Origin' : '*', 'Access-Control-Allow-Headers' : req.headers['access-control-request-headers'], 'Access-Control-Allow-Methods' : 'POST, GET, OPTIONS, DELETE'});
    return res.end();
  }
  var filename = "." + q.pathname;
  if (filename === "./"){
    filename = "./index.html"
  }
  if (q.pathname == "/createGuest"){
    return _createGuest(q, res);
  }
  else if (q.pathname == "/joinMMQueue"){
    return _joinMMQueue(req, q, res);
  }
  else if (q.pathname == "/leaveMMQueue"){
    return _leaveMMQueue(req, q, res);
  } 
  else if (q.pathname == "/leaveParty"){
    return _leaveParty(req, q, res);
  } 
  else if (q.pathname == "/makeGameServerAvailable"){
    return _makeGameServerAvailable(req, q, res);
  } 
  else if (q.pathname == "/pollPlayerStatus"){
    return _pollPlayerStatus(req, q, res);
  } 
  else if (q.pathname == "/getMatchData"){
    return _getMatchData(req, q, res);
  } 
  else if (q.pathname == "/pollGameServerStatus"){
    return _pollGameServerStatus(req, q, res);
  } 
  else if (q.pathname == "/gameServerCheckUser"){
    return _gameServerCheckUser(req, q, res);
  } 
  else if (q.pathname == "/gameServerEndMatch"){
    return _gameServerEndMatch(req, q, res);
  } 
  else if (q.pathname == "/test"){
    res.writeHead(200, {'Content-Type': 'text/json', 'Access-Control-Allow-Origin' : '*'});
    res.write("Alls good in the hood");
    res.end();
  }
  else{
    return fs.readFile(filename, function(err, data) { 
      if (err) {
        res.writeHead(404, {'Content-Type': 'text/html'});
        return res.end(filename + " Not Found 404");
      }  
      res.writeHead(200, {'Content-Type': 'text/json', 'Access-Control-Allow-Origin' : '*'});
      res.write(data);
      return res.end();
    });
  }
  
});

function _gameServerCheckUser(req, q, res){
  var token = req.headers['authorization'];
  return checkGameServerToken(token).then(server =>{
    var userToken = String(q.query.userToken);
    if(userToken){
      return checkPlayerToken(userToken).then(user =>{
        return RESPONSE_200(res, JSON.stringify(user))
      }).catch(err =>{
        console.error(err);
        return RESPONSE_404(res)
      })
    }else{
      return RESPONSE_403(res)
    }
  }).catch(err =>{
    return RESPONSE_401(res)
  })
}
function _gameServerEndMatch(req, q, res){
  var token = req.headers['authorization'];
  return checkGameServerToken(token).then(server =>{
    var matchID = parseInt(q.query.matchID.toString());
    var winningTeamID = parseInt(q.query.winningTeamID.toString());
    return queryDB(`SELECT players FROM matches WHERE matchID = ${matchID}`).then(result =>{
      if(result[0]){
        let promises = [];
        var players = JSON.parse(result[0].players);
        for(var i=0; i<players.length; i++){
          promises.push(queryDB(`UPDATE players SET status = 0 WHERE uid = ${players[i]}`));
        }
        promises.push(queryDB(`UPDATE matches SET winningTeamID = ${winningTeamID} WHERE matchID = ${matchID}`));
        return Promise.all(promises).then(() =>{
          console.log("Ended Match : " + matchID + " with winning team : " + winningTeamID);
          return RESPONSE_200(res, JSON.stringify({success : true}));
        }).catch(err =>{
          console.error(err);
          return err;
        })
      }else{
        var err = new Error("Couldnt find match : " + matchID);
        console.error(err);
        return err;
      }
    }).catch(err =>{
      console.error(err);
      return err;
    })
  }).catch(err =>{
    return RESPONSE_401(res)
  })
}
// Gets the status of the user making this call and returns it
function _pollPlayerStatus(req, q, res){
  var token = req.headers['authorization'];
  return checkPlayerToken(token).then(user =>{
    if(user.status){
      return RESPONSE_200(res, JSON.stringify({status : user.status}))
    }else{
      var error = new Error("User status not found");
      console.error(error);
      return RESPONSE_500(res)
    }
  }).catch(err =>{
    console.error(err);
    return RESPONSE_401(res)
  })
}
// Gets the status of the game server making this call and returns it
function _pollGameServerStatus(req, q, res){
  var token = req.headers['authorization'];
  return checkGameServerToken(token).then(server =>{
    return RESPONSE_200(res, JSON.stringify(server))
  }).catch(err =>{
    return RESPONSE_401(res)
  })
}

// Gets the data for a match
function _getMatchData(req, q, res){
  var token = req.headers['authorization'];
  // If this call is being made by a user
  return checkPlayerToken(token).then(user =>{
    if(q.query.matchID == null){
      return RESPONSE_404(res)
    }
    var matchID = parseInt(q.query.matchID.toString());
    if(matchID){
      return queryDB(`SELECT * FROM matches WHERE matchID = ${matchID}`).then(result =>{
        if(result[0]){
          var players = JSON.parse(result[0].players);
          if(players.indexOf(user.uid) !== -1){
            return RESPONSE_200(res, JSON.stringify(result[0]))
          }else{
            return RESPONSE_403(res)
          }
        }else{
          return RESPONSE_404(res)
        }
      }).catch(err =>{
        console.error(err);
        return RESPONSE_500(res)
      })
    }else{
      return RESPONSE_404(res)
    }
  }).catch(err =>{
    // Otherwise check to see if this call is being made by a Game Server 
    return checkGameServerToken(token).then(server =>{
      var matchID = q.query.matchID;
      if(matchID){
        return queryDB(`SELECT * FROM matches WHERE matchID = ${matchID}`).then(result =>{
          if(result[0]){
            return RESPONSE_200(res, JSON.stringify(result[0]))
          }else{
            return RESPONSE_404(res);
          }
        }).catch(err =>{
          console.error(err);
          return RESPONSE_500(res)
        })
      }else{
        return RESPONSE_404(res)
      }
    }).catch(err =>{
      return RESPONSE_401(res)
    })
  })
}

// Creates a guest account and returns an authentication token for it
function _createGuest(q, res){
  res.writeHead(200, {'Content-Type': 'text/json', 'Access-Control-Allow-Origin' : '*'});
  var newToken = generateRandomToken(35);
  var sql = `INSERT INTO players (token, type, name) VALUES ('${newToken}', 'G', 'Guest${ Math.floor(Math.random() * 999) + 1}');`;
  return queryDB(sql).then(result =>{
    console.log('Created new guest of ID: ' + String(result.insertId));
    return RESPONSE_200(res, JSON.stringify({token : newToken}))
  }).catch(err =>{
    console.error(err);
    return RESPONSE_200(res, JSON.stringify({token : null}))
  });
}
// Joins the matchmaking queue using the user making this call
function _joinMMQueue(req, q, res){
  var token = req.headers['authorization'];
  return checkPlayerToken(token).then(user =>{
    let promises = [];
    // If the user doesn't have a party, make one.
    if(user.partyHostID == null){
      promises.push(createParty(user.uid));
      user.partyHostID = user.uid;
    }
    // If the user is in a party that they don't own, deny this request.
    if(String(user.partyHostID) !== String(user.uid)){
      return RESPONSE_401(res);
    }
    // If the user is midgame (status = serverIP), deny this request.
    if(user.status > 1){
      return RESPONSE_401(res);
    }
    // Wait for promises to finish
    return Promise.all(promises).then(() =>{
      // Add party to MM queue.
      return addPartyToMMQueue(user.partyHostID).then(result =>{
        return RESPONSE_200(res, JSON.stringify({partyHostID : user.partyHostID}));
      }).catch(err =>{
        console.error(err);
        return RESPONSE_500(res);
      })
    }).catch(err =>{
      console.error(err);
      return RESPONSE_500(res);
    })
  }).catch(err =>{
    console.error(err);
    return RESPONSE_401(res);
  })
}
// Leaves the matchmaking queue using the user's group making this call
function _leaveMMQueue(req, q, res){
  var token = req.headers['authorization'];
  return checkPlayerToken(token).then(user =>{
    // If the user is not in a party or is not the host of their party, deny this request
    if(user.partyHostID == null || String(user.partyHostID) !== String(user.uid)){
      return RESPONSE_401(res);
    }
    return removePartyFromMMQueue(user.partyHostID).then(result =>{
      return RESPONSE_200(res, JSON.stringify({success : true}))
    }).catch(err =>{
      return RESPONSE_500(res)
    });
  }).catch(() =>{
    return RESPONSE_401(res);
  })
}
function _makeGameServerAvailable(req, q, res){
  var token = req.headers['authorization'];
  return checkGameServerToken(token).then(server =>{
    var newPublicToken = q.query.publicToken;
    if(newPublicToken){
      return queryDB(`UPDATE servers SET matchID = NULL WHERE serverIP = '${server.serverIP}'`).then(result =>{
        return queryDB(`UPDATE servers SET publicToken = '${newPublicToken}' WHERE serverIP = '${server.serverIP}'`).then(result =>{
          AvailableServers[server.serverIP] = server.serverIP;
          console.log("Game Server Available: " + server.serverIP);
          // Attempt to make a match now that the server is available
          attemptMakeMatches();
          return RESPONSE_200(res, JSON.stringify({success : true}))
        }).catch(err =>{
          console.error(err);
          return RESPONSE_500(res);
        })
      }).catch(err =>{
        console.error(err);
        return RESPONSE_500(res);
      })
    }else{
      var err = new Error("Game Server : " + String(server.serverIP) + " did not send a public token");
      console.error(err);
      return RESPONSE_400(res);
    }
  }).catch(() =>{
    return RESPONSE_401(res);
  })
}

// Makes the user making this call leave whatever party theyre in
// If they are host a new host is assigned, and if they were alone then the party is deleted
function _leaveParty(req, q, res){
  var token = req.headers['authorization'];
  return checkPlayerToken(token).then(user =>{
    res.writeHead(200, {'Content-Type': 'text/json', 'Access-Control-Allow-Origin' : '*'});
    // If the user is not in a party deny this request
    if(user.partyHostID == null){
      return RESPONSE_401(res);
    }else{
      return removeUserFromParty(user.uid, user.partyHostID).then(() =>{
        return RESPONSE_200(res, JSON.stringify({success : true}));
      }).catch(err =>{
        console.error(err);
        return RESPONSE_500(res);
      })
    }
  }).catch(() =>{
    return RESPONSE_401(res);
  })
}
// Adds a user to a party
function addUserToParty(uid, partyHostID){
  //  Get party Data
  return queryDB(`SELECT players FROM parties WHERE partyHostID = ${partyHostID};`).then(result =>{
    if(result[0]){
      // Get current players
      var players = JSON.parse(result[0].players);
      // Add new player if they don't already exist in party
      if(!players.includes(uid)){
        players.push(uid);
      }
      // Update party data to include new players
      return queryDB(`UPDATE parties SET players = '${JSON.stringify(players)}' WHERE partyHostID = ${partyHostID};`).then(result =>{
        // Update player data to include new party
        return queryDB(`UPDATE players SET partyHostID = ${partyHostID} WHERE uid = ${uid};`).then(result =>{
          return result;
        }).catch(err=>{
          return err;
        })
      }).catch(err =>{
        return err;
      })
    }else{
      return null;
    }
  }).catch(err =>{
    return err;
  });
}

// Removes a user from a party
function removeUserFromParty(uid, partyHostID){
  // Get party data
  return queryDB(`SELECT * FROM parties WHERE partyHostID = ${partyHostID}`).then(result =>{
    if(result[0]){
      var party = result[0];
      var players = JSON.parse(party.players);
      // If this player is not in this party, deny the call
      if(players.indexOf(uid) === -1){
        return null;
      }
      let promises = [];
      promises.push(removePartyFromMMQueue(partyHostID))
      // Remove the reference to the party in user data
      promises.push(queryDB(`UPDATE players SET partyHostID = NULL WHERE uid = ${uid}`))

      if(players.length > 1) { // If there are more players in the party then remove this player from the party
        players.splice(players.indexOf(uid), 1);
        promises.push(queryDB(`UPDATE parties SET players = '${JSON.stringify(players)}' WHERE partyHostID = ${partyHostID}`));
        // And set a new host using the first player in players
        promises.push(setNewPartyHost(players[0], partyHostID))
      }
      return Promise.all(promises).then(result =>{
        // If this is the only player in the party, just delete the whole party
        if(players.length <= 1){
          return queryDB(`DELETE FROM parties WHERE partyHostID = ${partyHostID}`);
        }
      }).catch(err =>{
        console.error(err);
        return err;
      })
      
    }else{
      var err = new Error("Party not found : " + String(partyHostID));
      console.error(err);
      return err;
    }
  }).catch(err =>{
    console.error(err);
    return err;
   })
}

function setNewPartyHost(newPartyHostID, currentPartyHostID){
  // If the two given values are for some reason, deny the call
  if(newPartyHostID == currentPartyHostID){
    var err = new Error("Tried to set new party host using the original host");
    console.error(err);
    return err;
  }
  // Delete any parties the new Host has
  return queryDB(`DELETE FROM parties WHERE partyHostID = ${newPartyHostID}`).then(() =>{
    // Get current party data
    return queryDB(`SELECT * FROM parties WHERE partyHostID = ${currentPartyHostID}`).then(result =>{
      if(result[0]){
        var party = result[0];
        var players = JSON.parse(party.players);
        let promises = [];
        // Update each player's reference to the party with the new partyHostID
        for(var i = 0; i<players.length; i++){
          promises.push(queryDB(`UPDATE players SET partyHostID = ${newPartyHostID} WHERE uid = ${players[i]}`));
        }
        // Update the partyHostID of the party with the new ID
        promises.push(queryDB(`UPDATE parties SET partyHostID = ${newPartyHostID} WHERE partyHostID = ${currentPartyHostID}`))

        return Promise.all(promises);
      }else{
        var err = new Error("Party Not Found : " + String(currentPartyHostID));
        console.error(err);
        return err;
      }
    }).catch(err =>{
      console.error(err);
      return err;
    })
  }).catch(err =>{
    console.error(err);
    return err;
  })
}

// Creates a new party given a userid as host and adds the user to it.
function createParty(uid){
  return new Promise(function(resolve, reject){
    // Delete any previous existing party for this user
    return deleteParty(uid).then(result =>{
      // Create a new party
      return queryDB(`INSERT INTO parties (partyHostID, players) VALUES (${uid}, '[${uid}]');`).then(result =>{
        // Add the host to the party
        return addUserToParty(uid, uid).then(result =>{
          resolve(result); return;
        }).catch(err =>{
          reject(err); return;
        })
      }).catch(err =>{
        reject(err); return;
      })

    }).catch(err =>{
      reject(err); return;
    })
  });
}
// Deletes a party
function deleteParty(partyHostID){
  return queryDB(`DELETE FROM parties WHERE partyHostID = ${partyHostID};`).then(result =>{
    return result;
  }).catch(err =>{
    return err;
  })
}

// Adds a party to the matchmaking queue.
function addPartyToMMQueue(partyHostID){
  // Get Party Data
  return queryDB(`SELECT * FROM parties WHERE partyHostID = ${partyHostID};`).then(result =>{
    if(result[0]){
      var party = result[0];
      var players = JSON.parse(party.players);
      let promises = [];
      var statusesEqualZero = true;
      console.log(`ADD PARTY TO MMQUEUE ( HOSTID = ${partyHostID} ), PLAYERS = ${players}`);
      // Get the statuses of each player in the party and make sure they are not already in queue nor in a match
      for(var i=0; i<players.length; i++){
        promises.push(queryDB(`SELECT status FROM players WHERE uid = ${players[i]}`).then(result =>{
          if(result[0].status){
            if(String(result[0].status) !== String(0)){
              console.log(`*PLAYER ${players[i]} IS NOT OF STATUS 0 (IDLE)! ADDING TO QUEUE WILL FAIL.`);
              statusesEqualZero = false;
            }
          }else{
            var err = new Error("Couldn't find player status " + players[i]);
            console.error(err);
            return err;
          }
        }).catch(err =>{
          console.error(err);
          return err;
        })
        );
      }
      Promise.all(promises).then(result =>{
        // Deny this request if one or more players don't have a status of 0 (idle)
        if(!statusesEqualZero){
          console.log(`*CANCELING ADDING PARTY OF HOSTID: ${partyHostID} TO MMQUEUE. ONE OR MORE PLAYERS ARE NOT OF STATUS 0 (IDLE)`)
          return null;
        }else{ // Otherwise carry on with request
          MMqueue[String(party.partyHostID)] = Object.keys(players).length;
          let promises2 = [];
          // Update player statuses to show in queue
          for(var i=0; i<players.length; i++){
            promises2.push(queryDB(`UPDATE players SET status = 1 WHERE uid = ${players[i]}`));
          }
          return Promise.all(promises2).then(result =>{
            // Attempt to make a match
            return(attemptMakeMatches());
          }).catch(err =>{
            console.error(err);
            return err;
          })

        }
      }).catch(err =>{
        console.error(err);
        return err;
      })

    }else{
      console.error('PARTY DOES NOT EXIST')
      // Party doesn't exist
      return null;
    }
  }).catch(err =>{
    return err;
  });
}


// Removes a party from the matchmaking queue
function removePartyFromMMQueue(partyHostID){
  delete MMqueue[String(partyHostID)];
  // Get party data
  return queryDB(`SELECT players FROM parties WHERE partyHostID = ${partyHostID}`).then(result =>{
    if(result[0]){
      // Get players from party
      var players = JSON.parse(result[0].players);
      let promises = [];
      var playersAreMidGame = false;
      // Check if any user statuses shows that they are midgame
      for(var i=0; i<players.length; i++){
        promises.push(queryDB(`SELECT status FROM players WHERE uid = ${players[i]}`).then(result =>{
          if(result[0].status){
            if(String(result[0].status) > String(1)){
              playersAreMidGame = true;
            }
          }else{
            var err = new Error("Couldn't find status for player " + players[i]);
            console.error(err);
            return err;
          }
        }).catch(err =>{
          console.error(err);
          return err;
        })
        );
      }
      Promise.all(promises).then(result =>{
        // If one or more players are midgame, deny this request
        if(playersAreMidGame){
          return null;
        }else{ // Otherwise continue the function
          let promises2 = [];
          for(var i=0; i<players.length; i++){
            // Set status of each player to 0
            promises2.push(queryDB(`UPDATE players SET status = 0 WHERE uid = ${players[i]}`));
          }
          return Promise.all(promises2);
        }
      }).catch(err =>{
        console.error(err);
        return err;
      })
    }else{
      var err = new Error("Party Not Found : " + String(partyHostID))
      console.error(err);
      return err;
    }
  }).catch(err =>{
    console.error(err);
    return err;
  })
}

// Moves a party out of the matchmaking queue and into a match
function movePartyFromMMQueueToMatch(partyHostID, matchID){
  delete MMqueue[String(partyHostID)];
  // Get party data
  return queryDB(`SELECT * FROM parties WHERE partyHostID = ${partyHostID}`).then(result =>{
    if(result[0]){
      let party = result[0];
      let promises = [];
      // Get Players from party
      let players = JSON.parse(party.players);
      // Set status of each player to matchID
      for(var i=0; i<players.length; i++){
        promises.push(queryDB(`UPDATE players SET status = ${matchID} WHERE uid = ${players[i]}`));
      }
      return Promise.all(promises).then(result =>{
        return result;
      }).catch(err =>{
        console.error(err);
        return err;
      })
    }else{
      return new Error("Party Not Found : " + String(partyHostID))
    }
  }).catch(err =>{
    console.error(err);
    return err;
  });

}

// Moves a server from being available to being in a match
function moveServerFromAvailibleToMatch(matchID, serverIP){
  delete AvailableServers[serverIP];
  return queryDB(`UPDATE servers SET matchID = ${matchID} WHERE serverIP = '${serverIP}'`);
}

// Attempts to make matches depending on who is in the MM queue and what servers are available
function attemptMakeMatches(){
  const numOfPlayers = 2;
  let promises = [];
  // NOTE: - this only works because parties are not being used yet.
  if (doesMMQueueHaveAtLeast(numOfPlayers) && Object.keys(AvailableServers).length > 0){
    var parties = {};
    // Pick a server to use and remove is from available server list
    var s = Object.keys(AvailableServers)[0];

    // Add parties to party list until max number for game is met
    for(var i = 0; i<numOfPlayers; i++){
      // Add party to list
      parties[Object.keys(MMqueue)[i]] = MMqueue[Object.keys(MMqueue)[i]];
    }
    promises.push(makeMatch(parties, s));
  }
  return Promise.all(promises).then(result =>{
    return result;
  }).catch(err =>{
    console.error(err);
    return err;
  });
}

function doesMMQueueHaveAtLeast(playerCount){
  var count = 0;
  for(var i=0;i<Object.keys(MMqueue).length;i++){
    count += MMqueue[Object.keys(MMqueue)[i]];
    if(count >= playerCount) return true;
  }
  return false;
}

// Makes a match between given players and server 
function makeMatch(parties, serverIP){
  return queryDB(`SELECT publicToken FROM servers WHERE serverIP = '${serverIP}'`).then(result =>{
    if(result[0]){
      var token = result[0].publicToken;
      return queryDB(`INSERT INTO matches (serverIP, serverPublicToken) VALUES ('${serverIP}', '${token}');`).then(result =>{
        console.log("Created Match");
        var players = [];
        let promises = [];
        let matchID = result.insertId;
        // Set match for Game Server
        promises.push(moveServerFromAvailibleToMatch(matchID, serverIP));
        for (var j = 0; j<Object.keys(parties).length; j++){
          // Get players from party and hang onto them for later
          promises.push(queryDB(`SELECT players FROM parties WHERE partyHostID = ${Object.keys(parties)[j]}`).then(result =>{
            if(result[0]){
              for (var i =0; i< JSON.parse(result[0].players).length; i++){
                players.push(JSON.parse(result[0].players)[i]);
              }
            }
            return result;
          }).catch(err =>{
            return err;
          }));
          // Remove party from MM queue
          promises.push(movePartyFromMMQueueToMatch(Object.keys(parties)[j], matchID));
        }
        return Promise.all(promises).then(result =>{
          // Update the match with the players
          return queryDB(`UPDATE matches SET players = '${JSON.stringify(players)}' WHERE matchID = ${matchID}`);
        }).catch(err =>{
          console.error(err);
          return err;
        });
      }).catch(err =>{
        console.error(err);
        return err;
      })
    }else{
      var err = new Error("Server not found : " + String(serverIP))
      console.error(err);
      return err;
    }
  }).catch(err =>{
    console.error(err);
    return err;
  })
  
}

  


// Checks a player token if it is validly associated with an account. Returns a user if it is, error otherwise
function checkPlayerToken(t){
  return new Promise(function(resolve, reject){
    var token = t;
    // Reject if token is null
    if (token == null){ reject(); return; }
    // Get rid of "Bearer " prefix
    if (token.startsWith('Bearer ')) token = token.slice(7, token.length);
    var sql = `SELECT * FROM players WHERE token = '${token}';`;
    queryDB(sql).then(result => {
      // Reject if no user is found for token
      if (result.length === 0){ reject(); return;}
      else {resolve(result[0]); return;}
    }).catch(err =>{
      console.error(err);
      reject(err); return;
    });
  });
}

// Checks a game server token if it is validly associated with an server. Returns a server if it is, null if it is not
function checkGameServerToken(t){
  return new Promise(function(resolve, reject){
    var token = t;
    // Reject if token is null
    if (token == null){ reject(); return; }
    // Get rid of "Bearer " prefix
    if (token.startsWith('Bearer ')) token = token.slice(7, token.length);
    var sql = `SELECT * FROM servers WHERE privateToken = '${token}';`;
    queryDB(sql).then(result => {
      // Reject if no user is found for token
      if (result.length === 0){ reject(); return;}
      else {resolve(result[0]); return;}
    }).catch(err =>{
      console.error(err);
      reject(err); return;
    });
  });
}

// Generates a random String token to be used for authentication, etc.
function generateRandomToken(size){
  return nanoid(size);
}

// Gets the data object of a user given a UID
function getUserData(uid){
  var sql = `SELECT * FROM players WHERE uid = ${uid};`;
  return queryDB(sql).then(result => {
    return result[0]
  }).catch(err =>{
    return null;
  });
  
}

// Queries the database using the given SQL instruction
function queryDB(sql){
  return new Promise(function(resolve, reject){
      con.query(sql, function (err, result) {
        if (err) {
          console.error(err);
          reject(err); 
          return;
        }else{
          resolve(result);
          return;
        }
      });
  });
}


function reset(){
  queryDB(`UPDATE players SET status = 0 WHERE true`)
  queryDB(`UPDATE players SET partyHostID = NULL WHERE true`)
  queryDB(`UPDATE servers SET matchID = NULL WHERE true`)
  queryDB(`DELETE FROM parties WHERE true`)
}
reset();

function RESPONSE_500(res){
  res.writeHead(500, {'Content-Type': 'text/html', 'Access-Control-Allow-Origin' : '*'});
  res.write("An unknown error occurred. Please try again in a moment");
  return res.end();
}
function RESPONSE_401(res){
  res.writeHead(401, {'Content-Type': 'text/html', 'Access-Control-Allow-Origin' : '*'});
  res.write("Unauthorized Request");
  return res.end();
}
function RESPONSE_403(res){
  res.writeHead(403, {'Content-Type': 'text/html', 'Access-Control-Allow-Origin' : '*'});
  res.write("Forbidden Request");
  return res.end();

}
function RESPONSE_200(res, json){
  res.writeHead(200, {'Content-Type': 'text/json', 'Access-Control-Allow-Origin' : '*'});
  res.write(json);
  return res.end();
}


// Start Listening
server.listen(port, hostname, () => {
  console.log(`Server running at https://${hostname}:${port}/`);
});

/*
queryDB(`CREATE TABLE players (name VARCHAR(15) NOT NULL, password VARCHAR(20),token VARCHAR(50) NOT NULL, mmr int NOT NULL DEFAULT 0, partyHostID int, status VARCHAR(30) NOT NULL DEFAULT '0', uid int NOT NULL AUTO_INCREMENT PRIMARY KEY);`);
queryDB(`CREATE TABLE parties (partyHostID int NOT NULL UNIQUE PRIMARY KEY, players JSON NOT NULL, status VARCHAR(30) NOT NULL DEFAULT '0');`);
queryDB(`CREATE TABLE servers (serverIP VARCHAR(30) NOT NULL UNIQUE PRIMARY KEY, matchID int, status VARCHAR(30) NOT NULL DEFAULT '0', publicToken VARCHAR(30), privateToken VARCHAR(30));`);
*/