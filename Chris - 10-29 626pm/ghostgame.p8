pico-8 cartridge // http://www.pico-8.com
version 18
__lua__
--variables

function _init()
  player={
    sp=1,
    pos_sp=17,
    lives=3,
    sublives=1, --timer    
    x=8,
    y=56,
    spawn_x=8,
    spawn_y=59,
    w=8,
    h=8,
    flp=false,
    dx=0,
    dy=0,
    max_dx=2,
    max_dy=3,
    acc=0.5,
    boost=4,
    anim=1,
    hit=0,
    hitbool=false,
    running=false,
    jumping=false,
    falling=false,
    sliding=false,
    landed=false,
    floating=false,
    canposess=false,
    posstime=1,
    posess=false,
    caninv=true,
    invtime=1,
    bonescoll=0    
  }  
  
  enemytable={}
  enemy_count=0
  make_enemy(20,20)
  make_enemy(30,10)
  
  bones={}
  add_bone(8*14, 8*7)
  
  gravity=0.3
  friction=0.85

  --simple camera
  cam_x=0
  cam_y=0

  --map limits
  map_start=0
  map_end=1024
  
  --current scene
  scene="menu"
end
-->8
--main update and draw

function _update()

  if scene=="menu" then
    update_menu()
  elseif scene=="game" then
    update_game()
  end
end


function _draw()

  if scene=="menu" then
    draw_menu()
  elseif scene=="game" then
    draw_game()
  end
end

-->8
--player
function wait_inv()
 if time()-player.invtime>8 then
     player.caninv=true
 end
end

function end_pos()
 if time()-player.posstime>3 then
     
     player.posess=false
 end
end

function end_inv()
	if time()-player.invtime>5 then
     
     player.invisible=false
     player.invtime=time()
 end
end

function player_update()
  --physics
  player.dy+=gravity
  player.dx*=friction

  --controls
  if btn(⬅️) then
    player.dx-=player.acc
    player.running=true
    player.flp=true
  end
  if btn(➡️) then
    player.dx+=player.acc
    player.running=true
    player.flp=false
  end

  --slide
  if player.running
  and not btn(⬅️)
  and not btn(➡️)
  and not player.falling
  and not player.jumping then
    player.running=false
    player.sliding=true
  end

  --jump
  if btnp(❎)
  and player.landed then
    player.dy-=player.boost
    player.landed=false
  end  
  --floating

  if btnp(❎)
  and player.falling then
   gravity=0.00000001
   player.floating=true
  end 

  --invisibility
  if btnp(🅾️)
  and player.invisible!=true then
  player.invisible=true
  player.invtime=time()
  player.caninv=false
  end
  
  --check collision up and down
  if player.dy>0 then
    player.falling=true
    player.landed=false
    player.jumping=false

    player.dy=limit_speed(player.dy,player.max_dy)

    if collide_map(player,"down",0) then
      player.landed=true
      player.falling=false
      player.dy=0
      player.y-=((player.y+player.h+1)%8)-1
      gravity=0.3 
    end
  elseif player.dy<0 then
    player.jumping=true
    if collide_map(player,"up",1) then
      player.dy=0
    end
  end

  --check collision left and right
  if player.dx<0 then

    player.dx=limit_speed(player.dx,player.max_dx)

    if collide_map(player,"left",1) then
      player.dx=0
    end
  elseif player.dx>0 then

    player.dx=limit_speed(player.dx,player.max_dx)

    if collide_map(player,"right",1) then
      player.dx=0
    end
  end

  --stop sliding
  if player.sliding then
    if abs(player.dx)<.2
    or player.running then
      player.dx=0
      player.sliding=false
    end
  end

  player.x+=player.dx
  player.y+=player.dy

  --limit player to map
  if player.x<map_start then
    player.x=map_start
  end
  if player.x>map_end-player.w then
    player.x=map_end-player.w
  end
end

