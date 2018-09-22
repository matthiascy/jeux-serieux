Utils
  + clamp(val, a, b)
  + lerp(val, target, t)
  + mod(a, b)
  + distance(a, b)
  + sphereMass(radius, density)
  + listRemove(lst, val)
  + listHas(lst, key, val)
  + listFind(lst, key, val)

Text
  + text
  + pos
  + scale
  + color
  + draw()

Settings
  + cameraLimit
  + propulseForce
  + volume
  + difficulty

Dir
  + Up
  + Down
  + Left
  + Right
  + CW
  + CCW

Key
  + Up
  + Down
  + Left
  + Right
  + A
  + Z
  + Enter

State
  + name
  + init()
  + onEnter()
  + onExit()
  + update(dt)
  + draw()

MenuState -> State
  + selection
  + title
  + playTxt
  + difficultyTxt
  + visibilityTxt
  + musicTxt
  + exitTxt

GameOverState -> State

PlayState -> State

FSM
  + current
  + states
  + add(state)
  + remove(stateName)
  + switchTo(stateName)
  + update(dt)
  + draw()

Timer

Game
  + satellite
  + planet
  + volume
  + score
  + gravity
  + fsm
  + timer
  + camera
  + renderer
  + init()
  + showHud()
  + showDirBtns()
  + showFnBtns()
  + showTime()
  + showScore()
  + incScore()
  + decScore()
  + keyinput()
  + update()
