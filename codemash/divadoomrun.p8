pico-8 cartridge // http://www.pico-8.com
version 38
__lua__

backdrops = {
 12,13,0
}

-- prevent btnp repeat
--poke(0x5f5c, 255)

not_started = true

cartdata("keith_jumper")

function _init()
	chars = {
	 {
	  spr = 1,
	  music = 0,
	  max_speed = 1.5,
	  jump = 2,
	  v_grav = 0.05,
	  h_grav = 0.05,
	  slip =  0.97,
	  wall_mod = 1
	 },
	 {
	  spr = 7,
	  music = 10,
	  max_speed = 1,
	  jump = 2.5,
	  v_grav = 0.05,
	  h_grav = 0.05,
	  slip = 0.97,
	  wall_mod = 1
	 },
	 {
	  spr = 4,
	  music = 4,
	  max_speed = 1.8,
	  jump = 2,
	  v_grav = 0.05,
	  h_grav = 0.025,
	  slip = 0.99,
	  wall_mod = 2
	 }
	}
 if (not not_started) then
  music(0)
 end
 hi_score = dget(0)
 if (hi_score == nil) then
 	hi_score = 0
 end
 g_time = 0
 needs_missing_map = true
 level = 1
 player = {
  x = 64,
  y = 64,
  dx = 0,
  dy = 0,
  jump = 1,
  on_ground = false,
  dead = false,
  dist = 0,
  time = 0,
  char = 1
 }
 wall = {
  x = 0,
  dx = 0.5
 }
 gen_map(true)
end

function _draw()
 local p = player
 local char = chars[p.char]
 cls()
 rectfill(0,0,128,128,backdrops[level % 3])
 camera(p.x-24,0)
 -- draw all but bottom row
 map(0,0,0,0,128,15)
 -- animate map
 map(0,g_time >= 30 and 15 or 16,0,120,128,1)
 -- draw evil wall
 for i=0,15 do
  spr(g_time % 6 <= 3 and 22 or 23,wall.x,i*8)
 end
 if (p.dead) then
  camera()
  print("no more divas :(",30,60,10)
  print("press 🅾️ to try again",20,68, 10)
 elseif (not_started) then
  camera()
  print("~diva doom run~",30,60,10)
  print("press 🅾️ to start",28,68, 10)
 else
  -- draw player
  if (p.jump >= 1) then
   spr(char.spr+2,p.x,p.y)
  else
   spr(p.time < char.max_speed and char.spr or char.spr+1,p.x,p.y)
  end
 end
 -- hud
 camera()
 draw_hud()
end