function player_animate()
  if player.jumping then
    if not player.invisible and not player.posess then
     player.sp=5
    elseif player.invisible then
     player.sp=10
    elseif player.posess then
     player.sp=20
    end    
 -- elseif player.falling then
 --   player.sp=8
 -- elseif player.sliding then
 --   player.sp=9
  elseif player.posess and player.running then
    if time()-player.anim>.1 then
      player.anim=time()
      player.sp+=1
      if player.sp>18 then
        player.sp=17
      end
    end
  elseif player.running and player.invisible!=true then
    if time()-player.anim>.1 then
      player.anim=time()
      player.sp+=1
      if player.sp>4 then
        player.sp=3
      end
    end
  elseif player.running and player.invisible then
    if time()-player.anim>.1 then
      player.anim=time()
      player.sp+=1
      if player.sp>9 then
        player.sp=8
      end
    end   		  
  else --player idle
   if player.posess then
    player.sp=19
   elseif player.invisible then
    if time()-player.anim>.3 then
  		  player.anim=time()
  		  player.sp+=1
  		  if player.sp>7 then
  		    player.sp=6
  		  end
  		end 
   else   
    if time()-player.anim>.3 then
      player.anim=time()
      player.sp+=1
      if player.sp>2 then
        player.sp=1
      end
    end
   end
  end
end

function limit_speed(num,maximum)
  return mid(-maximum,num,maximum)
end
-->8
--collisions

function collide_map(obj,aim,flag)
 --obj = table needs x,y,w,h
 --aim = left,right,up,down
--if obj.name == "human" then
 local x=obj.x  local y=obj.y
 local w=obj.w  local h=obj.h

 local x1=0	 local y1=0
 local x2=0  local y2=0

 if aim=="left" then
   x1=x-1  y1=y
   x2=x    y2=y+h-1

 elseif aim=="right" then
   x1=x+w-1    y1=y
   x2=x+w  y2=y+h-1

 elseif aim=="up" then
   x1=x+2    y1=y-1
   x2=x+w-3  y2=y

 elseif aim=="down" then
   x1=x+2      y1=y+h
   x2=x+w-3    y2=y+h
 end

 --pixels to tiles
 x1/=8    y1/=8
 x2/=8    y2/=8

 if fget(mget(x1,y1), flag)
 or fget(mget(x1,y2), flag)
 or fget(mget(x2,y1), flag)
 or fget(mget(x2,y2), flag) then
   return true
 else
   return false
 end

end


-->8
--human ai

function make_enemy(x,y)
 a={}
 a.x=x
 a.y=y
 a.sp=17
 a.w=8
 a.h=8
 a.flp=false
 a.dx=0
 a.dy=0
 a.max_dx=2
 a.max_dy=3
 a.acc=0.5
 a.boost=4
 a.anim=1
 a.running=true    
    --falling=false,
    --landed=false,
 a.movement=0
 a.moveright=true
 add(enemytable, a)
 --enemytable[enemy_count]=a
	enemy_count+=1
end

function delete_human(human)
 if human.x-human.w+2 < player.x 
  and human.x+human.w+2 > player.x
  and human.y-human.h/2 < player.y 
  and human.y+human.h/2 > player.y
 then
  player.posess=true
  del(enemytable,human)
  enemy_count-=1
 end
end

function playercollide(human)
 if human.x-human.w/2 < player.x 
  and human.x+human.w/2 > player.x
  and human.y-human.h/2 < player.y 
  and human.y+human.h/2 > player.y
 then
  player.hit+=1
 else
  player.hit+=0
 end
end

function human_update(human)
  human.dy+=gravity
  human.dx*=friction  
  
  if human_ai(human,"left",2) then
    human.moveright=true  
  elseif human_ai(human,"right",2) then
    human.moveright=false
  end
  
  --controls
  if human.moveright==false then
    human.dx-=human.acc
    human.running=true
    human.flp=true
  end
  if human.moveright then
    human.dx+=human.acc
    human.running=true
    human.flp=false
  end  

  --check collision up and down
  if human.dy>0 then
    --human.falling=true
    --human.landed=false

    human.dy=limit_speed(human.dy,human.max_dy)
    
    if collide_map(human,"down",0) then
      --human.landed=true
      --human.falling=false
      human.dy=0
      human.y-=((human.y+human.h+1)%8)-1
      gravity=0.3 
    
    end
    
  elseif human.dy<0 then
    --human.jumping=true
    if collide_map(human,"up",1) then
      human.dy=0
    end
  end

  --check collision left and right
  if human.dx<0 then

    human.dx=limit_speed(human.dx,human.max_dx)

    if collide_map(human,"left",1) then
      human.dx=0
    end
  elseif human.dx>0 then

    human.dx=limit_speed(human.dx,human.max_dx)

    if collide_map(human,"right",1) then
      human.dx=0
    end
  end

  human.x+=human.dx
  human.y+=human.dy

  --limit player to map
  if human.x<map_start then
    human.x=map_start
  end
  if human.x>map_end-human.w then
    human.x=map_end-human.w
  end
