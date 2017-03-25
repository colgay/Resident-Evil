Misc::Precache()
{
	g_sprTrail = precache_model("sprites/laserbeam.spr");
	g_sprShockwave = precache_model("sprites/shockwave.spr");
	g_sprEExplo = precache_model("sprites/eexplo.spr");
	g_sprFExplo = precache_model("sprites/fexplo.spr");
	g_sprFire = precache_model("sprites/fire.spr");
	g_sprSteam = precache_model("sprites/steam1.spr");
	
	g_modelGlass = precache_model("models/glassgibs.mdl");
}