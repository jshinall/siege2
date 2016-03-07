The Master ToDo List, as dictated by RootWyrm (meaning Doctor Krieger and his Comfy Chair.) May also contain design notes (up to 80% by volume.)

# File Layout Resolution
We need to fix the file layout because the current one is just stupid. Editor, Mapper, and Mod need split up cleanly.

Someone who is more familiar with NS2 mod development (meaning someone who is not UWE) will need to chime in here. 
Otherwise, we're gonna end up with a RootWyrm layout. See my other repos to give you some idea of what that looks like.

# LEGAL/LICENSE COMPLIANCE ISSUES
These are top priority. Any components which were integrated from elsewhere **need to be flagged up for inspection post-haste**.

All of these will need to be sorted by need and priority so that permission can be obtained or new development started.

* DESIGN ITEM: RootWyrm Flavored NetCode Because UWE Is Incompetent

The only way to fix the red plugs is fixing the code path, and the only way to fix that is getting out from under the shitshow that is Spark.
Siege doesn't have unique requirements, just bigger ones. Not surprisingly, fixing it this way also fixes everything *ELSE* UWE got 100% wrong. (As usual.)
https://github.com/torch/threads - need to implement this. Already tested with LuaJIT, saving many steps.

- NetCode_Fast0: Fast Update / Fast Poll netcode thread. Player position, bullet/bite, etcetera.
- NetCode_Fast1: High Polling Structures; PG, tunnel, marine structure being built, etc. Fast1(PG)<->Fast0(PlayerPos)
- NetCode_Mid0: Mid-speed thread. Covers all ARC, movable alien structure (!echoing) data
-- Mid0 will incur some reg delay for structure attacks. Oh noes, a few wasted bullets!
- NetCode_Mid1: Mid-speed thread 2; specifically for IP/Egg 
- NetCode_Low0: Low-speed thread. Covers static low-update structures (e.g. built armories, HarmSlab, Spur)

* DESIGN ITEM: Kredits^TM for Krieger

Everyone loves Kredits. We all miss being able to abuse Kredits. So there are two major items we need to do here.
1. Kredits needs to be broken out so it's a standalone mod any server can tack on regardless of other mods.
2. Kredits needs to use an external config file or files so admins can tune to suit their server.
3. Nice to have: some way to hook in/out so users can automatically buy badges, reserve slot, etc. w/Kredits.

General config file layout should be something like:
kredits.conf: item,cost,enabled(bool),maxuse(int)
kredits_users.conf: groupname{steamid,steamid,steamid}
kredits_abuse.conf: item,abuse_enabled(bool),allowed_group(name),maxuse(int)
kredits_badge.hook: steamid{badgeid(int),reserve_slot(bool),etc}

* DESIGN IDEA: 2112 Overture (Krieger's Cannon!)
NS1 had static cannons. Let's bring 'em back. But if they're identical to ARCs, nobody will build 'em. So in terms of 
balance I'm thinking this as a start point:
175% ARC damage, ARC armor - 50%, ARC hp - 50%, crit chance 2% (200% ARC damage), +1 overhead vs ARC, 25 res
Need a model. I'm thinking something like http://vignette2.wikia.nocookie.net/marvelcinematicuniverse/images/4/46/Sonic_Cannon.png/revision/latest?cb=20141129002719