end

function human_animate(human)
  if human.running then
   if time()-human.anim>.1 then
      human.anim=time()
      human.sp+=1
      if human.sp>18 then
        human.sp=17
      end
    end
 -- else --player idle
   -- if time()-player.anim>.3 then
   --   player.anim=time()
   --   player.sp+=1
    --  if player.sp>2 then
     --   player.sp=1
    --  end
  --  end
  end
end

function human_ai(obj,aim,flag)

 local x=obj.x  local y=obj.y
 local w=obj.w  local h=obj.h

 local x1=0	 local y1=0
 local x2=0  local y2=0

 if aim=="left" then
   x1=x-1  y1=y
   x2=x    y2=y+h-1

 elseif aim=="right" then
   x1=x+w-1    y1=y
   x2=x+w  y2=y+h-1 
   end
 
 x1/=8    y1/=8
 x2/=8    y2/=8

 if fget(mget(x1,y1), flag)
 or fget(mget(x1,y2), flag)
 or fget(mget(x2,y1), flag)
 or fget(mget(x2,y2), flag) then
   return true
 else
   return false
 end

end
-->8
--bones

function add_bone(x,y)
 a={}
 a.x=x
 a.y=y
 a.sp=12
 a.w=8
 a.h=8
 a.flp=false
 
 add(bones, a)
end

function bone_collect(bone)
 if bone.x-bone.w/2 < player.x 
  and bone.x+bone.w/2 > player.x
  and bone.y-bone.h/2 < player.y 
  and bone.y+bone.h/2 > player.y
 then
 player.bonescoll+=1
  del(bones, bone)
 end
end
-->8
--menu update and draw

function update_menu()

 if btnp(❎) then
   scene="game"
 end
end


function draw_menu()

  cls()
  print("press ❎ to start",30,63)
end
-->8
--game update and draw

function update_game()
  
  player_update()
  player_animate()
  
  foreach(enemytable, human_update)  
  foreach(enemytable, playercollide)
  foreach(enemytable, human_animate)
  
  foreach(bones, bone_collect)
  
  if player.invisible then
   end_inv()
   player.canposess=true
  else
   player.canposess=false
   wait_inv()
  end
  
  if player.posess then
   end_pos()
  end  
    
  --check if hit; check if posessed 
  if player.hit>0 then
   if player.invisible then    
    if btnp(🅾️) and not player.posess then
     player.posstime=time()
     foreach(enemytable, delete_human)
    end
   else    
    player.hitbool=true  
   end 
  else
   player.hitbool=false
  end
  player.hit=0
  
  if player.posess then
   player.invisible=false   
  end
  
  --update lives
  if player.hitbool and time()-player.sublives>.3 then
   player.lives-=1
   player.sublives=time()
  end
  
  --respawn/death
  if player.lives<=0 then
   player.x=player.spawn_x
   player.y=player.spawn_y
   player.lives=3
  end     
  
  --camera
  cam_x=player.x-64+(player.w/2)
  if cam_x<map_start then
     cam_x=map_start
  end
  if cam_x>map_end-128 then
     cam_x=map_end-128
  end
  
  cam_y=player.y-64+(player.h/2)
  if cam_y<map_start then
     cam_y=map_start
  end
  if cam_y>map_end-128 then
     cam_y=map_end-128
  end
  
  camera(cam_x,cam_y)
end


