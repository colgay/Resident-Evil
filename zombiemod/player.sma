new g_resourcePoint[33];
new g_point[33];
new Float:g_maxArmor[33];

Player::Init()
{
	RegisterHam(Ham_TraceAttack, "player", "Player@TraceAttack");
	RegisterHam(Ham_TakeDamage, "player", "Player@TakeDamage");
	RegisterHam(Ham_TakeDamage, "player", "Player@TakeDamage_Post", 1);
}

Player::Disconnect(id)
{
	g_resourcePoint[id] = 0;
	g_point[id] = 0;
	g_maxArmor[id] = 0.0;
}

public Player::TraceAttack(id, attacker, Float:damage, Float:direction[3], tr, damageBits)
{
	//ha
}

public Player::TakeDamage(id)
{
	//ha
}

public Player::TakeDamage_Post(id)
{
	//ha
}

stock Float:getMaxArmor(id)
{
	return g_maxArmor[id];
}

stock setMaxArmor(id, Float:armor)
{
	g_maxArmor[id] = armor;
}

stock getPlayerPoint(id)
{
	return g_point[id];
}

stock setPlayerPoint(id, value)
{
	g_point[id] = value;
}

stock addPoint(id, amount)
{
	g_point[id] += value;
}

stock getResourcePoint(id)
{
	return g_resourcePoint[id];
}

stock setResourcePoint(id, value)
{
	g_resourcePoint[id] = value;
}

stock addResourcePoint(id, amount)
{
	g_resourcePoint[id] += value;
}