function _update60()
 local p = player
 local char = chars[p.char]
 -- already dead
 if p.dead or not_started then
  if (btnp(🅾️)) then
   not_started = false
   _init()
  end
  return
 end
 -- apply death
 if hit(p.x,p.y,7,7,2) or
  hit_spr(p.x,p.y,wall.x,p.y) then
  if #chars > 1 then
  	next_char()
  	return
  end
  deli(chars,1)
  p.dead=true
  dset(0,hi_score)
  music(-1)
  sfx(12)
  return
 end
 -- apply gravity
 p.dy=p.dy+char.v_grav
 -- up/ down
 if (btn(➡️)) then
  p.dx=p.dx+char.h_grav
 end
 if (btn(⬅️)) then
  p.dx=p.dx-char.h_grav
 end

 -- jump
 if (btnp(🅾️)) and
   (p.on_ground or p.jump<1) then
   p.on_ground=false
   p.jump+=1
   p.dy=p.dy-char.jump
   sfx(11)
 end

 -- change character
 if (btnp(❎)) then
  p.char += 1
  if (p.char > #chars) then
   p.char = 1
  end
  music(chars[p.char].music)
 end

 -- check wall coll
 if hit(p.x+p.dx,p.y,7,7,1) then
  player.dx=0
 end

 -- check ground coll
 if hit(p.x+p.dx,p.y+p.dy,7,7,1) then
  if p.dy>0 then
   p.on_ground=true
  end
   p.dy=0
 end

 -- check pizza coll
 if hit(p.x,p.y,7,7,4,true) then
  p.dist = p.dist + 160
 end

 -- decel if on ground
 if p.on_ground then
  p.dx=p.dx*char.slip
  p.jump=0
 end

 -- max acceleration
 if p.dx > char.max_speed then
  p.dx = char.max_speed
 end

 -- update forward/ upward motion
 p.y=p.y+p.dy
 p.x=p.x+p.dx

 -- player animation
 p.time = p.time + p.dx
 if (p.time >= char.max_speed * 2) then
 	p.time = 0
 end

 -- move evil wall
 wall.x = wall.x + wall.dx/char.wall_mod
 if (p.x - wall.x > 64 or wall.x > p.x) then
  wall.x = p.x - 64
 end

 -- update score
 p.dist = p.dist + p.dx

 -- global animation
 g_time = g_time + 1
 if (g_time > 60) then
  g_time = 0
 end

 -- reset to beginning
 -- generate more map
 if p.x >= (127-12)*8 then
  p.x = 24
  level = level + 1
  sfx(13)
  wall.dx = wall.dx + 0.05
  needs_missing_map = true
  gen_map()
 end
 if needs_missing_map and p.x >= (36-12)*8 then
  gen_missing_map()
  needs_missing_map = false
 end
end
-->8
function hit(x,y,w,h,flag,remove)
 collide=false

 for i=x,x+w,w do
  if (fget(mget(i/8,y/8))==flag) or
         (fget(mget(i/8,(y+h)/8))==flag) then
   collide=true
   if remove then
    mset(i/8,y/8,24)
    mset(i/8,(y+h)/8,24)
   end
  end
 end

 return collide
end

function hit_spr(x1,y1,x2,y2)
 if (x1 >= x2+8 or x2 >= x1+8) return false;

	if (y1 >= y2+8 or y2 >= y1+8) return false;

	return true;
end
-->8
function gen_map(init)
 -- set flat space at begin
 if (init) then
 	for i=0,15 do
			set_map_x(1,i)
		end
 end
	-- set variable space
	for i=16,111 do
	 local flr_hgt = gen_floor_height()
	 set_map_x(flr_hgt,i)
	 if (flr_hgt > 1 and has_thorns()) then
			mset(i,15-flr_hgt,20)
		end
		local pizza_hgt = pizza_pos(flr_hgt)
		if pizza_hgt != -1 then
		 mset(i,15-pizza_hgt,25)
		end
 end
end

function gen_missing_map()
 for i=0,15 do
  local flr_hgt = gen_floor_height()
		set_map_x(flr_hgt,i)
		set_map_x(flr_hgt,i+112)
	end
end

function gen_floor_height()
 -- negative = no floor
	local has_flr = rnd(8+level)-(level) > 0
	if (not has_flr) then
		return 0
	end
	return flr(rnd(3 + level * 0.34)) + 1
end

function has_thorns()
	return rnd(100)-(97-(level*2)) > 0
end

function pizza_pos(flr_hgt)
 local max_flr_hgt = flr(1 + 3 + level * 0.34)
	local could_have_pizza = rnd(100) > (88-(level*2))
	if (flr_hgt == max_flr_hgt and could_have_pizza) then
	 return flr_hgt + 4
	end
	if flr_hgt == 1 and could_have_pizza then
		return flr_hgt + 1
	end
	return -1
end

-- set a single space on map
function set_map_x(flr_hgt,x)
	-- clear
	for j=0,17 do
  mset(x,j,24)
 end
 for j=0,flr_hgt do
  -- negative nums make no floors
		mset(x,15-j,16)
		-- animation map swap
		mset(x,16,16)
	end
	-- make lava
	if flr_hgt < 1 then
	 mset(x,15,18)
	 -- animation map swap
	 mset(x,16,19)
	end
end
-->8
function draw_hud()
 local p = player
	local score = max(flr(p.dist/8),0)
 if (score > hi_score) then
  hi_score = score
 end
 print("score",1,1,10)
 print(score,24,1,7)
 print("hi",42,1,10)
 print(hi_score,54,1,7)
 print("lvl",74,1,10)
 print(level,90,1,7)
 
 --remaining players
 for i=1,#chars do
  local char = chars[i]
  spr(char.spr,91+i*9,1)
 end
end

function next_char()
 local p = player
 deli(chars,p.char)
 p.char = 1
 p.y = 20
 p.jump = 1
 p.dx = 0
 p.dy = 0
 p.on_ground = false
 music(chars[p.char].music)
 
 -- false floor
 set_map_x(6,p.x/8-1)
 set_map_x(6,p.x/8)
 set_map_x(6,p.x/8+1)
 set_map_x(6,p.x/8+2)
 
 -- reset wall
 wall.x = p.x - 64
end
__gfx__
00aaaa0000aaaa0000aaaa00a0aaaa0a00aaaa0000aaaa00a0aaaa0a004444000044440040444404000000000000000000000000000000000000000000000000
0a7ff7a00a7ff7a00a7ff7a00a7ff7a00a7ff7a00a7ff7a00a7ff7a0047f4440047f4440047ff740000000000000000000000000000000000000000000000000
0affffa00affffa00affffa000f77f000affffa00affffa000f77f0004ffff4004ffff4000f77f00000000000000000000000000000000000000000000000000
0a8888a00a8888a00a8888a0f888888f0aeffea00aeffea0feeffeef041ff140041ff140ff1ff1ff000000000000000000000000000000000000000000000000
08888880f88888800888888f00888800feeeeee00eeeeeef00eeee00ff1111f00f1111ff00111100000000000000000000000000000000000000000000000000
0f1111f0001111f00f1111005011110500eeeef00feeee0050eeee05001111f00f11110060111106000000000000000000000000000000000000000000000000
00100100055001000010055051000015055eee0000eee5505ee00ee506600f0000f006606f0000f6000000000000000000000000000000000000000000000000
05500550000005500550000000000000000005500550000000000000000006600660000000000000000000000000000000000000000000000000000000000000
77777677000000000900000000090090600600000000000000606000000606000000000000000000000000000000000000000000000000000000000000000000
67677776000000000000900909000000030330600000000006055060060550600000000000099000000000000000000000000000000000000000000000000000
77777677000000000000000000000000003b330000000000005665066056650000000000009b8900000000000000000000000000000000000000000000000000
767677770000000008808880088808800b33bb360000000065655650056556560000000009383890000000000000000000000000000000000000000000000000
77777767000000008888888888888888633bb33000000000056556566565565000000000098b8b90000000000000000000000000000000000000000000000000
777677770000000088a88a88888a88a80033b3b00000000060566500005665060000000000938900000000000000000000000000000000000000000000000000
6777777600000000899899988999899806b330300000000006055060060550600000000000099000000000000000000000000000000000000000000000000000
77767767000000009999999999999999033330330000000000060600006060000000000000000000000000000000000000000000000000000000000000000000
__gff__
0000000000000000000000000000000001000202020000000004000000000000020000000000000000000000000000000200000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
0000000000000000000000120000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000101000101010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000001010101010100000000000001010101010101000000000000000000000000000000000000000000000000000000000000000001010101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000101010100000000000000000000000000000000000001010100000000000000000000000000000000000000000000000000000001010100000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000101000101010000000000000000000000000000000000000000000000000101000101010101010101010101000000000000000000000001010100000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000101000100010000000000000000000000000000000000000000000000000000000000000000000000000000000000000001010100000000000001010100000000000000000000000001010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010101000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000101010101010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000010101010000000000010100000000000000000000000000000000000000000101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000001010101010101010101010100000000000000000000010101000000000000000000000101000000000000000000000000000000000000000100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000010101000000000000000000000101000000000000000001010000000000000000000000000001010100000000000000000000000000000000010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000101010000000000000000000000000001010101010000000101000000000000000000000000000000000101010101000000000000000000000001010000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0101010101010101010101010100000000000000000000000000000000000000010101010100000000000000000000000000000000000000000001010101010101010101010100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__sfx__
010e00002b05000000000000000029050000000000000000290502900029050000002905000000000000000029050000002905000000290500000029050000002905000000290500000029050000002900000000
010e00002b05000000000000000029050000000000000000290502900029050000002905000000000000000029050000002905000000290500000029050000002805029000260000000026050000000000000000
010e00002b05000000000000000029050000000000000000290502900029050000002905000000000000000029050000002905000000290500000029050000002905000000260500000026050000002600000000
010e000026050000000000026050000000000026050000002d0500000000000000000000000000000000000026050000000000026050000000000026050000002d0500000000000000002b050000000000000000
7b0e0000290500000000000000002905000000290500000029050000000000000000290500000029050000002905000000290500000029050000002905000000290500000000000000002b050000000000000000
7b0e0000290500000000000000002905000000290500000029050000000000000000290500000029050000002905000000290500000028050000002800000000260500000000000000002b050000000000000000
7b0e00002905000000000000000029050000002905000000290500000000000000002905000000290500000029050000002905000000290500000029050000002905000000260500000026050000000000000000
7b0e000026050000000000026050000000000026050000002d0522d0522d000000000000000000000000000026050000000000026050000000000026050000002d0522d05210003000002b050000000000000000
010e00001651016510165101651022510225102251022510165101651016510165102251022510225102251018510185101851018510245102451024510245101a5101a5101a5101a51026510265102651026510
010e0000135101351013510135101f5101f5101f5101f510135101351013510135101f5101f5101f5101f5101a5101a5101a5101a510265102651026510265101851018510185101851024510245102451024510
010e00000c753000033c6000000324633000033c600000030c753000033c6050000324633000033c6133c6130c753000033c6050000324633000033c605000030c753000033c6050000324633000033c6133c613
00020000000000905010050190502005026050290502e05033050370503205033050300502f0502a05023050200501e0501a0501605013050100500e0500b0500a05008050060500405003050020500105000000
010200001a0501a0501a0501a0501a0501a0501a0501a0501a0501a0501a0501a0501a0501a0501a0501a05015050150501505015050150501505015050150501505015050110501105011050110501105011050
010300001c0501c0501c0501c0501c0501c0501f0501f0501f0501f0502305023050230502305021050210502105021050210501c0501c0501c0501c0501a0501a0501a0501a0501a05000000000000000000000
011200002c1502c1502c1502c150000000000000000000002c1502c1502c1502c150000000000000000000002a1502a1552a1552a1502a1552a1552a1502a1552815028150281502815000000000002815028150
011200002c1502c1502c1502c150000000000000000000002c1502c1502c1502c150000000000000000000002a1502a1552a1552a1502a1552a1552a1502a1552815028150281502815000000000002810028100
011200002515025150251502515000000000000000000000231502315023150231500000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
011200002c1002c1002c1502c1552c1502c1552c1552c1502c1502c1552c1502c1552c1502c1552c1552a1502a1502a1552a1502a1552a1502a1552a1552a1502a1502a1552a1552a1502a1502a1552815028150
01120000281502815523150231552315023155231552315023150231552115521150211502115520150201551e1501e1551e1501e1551e1501e1551e1551e1501e1501e1551e1551e1501e1501e1551c1501c155
3112000015752157521c7521c75221752217521c7521c7521c7521c75220752207522375223752207522075217752177521e7521e75223752237521e7521e75219752197521c7521c75220752207521c7521c752
01120000180530c0000c0000c003306530000018053180531800300000000000000030653000000000000000180530c0000c0000c003306530000018053180530000000000000000000030653000000000000000
011200000000000000000002a550285500050026550265502655026550265002a550285502655023550215500050000500005002a550285502655023550235502355023550005002a55028550265502355021550
011200000000000000000002a550285502655023550235502355023550005002a5502855026550235502155023550235502f5502f5502d5502d5502b5502b5502a5502a5502a5502a5502a500265552655026550
011200002a7502a7502a7500000000000000000000000000287502875028700287502875028750007000070028750287500070028750287502875000700007002875028750007002875028750267552675026750
011200002a7502a7502a7500070000700007000070000700287502875028700287502875028750007002675028750287500070028750287502675023750237502870028700007002a75028750267502375021750
011200000c753000000000000000306330000000000000000c7530c7033060300000306330000000000000000c753000000000000000306330000000000000000c75300000306330000030633000000c70300000
011200001705017050170501700017050170501a0501a050120501205012050000001205012050110501105010050100501005000000100501005015050150501705017050170500000017050170501a0501a050
__music__
01 04080a44
00 05080a44
00 06080a44
02 07090a44
01 0e131450
00 0f131450
00 11131453
00 12131453
00 41131453
02 41131453
01 15191a44
00 16191a44
00 17191a44
02 18191a44