function draw_game()

  cls()  
  map(0,0)
  
  --ui
  print('lives: ' ..player.lives, cam_x,cam_y)
  print('bones: ' ..player.bonescoll, cam_x,cam_y+10)
  
  if player.caninv then
  	spr(6,cam_x,cam_y+15,1,1)
  end
  
  --open doors
  if player.posess then
   if collide_map(player,"right",3) then
    --spr(69,player.x+8,player.y,1,1,false)
    fset(68,0,false)
    fset(68,1,false)
   elseif collide_map(player,"left",3) then
    --spr(69,player.x-8,player.y,1,1,false)
    fset(68,0,false)
    fset(68,1,false)
   else
    fset(68,0,true)
    fset(68,1,true)
   end
  end  
  
  --draw player
  spr(player.sp,player.x,player.y,1,1,player.flp)
  
  --draw all humans
  for obj in all(enemytable) do  
   spr(obj.sp,obj.x,obj.y,1,1,obj.flp)
  end  
  
  --draw all bones
  for obj in all(bones) do  
   spr(obj.sp,obj.x,obj.y,1,1,obj.flp)
  end   
end
__gfx__
00000000000770000007700000067000000670000006700000056000000560000005600000056000000560000000000000000000000000000000000000000000
00000000007777000077770000677700006777000067770000566600005666000056660000566600005666000000000000000000000000000000000000000000
00700700077777700777777006777770067777700677777005666660056666600566666005666660056666600000000000000000000000000000000000000000
00077000070770700707707006707070067070700670707005866860058668600568686005686860056868600000000077000077000000000000000000000000
00077000077777700777777006777770067777700677777005666660056666600566666005666660056666600000000007777770000000000000000000000000
00700700077777700777777006777770067777700677777005666660056666600566666005666660056666600000000077000077000000000000000000000000
00000000077777700777777006777770067777700677777005666660056666600566666005666660056666600000000000000000000000000000000000000000
00000000070770700070070006077070007007000000000005066060006006000506606000600600000000000000000000000000000000000000000000000000
00000000006666600066666000666660006666600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000066666660666666606666666066666660000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066f1ff1666f1ff1666f1ff1666f1ff160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066f1ff1666f1ff1666f1ff1666f1ff160000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066efffe666efffe666efffe666efffe60000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
000000006f66666f6f66666f6f66666f6f66666f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000066f66660666666f06666666066f666f00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000f000f0000000f000f0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
f44f4444111111111111111111111111444444444000000011111111111111111111111111111111000000000000000011111111000000000000000000000000
4f4444f411111111111111111111111144444444400000001ddddddd1ddddddd1ddddddd1ddddddd00000000000000001ddddddd000000000000000000000000
4444f44411111111111111111111111144444444400000001ddddddd1ddddddd1ddddddd1ddddddd00000000000000001dddd1dd000000000000000000000000
444f44f411111111111111111111111144444494400000001ddddddd1ddddddd1ddddddd1ddddddd00000000000000001ddddddd000000000000000000000000
f444444f111111111111111111111111444444444000000011111111111111111177771111111111077770000000000011111111000000000000000000000000
4f44f4441111111111111111111111114444444440000000dddd1ddddddd1dddd77007d777d7777d0700707770777000dddd1ddd000000000000000000000000
44f444f40110010011111111111111114444444440000000dddd1ddddddd1dddd777777777771ddd0777777777700000dddd1ddd000000000000000000000000
f4444f440000000111111111111111114444444440000000dddd1ddddddd1dddd7777dd777d7777d0777007770777000dddd1ddd000000000000000000000000
00000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001ddddddd1ddddddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001ddddddd1ddddddd0000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000001ddddddd1ddddddd0000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000011111111111111110000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000dddd1ddddddd1ddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000dddd1ddddddd1ddd0000000000000000000000000000000000000000000000000000000000000000
000000000000000000000000000000000000000000000000dddd1ddddddd1ddd0000000000000000000000000000000000000000000000000000000000000000
__gff__
00000000000300000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000030303030b0000000000000004000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
4141414141414141414141434647474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
5657564c5657565756574c435657474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4647474741414141414141434747474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4647464747464646464647434747474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c464646464646464c5657434647474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4641414141414141464646434646474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4647464746474647464646434647474700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4c4849575657565756474c444c46464600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
4141414141414141414141414141414100004141414141414100000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
