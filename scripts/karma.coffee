# Description:
#   A simple karma tracking script for hubot.
#
# Commands:
#   <name>++ - adds karma to a user
#   <name>-- - removes karma from a user
#   karma <name> - shows karma for the named user
#   karma all - shows all users' karama
#   karma - shows all users' karama

module.exports = (robot) ->

  # Match no @ sign only if it's the start of the message.
  robot.hear /^([A-z.]+\s?)(\+\+|--)$/, (response) ->
    thisUser = response.message.user
    # return response.send "Match no @ signs: #{JSON.stringify(response.match)}" # debug
    targetToken = response.match[1].trim()
    return if not targetToken
    targetUser = userForToken targetToken, response
    return if not targetUser
    return response.send "Hey, you can't give yourself karma!" if thisUser is targetUser
    op = response.match[2]
    targetUser.karma += if op is "++" then 1 else -1
    response.send "#{targetUser.name} now has #{targetUser.karma} karma."

  # Match @ signs with possible space in name anywhere in a string.
  robot.hear /^.*?@(.*?)(\+\+|--).*?$/, (response) ->
    thisUser = response.message.user
    # return response.send "Match @ signs: #{JSON.stringify(response.match)}" # debug
    targetToken = response.match[1].trim()
    return if targetToken.split(' ').length > 1
    # return response.send "#{JSON.stringify(targetToken)}" # debug
    return if not targetToken
    targetUser = userForToken targetToken, response
    # return response.send "#{JSON.stringify(targetUser)}" # debug
    return if not targetUser
    return response.send "Hey, you can't give yourself karma!" if thisUser is targetUser
    op = response.match[2]
    targetUser.karma += if op is "++" then 1 else -1
    response.send "#{targetUser.name} now has #{targetUser.karma} karma."

  robot.hear /^karma(?:\s+@?(.*))?$/, (response) ->
    targetToken = response.match[1]?.trim()
    if not targetToken? or targetToken.toLowerCase() is "all"
      users = robot.brain.users()
      list = Object.keys(users)
        .sort()
        .map((k) -> [users[k].karma or 0, users[k].name])
        .sort((line1, line2) -> if line1[0] < line2[0] then 1 else if line1[0] > line2[0] then -1 else 0)
        .map((line) -> line.join " ")
      msg = "Karma for all users:\n#{list.join '\n'}"
    else
      targetUser = userForToken targetToken, response
      return if not targetUser
      msg = "#{targetUser.name} has #{targetUser.karma} karma."
    response.send msg

  userForToken = (token, response) ->
    users = usersForToken token
    if users.length is 1
      user = users[0]
      user.karma ?= 0
    else if users.length > 1
      response.send "Be more specific, I know #{users.length} people named like that: #{(u.name for u in users).join ", "}."
    else
      response.send "Sorry, I don't recognize the user named '#{token}'."
    user

  usersForToken = (token) ->
    user = robot.brain.userForName token
    return [user] if user
    user = userForMentionName token
    return [user] if user
    robot.brain.usersForFuzzyName token

  userForMentionName = (mentionName) ->
    for id, user of robot.brain.users()
      return user if mentionName is user.mention_name
