require File.expand_path('../rubot', __FILE__)

# Your bot must implement a method #bot_loop
# inside the loop, you can use these methods:
#
# -------
# scan -> scans tile in front of the bot
#   returns:
#    'empty' - the tile is empty
#    'enemy' - tile has the enemy bot
#    'wall' - tile has an obstruction
#
# -------
# move_forward -> moves bot one tile forward
# -------
# turn -> turns bot 90*
#   argument:
#     :left - turns counter-clockwise
#     :right - turns clockwise
# -------
# fire -> attack tile in fornt of the bot
#


class ExampleBot < Rubot
  def bot_loop
    scan_result = scan()
    if scan_result == 'empty'
      move_forward
    else
      fire()
      turn(:left)
    end
  end
end

#
# Initialize your bot with a name and the address for the game server
#
ExampleBot.new('ExampleBot', 'ws://localhost:3000/cable/')
