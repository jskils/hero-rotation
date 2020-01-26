--- ============================ HEADER ============================
--- ======= LOCALIZE =======
-- Addon
local addonName, addonTable = ...
-- HeroLib
local HL         = HeroLib
local Cache      = HeroCache
local Unit       = HL.Unit
local Player     = Unit.Player
local Target     = Unit.Target
local Pet        = Unit.Pet
local Spell      = HL.Spell
local MultiSpell = HL.MultiSpell
local Item       = HL.Item
-- HeroRotation
local HR         = HeroRotation
local Shaman     = HR.Commons.Shaman
-- LUA
local floor      = math.floor

--- ============================ CONTENT ===========================
--- ======= APL LOCALS =======
-- luacheck: max_line_length 9999

-- Spells
if not Spell.Shaman then Spell.Shaman = {} end
Spell.Shaman.Elemental = {
  TotemMastery                          = Spell(210643),
  StormkeeperBuff                       = Spell(191634),
  Stormkeeper                           = Spell(191634),
  UnlimitedPower                        = Spell(260895),
  PrimalElementalist                    = Spell(117013),
  FireElemental                         = Spell(198067),
  StormElemental                        = Spell(192249),
  ElementalBlast                        = Spell(117014),
  LavaBurst                             = Spell(51505),
  ChainLightning                        = Spell(188443),
  FlameShock                            = Spell(188389),
  FlameShockDebuff                      = Spell(188389),
  WindGustBuff                          = Spell(263806),
  Ascendance                            = Spell(114050),
  Icefury                               = Spell(210714),
  IcefuryBuff                           = Spell(210714),
  LiquidMagmaTotem                      = Spell(192222),
  Earthquake                            = Spell(61882),
  MasteroftheElements                   = Spell(16166),
  MasteroftheElementsBuff               = Spell(260734),
  LavaSurgeBuff                         = Spell(77762),
  AscendanceBuff                        = Spell(114050),
  FrostShock                            = Spell(196840),
  LavaBeam                              = Spell(114074),
  IgneousPotential                      = Spell(279829),
  SurgeofPowerBuff                      = Spell(285514),
  NaturalHarmony                        = Spell(278697),
  SurgeofPower                          = Spell(262303),
  LightningBolt                         = Spell(188196),
  LavaShock                             = Spell(273448),
  LavaShockBuff                         = Spell(273453),
  TectonicThunder                       = Spell(286949),
  CalltheThunder                        = Spell(260897),
  EarthShock                            = Spell(8042),
  EchooftheElementals                   = Spell(275381),
  EchooftheElements                     = Spell(108283),
  ResonanceTotemBuff                    = Spell(202192),
  TectonicThunderBuff                   = Spell(286949),
  WindShear                             = Spell(57994),
  BloodFury                             = Spell(20572),
  Berserking                            = Spell(26297),
  Fireblood                             = Spell(265221),
  AncestralCall                         = Spell(274738),
  BagofTricks                           = Spell(312411),
  BloodoftheEnemy                       = MultiSpell(297108, 298273, 298277),
  MemoryofLucidDreams                   = MultiSpell(298357, 299372, 299374),
  PurifyingBlast                        = MultiSpell(295337, 299345, 299347),
  RippleInSpace                         = MultiSpell(302731, 302982, 302983),
  ConcentratedFlame                     = MultiSpell(295373, 299349, 299353),
  TheUnboundForce                       = MultiSpell(298452, 299376, 299378),
  WorldveinResonance                    = MultiSpell(295186, 298628, 299334),
  FocusedAzeriteBeam                    = MultiSpell(295258, 299336, 299338),
  GuardianofAzeroth                     = MultiSpell(295840, 299355, 299358),
  ReapingFlames                         = MultiSpell(310690, 310705, 310710),
  RecklessForceBuff                     = Spell(302932),
  ConcentratedFlameBurn                 = Spell(295368),
  LightningLasso                        = Spell(305483)
};
local S = Spell.Shaman.Elemental;

-- Items
if not Item.Shaman then Item.Shaman = {} end
Item.Shaman.Elemental = {
  PotionofUnbridledFury          = Item(169299),
  AzsharasFontofPower            = Item(169314, {13, 14})
};
local I = Item.Shaman.Elemental;

-- Rotation Var
local ShouldReturn; -- Used to get the return string
local EnemiesCount;

-- GUI Settings
local Everyone = HR.Commons.Everyone;
local Settings = {
  General = HR.GUISettings.General,
  Commons = HR.GUISettings.APL.Shaman.Commons,
  Elemental = HR.GUISettings.APL.Shaman.Elemental
};


local EnemyRanges = {40, 5}
local function UpdateRanges()
  for _, i in ipairs(EnemyRanges) do
    HL.GetEnemies(i);
  end
end

local function GetEnemiesCount(range)
  -- Unit Update - Update differently depending on if splash data is being used
  if HR.AoEON() then
    if Settings.Elemental.UseSplashData then
      HL.GetEnemies(range, nil, true, Target)
      return Cache.EnemiesCount[range]
    else
      UpdateRanges()
      Everyone.AoEToggleEnemiesUpdate()
      return Cache.EnemiesCount[40]
    end
  else
    return 1
  end
end

local function ResonanceTotemTime()
  for index=1,4 do
    local _, totemName, startTime, duration = GetTotemInfo(index)
    if totemName == S.TotemMastery:Name() then
      return (floor(startTime + duration - GetTime() + 0.5)) or 0
    end
  end
  return 0
end

local function num(val)
  if val then return 1 else return 0 end
end

local function bool(val)
  return val ~= 0
end

local function EvaluateCycleFlameShock47(TargetUnit)
  return TargetUnit:DebuffRefreshableCP(S.FlameShockDebuff) and (EnemiesCount < (5 - num(not S.TotemMastery:IsAvailable())) or not S.StormElemental:IsAvailable() and (S.FireElemental:CooldownRemainsP() > (120 + 14 * Player:SpellHaste()) or S.FireElemental:CooldownRemainsP() < (24 - 14 * Player:SpellHaste()))) and (not S.StormElemental:IsAvailable() or S.StormElemental:CooldownRemainsP() < 120 or EnemiesCount == 3 and Player:BuffStackP(S.WindGustBuff) < 14)
end

local function EvaluateCycleFlameShock148(TargetUnit)
  return TargetUnit:DebuffRefreshableCP(S.FlameShockDebuff)
end

local function EvaluateCycleFlameShock163(TargetUnit)
  return (TargetUnit:DebuffDownP(S.FlameShockDebuff) or S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 2 * Player:GCD() or TargetUnit:DebuffRemainsP(S.FlameShockDebuff) <= Player:GCD() or S.Ascendance:IsAvailable() and TargetUnit:DebuffRemainsP(S.FlameShockDebuff) < (S.Ascendance:CooldownRemainsP() + S.AscendanceBuff:BaseDuration()) and S.Ascendance:CooldownRemainsP() < 4 and (not S.StormElemental:IsAvailable() or S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 120)) and (Player:BuffStackP(S.WindGustBuff) < 14 or S.IgneousPotential:AzeriteRank() >= 2 or Player:BuffP(S.LavaSurgeBuff) or not Player:HasHeroism()) and Player:BuffDownP(S.SurgeofPowerBuff)
end

local function EvaluateCycleFlameShock390(TargetUnit)
  return TargetUnit:DebuffRefreshableCP(S.FlameShockDebuff) and EnemiesCount > 1 and Player:BuffP(S.SurgeofPowerBuff)
end

local function EvaluateCycleFlameShock511(TargetUnit)
  return TargetUnit:DebuffRefreshableCP(S.FlameShockDebuff) and Player:BuffDownP(S.SurgeofPowerBuff)
end

local function EvaluateCycleFlameShock562(TargetUnit)
  return TargetUnit:DebuffRefreshableCP(S.FlameShockDebuff)
end

local function EvaluateCycleFlameShock702(TargetUnit)
  return ((TargetUnit:DebuffDownP(S.FlameShockDebuff) or S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 2 * Player:GCD() or TargetUnit:DebuffRemainsP(S.FlameShockDebuff) <= Player:GCD() or S.Ascendance:IsAvailable() and TargetUnit:DebuffRemainsP(S.FlameShockDebuff) < (S.Ascendance:CooldownRemainsP() + S.AscendanceBuff:BaseDuration()) and S.Ascendance:CooldownRemainsP() < 4 and (not S.StormElemental:IsAvailable() or S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 120)) and (Player:BuffStackP(S.WindGustBuff) < 14 or S.IgneousPotential:AzeriteRank() >= 2 or Player:BuffP(S.LavaSurgeBuff) or not Player:HasHeroism()) and Player:BuffDownP(S.SurgeofPowerBuff))
end

--- ======= ACTION LISTS =======
local function APL()
  local Precombat, Aoe, Funnel, SingleTarget
  EnemiesCount = GetEnemiesCount(8)
  HL.GetEnemies(40) -- For CastCycle calls
  Precombat = function()
    -- flask
    -- food
    -- augmentation
    -- snapshot_stats
    if Everyone.TargetIsValid() then
      -- totem_mastery
      if S.TotemMastery:IsReadyP() then
        if HR.Cast(S.TotemMastery) then return "totem_mastery 4"; end
      end
      -- earth_elemental,if=!talent.primal_elementalist
      -- use_item,name=azsharas_font_of_power
      if I.AzsharasFontofPower:IsEquipReady() then
        if HR.Cast(I.AzsharasFontofPower, nil, Settings.Commons.TrinketDisplayStyle) then return "azsharas_font_of_power 6"; end
      end
      -- stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
      if S.Stormkeeper:IsCastableP() and Player:BuffDownP(S.StormkeeperBuff) and (S.Stormkeeper:IsAvailable() and ((EnemiesCount - 1) < 3)) then
        if HR.Cast(S.Stormkeeper) then return "stormkeeper 7"; end
      end
      -- potion
      if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions then
        if HR.CastSuggested(I.PotionofUnbridledFury) then return "battle_potion_of_intellect 27"; end
      end
      -- elemental_blast,if=talent.elemental_blast.enabled
      if S.ElementalBlast:IsCastableP() and (S.ElementalBlast:IsAvailable()) then
        if HR.Cast(S.ElementalBlast) then return "elemental_blast 29"; end
      end
      -- lava_burst,if=!talent.elemental_blast.enabled
      if S.LavaBurst:IsCastableP() and (not S.ElementalBlast:IsAvailable() and not Player:IsCasting(S.LavaBurst)) then
        if HR.Cast(S.LavaBurst) then return "lava_burst 33"; end
      end
    end
  end
  Aoe = function()
    -- stormkeeper,if=talent.stormkeeper.enabled
    if S.Stormkeeper:IsCastableP() and (S.Stormkeeper:IsAvailable()) then
      if HR.Cast(S.Stormkeeper, Settings.Elemental.GCDasOffGCD.Stormkeeper) then return "stormkeeper 39"; end
    end
    -- flame_shock,target_if=refreshable&(spell_targets.chain_lightning<(5-!talent.totem_mastery.enabled)|!talent.storm_elemental.enabled&(cooldown.fire_elemental.remains>(cooldown.storm_elemental.duration-30+14*spell_haste)|cooldown.fire_elemental.remains<(24-14*spell_haste)))&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<cooldown.storm_elemental.duration-30|spell_targets.chain_lightning=3&buff.wind_gust.stack<14)
    if S.FlameShock:IsCastableP() then
      if HR.CastCycle(S.FlameShock, 40, EvaluateCycleFlameShock47) then return "flame_shock 69" end
    end
    -- ascendance,if=talent.ascendance.enabled&(talent.storm_elemental.enabled&cooldown.storm_elemental.remains<cooldown.storm_elemental.duration-30&cooldown.storm_elemental.remains>15|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
    if S.Ascendance:IsCastableP() and HR.CDsON() and (S.Ascendance:IsAvailable() and (S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 120 and S.StormElemental:CooldownRemainsP() > 15 or not S.StormElemental:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and not S.Icefury:CooldownUpP())) then
      if HR.Cast(S.Ascendance, Settings.Elemental.GCDasOffGCD.Ascendance) then return "ascendance 70"; end
    end
    -- liquid_magma_totem,if=talent.liquid_magma_totem.enabled
    if S.LiquidMagmaTotem:IsCastableP() and (S.LiquidMagmaTotem:IsAvailable()) then
      if HR.Cast(S.LiquidMagmaTotem) then return "liquid_magma_totem 88"; end
    end
    -- earthquake,if=!talent.master_of_the_elements.enabled|buff.stormkeeper.up|maelstrom>=(100-4*spell_targets.chain_lightning)|buff.master_of_the_elements.up|spell_targets.chain_lightning>3
    if S.Earthquake:IsReadyP() and (not S.MasteroftheElements:IsAvailable() or Player:BuffP(S.StormkeeperBuff) or Player:Maelstrom() >= (100 - 4 * EnemiesCount) or Player:BuffP(S.MasteroftheElementsBuff) or EnemiesCount > 3) then
      if HR.Cast(S.Earthquake) then return "earthquake 92"; end
    end
    -- blood_of_the_enemy,if=!talent.primal_elementalist.enabled|!talent.storm_elemental.enabled
    if S.BloodoftheEnemy:IsCastableP() and (not S.PrimalElementalist:IsAvailable() or not S.StormElemental:IsAvailable()) then
      if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle) then return "blood_of_the_enemy 96"; end
    end
    -- chain_lightning,if=buff.stormkeeper.remains<3*gcd*buff.stormkeeper.stack
    if S.ChainLightning:IsCastableP() and (Player:BuffRemainsP(S.StormkeeperBuff) < 3 * Player:GCD() * Player:BuffStackP(S.StormkeeperBuff)) then
      if HR.Cast(S.ChainLightning) then return "chain_lightning 100"; end
    end
    -- lava_burst,if=buff.lava_surge.up&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30))&dot.flame_shock.ticking
    if S.LavaBurst:IsCastableP() and (Player:BuffP(S.LavaSurgeBuff) and EnemiesCount < 4 and (not S.StormElemental:IsAvailable() or S.StormElemental:CooldownRemainsP() < 120) and Target:DebuffP(S.FlameShockDebuff)) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 106"; end
    end
    -- icefury,if=spell_targets.chain_lightning<4&!buff.ascendance.up
    if S.Icefury:IsCastableP() and (EnemiesCount < 4 and Player:BuffDownP(S.AscendanceBuff)) then
      if HR.Cast(S.Icefury) then return "icefury 116"; end
    end
    -- frost_shock,if=spell_targets.chain_lightning<4&buff.icefury.up&!buff.ascendance.up
    if S.FrostShock:IsCastableP() and (EnemiesCount < 4 and Player:BuffP(S.IcefuryBuff) and Player:BuffDownP(S.AscendanceBuff)) then
      if HR.Cast(S.FrostShock) then return "frost_shock 120"; end
    end
    -- elemental_blast,if=talent.elemental_blast.enabled&spell_targets.chain_lightning<4&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30))
    if S.ElementalBlast:IsCastableP() and (S.ElementalBlast:IsAvailable() and EnemiesCount < 4 and (not S.StormElemental:IsAvailable() or S.StormElemental:CooldownRemainsP() < 120)) then
      if HR.Cast(S.ElementalBlast) then return "elemental_blast 126"; end
    end
    -- lava_beam,if=talent.ascendance.enabled
    if S.LavaBeam:IsCastableP() and (S.Ascendance:IsAvailable()) then
      if HR.Cast(S.LavaBeam) then return "lava_beam 134"; end
    end
    -- chain_lightning
    if S.ChainLightning:IsCastableP() then
      if HR.Cast(S.ChainLightning) then return "chain_lightning 138"; end
    end
    -- lava_burst,moving=1,if=talent.ascendance.enabled
    if S.LavaBurst:IsCastableP() and Player:IsMoving() and (S.Ascendance:IsAvailable()) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 140"; end
    end
    -- flame_shock,moving=1,target_if=refreshable
    if S.FlameShock:IsCastableP() and Player:IsMoving() then
      if HR.CastCycle(S.FlameShock, 40, EvaluateCycleFlameShock148) then return "flame_shock 156" end
    end
    -- frost_shock,moving=1
    if S.FrostShock:IsCastableP() and Player:IsMoving() then
      if HR.Cast(S.FrostShock) then return "frost_shock 157"; end
    end
  end
  Funnel = function()
    -- flame_shock,target_if=(!ticking|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
    if S.FlameShock:IsCastableP() and ((Target:DebuffDownP(S.FlameShockDebuff) or Target:DebuffRemainsP(S.FlameShockDebuff) <= Player:GCD() or S.Ascendance:IsAvailable() and Target:DebuffRemainsP(S.FlameShockDebuff) < (S.Ascendance:CooldownRemainsP() + 15) and S.Ascendance:CooldownRemainsP() < 4 and (not S.StormElemental:IsAvailable() or S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 120)) and (Player:BuffStackP(S.WindGustBuff) < 14 or S.IgneousPotential:AzeriteRank() >= 2 or Player:BuffP(S.LavaSurgeBuff) or not Player:HasHeroism()) and Player:BuffDownP(S.SurgeofPowerBuff)) then
      if HR.Cast(S.FlameShock) then return "flame_shock 702"; end
    end
    -- blood_of_the_enemy,if=!talent.ascendance.enabled&(!talent.storm_elemental.enabled|!talent.primal_elementalist.enabled)|talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
    if S.BloodoftheEnemy:IsCastableP() and (not S.Ascendance:IsAvailable() and (not S.StormElemental:IsAvailable() or not S.PrimalElementalist:IsAvailable()) or S.Ascendance:IsAvailable() and (HL.CombatTime() >= 60 or Player:HasHeroism()) and S.LavaBurst:CooldownRemainsP() > 0 and (S.StormElemental:CooldownRemainsP() < 120 or not S.StormElemental:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and not S.Icefury:CooldownUpP())) then
      if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle) then return "blood_of_the_enemy 704"; end
    end
    -- ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
    if S.Ascendance:IsCastableP() and (S.Ascendance:IsAvailable() and (HL.CombatTime() >= 60 or Player:HasHeroism()) and bool(S.LavaBurst:CooldownRemainsP()) and (S.StormElemental:CooldownRemainsP() < 120 or not S.StormElemental:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and not S.Icefury:CooldownUpP())) then
      if HR.Cast(S.Ascendance, Settings.Elemental.GCDasOffGCD.Ascendance) then return "ascendance 706"; end
    end
    -- elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&buff.master_of_the_elements.up&maelstrom<60|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
    if S.ElementalBlast:IsCastableP() and (S.ElementalBlast:IsAvailable() and (S.MasteroftheElements:IsAvailable() and Player:BuffP(S.MasteroftheElementsBuff) and Player:Maelstrom() < 60 or not S.MasteroftheElements:IsAvailable()) and (not (S.StormElemental:CooldownRemainsP() > 120 and S.StormElemental:IsAvailable()) or S.NaturalHarmony:AzeriteRank() == 3 and Player:BuffStackP(S.WindGustBuff) < 14)) then
      if HR.Cast(S.ElementalBlast) then return "elemental_blast 708"; end
    end
    -- stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
    if S.Stormkeeper:IsCastableP() and (S.Stormkeeper:IsAvailable() and EnemiesCount < 3 and (not S.SurgeofPower:IsAvailable() or Player:BuffP(S.SurgeofPowerBuff) or Player:Maelstrom() >= 44)) then
      if HR.Cast(S.Stormkeeper, Settings.Elemental.GCDasOffGCD.Stormkeeper) then return "stormkeeper 710"; end
    end
    -- liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
    if S.LiquidMagmaTotem:IsCastableP() and (S.LiquidMagmaTotem:IsAvailable() and EnemiesCount < 3) then
      if HR.Cast(S.LiquidMagmaTotem) then return "liquid_magma_totem 712"; end
    end
    -- lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<6&(azerite.lava_shock.rank*buff.lava_shock.stack)<36&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
    if S.LightningBolt:IsCastableP() and (Player:BuffP(S.StormkeeperBuff) and EnemiesCount < 6 and (S.LavaShock:AzeriteRank() * Player:BuffStackP(S.LavaShockBuff)) < 36 and (Player:BuffP(S.MasteroftheElementsBuff) and not S.SurgeofPower:IsAvailable() or Player:BuffP(S.SurgeofPowerBuff))) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 714"; end
    end
    -- earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|(azerite.lava_shock.rank*buff.lava_shock.stack<36)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
    if S.EarthShock:IsReadyP() and (Player:BuffDownP(S.SurgeofPowerBuff) and S.MasteroftheElements:IsAvailable() and (Player:BuffP(S.MasteroftheElementsBuff) or not S.LavaBurst:CooldownUpP() and Player:Maelstrom() >= 92 + 30 * num(S.CalltheThunder:IsAvailable()) or (S.LavaShock:AzeriteRank() * Player:BuffStackP(S.LavaShockBuff) < 36) and Player:BuffP(S.StormkeeperBuff) and S.LavaBurst:CooldownRemainsP() <= Player:GCD())) then
      if HR.Cast(S.EarthShock) then return "earth_shock 716"; end
    end
    -- earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
    if S.EarthShock:IsReadyP() and (not S.MasteroftheElements:IsAvailable() and not (S.IgneousPotential:AzeriteRank() > 2 and Player:BuffP(S.AscendanceBuff)) and (Player:BuffP(S.StormkeeperBuff) or Player:Maelstrom() >= 90 + 30 * num(S.CalltheThunder:IsAvailable()) or not (S.StormElemental:CooldownRemainsP() > 120 and S.StormElemental:IsAvailable()) and Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * floor((Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) % 150) >= 30 * (1 + num(S.EchooftheElementals:AzeriteRank() >= 2)))) then
      if HR.Cast(S.EarthShock) then return "earth_shock 718"; end
    end
    -- earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>(cooldown.storm_elemental.duration-30))|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)))
    if S.EarthShock:IsReadyP() and (S.SurgeofPower:IsAvailable() and Player:BuffDownP(S.SurgeofPowerBuff) and S.LavaBurst:CooldownRemainsP() <= Player:GCD() and (not S.StormElemental:IsAvailable() and not (S.FireElemental:CooldownRemainsP() > 120) or S.StormElemental:IsAvailable() and not (S.StormElemental:CooldownRemainsP() > 120))) then
      if HR.Cast(S.EarthShock) then return "earth_shock 720"; end
    end
    -- lightning_bolt,if=cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
    if S.LightningBolt:IsCastableP() and (S.StormElemental:CooldownRemainsP() > 120 and S.StormElemental:IsAvailable() and (S.IgneousPotential:AzeriteRank() < 2 or Player:BuffDownP(S.LavaSurgeBuff) and Player:HasHeroism())) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 722"; end
    end
    -- lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
    if S.LightningBolt:IsCastableP() and (Player:BuffRemainsP(S.StormkeeperBuff) < 1.1 * Player:GCD() * Player:BuffStackP(S.StormkeeperBuff) or Player:BuffP(S.StormkeeperBuff) and Player:BuffP(S.MasteroftheElementsBuff)) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 724"; end
    end
    -- frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
    if S.FrostShock:IsCastableP() and (S.Icefury:IsAvailable() and S.MasteroftheElements:IsAvailable() and Player:BuffP(S.IcefuryBuff) and Player:BuffP(S.MasteroftheElementsBuff)) then
      if HR.Cast(S.FrostShock) then return "frost_shock 726"; end
    end
    -- lava_burst,if=buff.ascendance.up
    if S.LavaBurst:IsReadyP() and (Player:BuffP(S.AscendanceBuff)) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 728"; end
    end
    -- flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
    if S.FlameShock:IsCastableP() and (Target:DebuffRefreshableCP(S.FlameShock) and EnemiesCount > 1 and Player:BuffP(S.SurgeofPowerBuff)) then
      if HR.Cast(S.FlameShock) then return "flame_shock 730"; end
    end
    -- lava_burst,if=talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains-150*floor((1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains)%150))<(expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)))
    if S.LavaBurst:IsCastableP() and (S.StormElemental:IsAvailable() and Player:BuffP(S.LavaSurgeBuff) and Player:BuffP(S.SurgeofPowerBuff) and (Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * floor((Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) % 150) < 30 * (1 + num(S.EchooftheElementals:AzeriteRank() >= 2)) or (1.16 * Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * floor((1.16 * Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) % 150)) < (Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * floor((Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) % 150)))) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 732"; end
    end
    -- lava_burst,if=!talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.fire_elemental.remains-150*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%150)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains-150*floor((1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains)%150))<(expected_combat_length-time-cooldown.fire_elemental.remains-150*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%150)))
    if S.LavaBurst:IsCastableP() and (not S.StormElemental:IsAvailable() and Player:BuffP(S.LavaSurgeBuff) and Player:BuffP(S.SurgeofPowerBuff) and (Target:TimeToDie() - S.FireElemental:CooldownRemainsP() - 150 * floor((Target:TimeToDie() - S.FireElemental:CooldownRemainsP()) % 150) < 30 * (1 + (num(S.EchooftheElementals:AzeriteRank() >= 2))) or (1.16 * Target:TimeToDie() - S.FireElemental:CooldownRemainsP() - 150 * floor((1.16 * Target:TimeToDie() - S.FireElemental:CooldownRemainsP()) % 150)) < (Target:TimeToDie() - S.FireElemental:CooldownRemainsP() - 150 * floor((Target:TimeToDie() - S.FireElemental:CooldownRemainsP()) % 150)))) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 734"; end
    end
    -- lightning_bolt,if=buff.surge_of_power.up
    if S.LightningBolt:IsCastableP() and (Player:BuffP(S.SurgeofPowerBuff)) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 736"; end
    end
    -- lava_burst,if=cooldown_react&!talent.master_of_the_elements.enabled
    if S.LavaBurst:IsCastableP() and (Player:BuffP(S.LavaSurgeBuff) and not S.MasteroftheElements:IsAvailable()) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 738"; end
    end
    -- icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<cooldown.storm_elemental.duration)
    if S.Icefury:IsCastableP() and (S.Icefury:IsAvailable() and not (Player:Maelstrom() > 75 and S.LavaBurst:CooldownUpP()) and (not S.StormElemental:IsAvailable() or S.StormElemental:CooldownRemainsP() < 120)) then
      if HR.Cast(S.Icefury) then return "icefury 740"; end
    end
    -- lava_burst,if=cooldown_react&charges>talent.echo_of_the_elements.enabled
    if S.LavaBurst:IsCastableP() and (Player:BuffP(S.LavaSurgeBuff) and S.LavaBurst:ChargesP() > num(S.EchooftheElementals:IsAvailable())) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 742"; end
    end
    -- frost_shock,if=talent.icefury.enabled&buff.icefury.up&buff.icefury.remains<1.1*gcd*buff.icefury.stack
    if S.FrostShock:IsCastableP() and (S.Icefury:IsAvailable() and Player:BuffP(S.IcefuryBuff) and Player:BuffRemainsP(S.IcefuryBuff) < 1.1 * Player:GCD() * num(Player:BuffStackP(S.IcefuryBuff))) then
      if HR.Cast(S.FrostShock) then return "frost_shock 744"; end
    end
    -- lava_burst,if=cooldown_react
    if S.LavaBurst:IsCastableP() and (Player:BuffP(S.LavaSurgeBuff)) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 746"; end
    end
    -- concentrated_flame
    if S.ConcentratedFlame:IsCastableP() then
      if HR.Cast(S.ConcentratedFlame, nil, Settings.Commons.EssenceDisplayStyle) then return "concentrated_flame 747"; end
    end
    -- reaping_flames
    if S.ReapingFlames:IsCastableP() then
      if HR.Cast(S.ReapingFlames, nil, Settings.Commons.EssenceDisplayStyle) then return "reaping_flames 748"; end
    end
    -- flame_shock,target_if=refreshable&!buff.surge_of_power.up
    if S.FlameShock:IsCastableP() and (Target:DebuffRefreshableCP(S.FlameShockDebuff) and Player:BuffDownP(S.SurgeofPowerBuff)) then
      if HR.Cast(S.FlameShock) then return "flame_shock 749"; end
    end
    -- totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15))
    if S.TotemMastery:IsReadyP() and (S.TotemMastery:IsAvailable() and (ResonanceTotemTime() < 6 or (ResonanceTotemTime() < (S.Ascendance:BaseDuration() + S.Ascendance:CooldownRemainsP()) and S.Ascendance:CooldownRemainsP() < 15))) then
      if HR.Cast(S.TotemMastery) then return "totem_mastery 750"; end
    end
    -- frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
    if S.FrostShock:IsCastableP() and (S.Icefury:IsAvailable() and Player:BuffP(S.IcefuryBuff) and (Player:BuffRemainsP(S.IcefuryBuff) < Player:GCD() * 4 * Player:BuffStackP(S.IcefuryBuff) or Player:BuffP(S.StormkeeperBuff) or not S.MasteroftheElements:IsAvailable())) then
      if HR.Cast(S.FrostShock) then return "frost_shock 752"; end
    end
    -- earth_elemental,if=!talent.primal_elementalist.enabled|talent.primal_elementalist.enabled&(cooldown.fire_elemental.remains<(cooldown.fire_elemental.duration-30)&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)
    -- flame_shock,moving=1,target_if=refreshable
    if S.FlameShock:IsCastableP() and (Player:IsMoving() and Target:DebuffRefreshableCP(S.FlameShockDebuff)) then
      if HR.Cast(S.FlameShock) then return "flame_shock 754"; end
    end
    -- flame_shock,moving=1,if=movement.distance>6
    -- frost_shock,moving=1
    if S.FlameShock:IsCastableP() and (Player:IsMoving()) then
      if HR.Cast(S.FlameShock) then return "flame_shock 756"; end
    end
    -- lightning_bolt
    -- Moved moving abilities above LB filler
    if S.LightningBolt:IsCastableP() then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 758"; end
    end
  end
  SingleTarget = function()
    -- flame_shock,target_if=(!ticking|dot.flame_shock.remains<=gcd|talent.ascendance.enabled&dot.flame_shock.remains<(cooldown.ascendance.remains+buff.ascendance.duration)&cooldown.ascendance.remains<4&(!talent.storm_elemental.enabled|talent.storm_elemental.enabled&cooldown.storm_elemental.remains<120))&(buff.wind_gust.stack<14|azerite.igneous_potential.rank>=2|buff.lava_surge.up|!buff.bloodlust.up)&!buff.surge_of_power.up
    if S.FlameShock:IsCastableP() and ((Target:DebuffDownP(S.FlameShockDebuff) or Target:DebuffRemainsP(S.FlameShockDebuff) <= Player:GCD() or S.Ascendance:IsAvailable() and Target:DebuffRemainsP(S.FlameShockDebuff) < (S.Ascendance:CooldownRemainsP() + 15) and S.Ascendance:CooldownRemainsP() < 4 and (not S.StormElemental:IsAvailable() or S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 120)) and (Player:BuffStackP(S.WindGustBuff) < 14 or S.IgneousPotential:AzeriteRank() >= 2 or Player:BuffP(S.LavaSurgeBuff) or not Player:HasHeroism()) and Player:BuffDownP(S.SurgeofPowerBuff)) then
      if HR.Cast(S.FlameShock) then return "flame_shock 200"; end
    end
    -- blood_of_the_enemy,if=!talent.ascendance.enabled&!talent.storm_elemental.enabled|talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
    if S.BloodoftheEnemy:IsCastableP() and (not S.Ascendance:IsAvailable() and not S.StormElemental:IsAvailable() or S.Ascendance:IsAvailable() and (HL.CombatTime() >= 60 or Player:HasHeroism()) and S.LavaBurst:CooldownRemainsP() > 0 and (S.StormElemental:CooldownRemainsP() < 120 or not S.StormElemental:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and not S.Icefury:CooldownUpP())) then
      if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle) then return "blood_of_the_enemy 201"; end
    end
    -- ascendance,if=talent.ascendance.enabled&(time>=60|buff.bloodlust.up)&cooldown.lava_burst.remains>0&(cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)
    if S.Ascendance:IsCastableP() and HR.CDsON() and (S.Ascendance:IsAvailable() and (HL.CombatTime() >= 60 or Player:HasHeroism()) and S.LavaBurst:CooldownRemainsP() > 0 and (S.StormElemental:CooldownRemainsP() < 120 or not S.StormElemental:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and not S.Icefury:CooldownUpP())) then
      if HR.Cast(S.Ascendance, Settings.Elemental.GCDasOffGCD.Ascendance) then return "ascendance 202"; end
    end
    -- elemental_blast,if=talent.elemental_blast.enabled&(talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up&maelstrom<60|!buff.master_of_the_elements.up)|!talent.master_of_the_elements.enabled)&(!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)|azerite.natural_harmony.rank=3&buff.wind_gust.stack<14)
    if S.ElementalBlast:IsCastableP() and (S.ElementalBlast:IsAvailable() and (S.MasteroftheElements:IsAvailable() and (Player:BuffP(S.MasteroftheElementsBuff) and Player:Maelstrom() < 60 or Player:BuffDownP(S.MasteroftheElementsBuff)) or not S.MasteroftheElements:IsAvailable()) and (not (S.StormElemental:CooldownRemainsP() > 120 and S.StormElemental:IsAvailable()) or S.NaturalHarmony:AzeriteRank() == 3 and Player:BuffStackP(S.WindGustBuff) < 14)) then
      if HR.Cast(S.ElementalBlast) then return "elemental_blast 218"; end
    end
    -- stormkeeper,if=talent.stormkeeper.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)&(!talent.surge_of_power.enabled|buff.surge_of_power.up|maelstrom>=44)
    if S.Stormkeeper:IsCastableP() and (S.Stormkeeper:IsAvailable() and ((EnemiesCount - 1) < 3) and (not S.SurgeofPower:IsAvailable() or Player:BuffP(S.SurgeofPowerBuff) or Player:Maelstrom() >= 44)) then
      if HR.Cast(S.Stormkeeper, Settings.Elemental.GCDasOffGCD.Stormkeeper) then return "stormkeeper 236"; end
    end
    -- liquid_magma_totem,if=talent.liquid_magma_totem.enabled&(raid_event.adds.count<3|raid_event.adds.in>50)
    if S.LiquidMagmaTotem:IsCastableP() and (S.LiquidMagmaTotem:IsAvailable() and ((EnemiesCount - 1) < 3)) then
      if HR.Cast(S.LiquidMagmaTotem) then return "liquid_magma_totem 246"; end
    end
    -- lightning_bolt,if=buff.stormkeeper.up&spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack)<26&(buff.master_of_the_elements.up&!talent.surge_of_power.enabled|buff.surge_of_power.up)
    if S.LightningBolt:IsCastableP() and (Player:BuffP(S.StormkeeperBuff) and EnemiesCount < 2 and (S.LavaShock:AzeriteRank() * Player:BuffStackP(S.LavaShockBuff)) < 26 and (Player:BuffP(S.MasteroftheElementsBuff) and not S.SurgeofPower:IsAvailable() or Player:BuffP(S.SurgeofPowerBuff))) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 252"; end
    end
    -- earthquake,if=(spell_targets.chain_lightning>1|azerite.tectonic_thunder.rank>=3&!talent.surge_of_power.enabled&azerite.lava_shock.rank<1)&azerite.lava_shock.rank*buff.lava_shock.stack<(36+3*azerite.tectonic_thunder.rank*spell_targets.chain_lightning)&(!talent.surge_of_power.enabled|!dot.flame_shock.refreshable|cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30))&(!talent.master_of_the_elements.enabled|buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled)
    if S.Earthquake:IsReadyP() and ((EnemiesCount > 1 or S.TectonicThunder:AzeriteRank() >= 3 and not S.SurgeofPower:IsAvailable() and S.LavaShock:AzeriteRank() < 1) and S.LavaShock:AzeriteRank() * Player:BuffStackP(S.LavaShockBuff) < (36 + 3 * S.TectonicThunder:AzeriteRank() * EnemiesCount) and (not S.SurgeofPower:IsAvailable() or not Target:DebuffRefreshableCP(S.FlameShockDebuff) or S.StormElemental:CooldownRemainsP() > 120) and (not S.MasteroftheElements:IsAvailable() or Player:BuffP(S.MasteroftheElementsBuff) or S.LavaBurst:CooldownRemainsP() > 0 and Player:Maelstrom() >= 92 + 30 * num(S.CalltheThunder:IsAvailable()))) then
      if HR.Cast(S.Earthquake) then return "earthquake 266"; end
    end
    -- earth_shock,if=!buff.surge_of_power.up&talent.master_of_the_elements.enabled&(buff.master_of_the_elements.up|cooldown.lava_burst.remains>0&maelstrom>=92+30*talent.call_the_thunder.enabled|spell_targets.chain_lightning<2&(azerite.lava_shock.rank*buff.lava_shock.stack<26)&buff.stormkeeper.up&cooldown.lava_burst.remains<=gcd)
    if S.EarthShock:IsReadyP() and (Player:BuffDownP(S.SurgeofPowerBuff) and S.MasteroftheElements:IsAvailable() and (Player:BuffP(S.MasteroftheElementsBuff) or S.LavaBurst:CooldownRemainsP() > 0 and Player:Maelstrom() >= 92 + 30 * num(S.CalltheThunder:IsAvailable()) or EnemiesCount < 2 and (S.LavaShock:AzeriteRank() * Player:BuffStackP(S.LavaShockBuff) < 26) and Player:BuffP(S.StormkeeperBuff) and S.LavaBurst:CooldownRemainsP() <= Player:GCD())) then
      if HR.Cast(S.EarthShock) then return "earth_shock 294"; end
    end
    -- earth_shock,if=!talent.master_of_the_elements.enabled&!(azerite.igneous_potential.rank>2&buff.ascendance.up)&(buff.stormkeeper.up|maelstrom>=90+30*talent.call_the_thunder.enabled|!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)&expected_combat_length-time-cooldown.storm_elemental.remains-150*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%150)>=30*(1+(azerite.echo_of_the_elementals.rank>=2)))
    if S.EarthShock:IsReadyP() and (not S.MasteroftheElements:IsAvailable() and not (S.IgneousPotential:AzeriteRank() > 2 and Player:BuffP(S.AscendanceBuff)) and (Player:BuffP(S.StormkeeperBuff) or Player:Maelstrom() >= 90 + 30 * num(S.CalltheThunder:IsAvailable()) or not (S.StormElemental:CooldownRemainsP() > 120 and S.StormElemental:IsAvailable()) and Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * math.floor ((Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) / 150) >= 30 * (1 + num((S.EchooftheElementals:AzeriteRank() >= 2))))) then
      if HR.Cast(S.EarthShock) then return "earth_shock 314"; end
    end
    -- earth_shock,if=talent.surge_of_power.enabled&!buff.surge_of_power.up&cooldown.lava_burst.remains<=gcd&(!talent.storm_elemental.enabled&!(cooldown.fire_elemental.remains>(cooldown.fire_elemental.duration-30))|talent.storm_elemental.enabled&!(cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)))
    if S.EarthShock:IsReadyP() and (S.SurgeofPower:IsAvailable() and Player:BuffDownP(S.SurgeofPowerBuff) and S.LavaBurst:CooldownRemainsP() <= Player:GCD() and (not S.StormElemental:IsAvailable() and not (S.FireElemental:CooldownRemainsP() > 120) or S.StormElemental:IsAvailable() and not (S.StormElemental:CooldownRemainsP() > 120))) then
      if HR.Cast(S.EarthShock) then return "earth_shock 336"; end
    end
    -- lightning_lasso
    if S.LightningLasso:IsCastableP() then
      if HR.Cast(S.LightningLasso) then return "lightning_lasso"; end
    end
    -- lightning_bolt,if=cooldown.storm_elemental.remains>(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled&(azerite.igneous_potential.rank<2|!buff.lava_surge.up&buff.bloodlust.up)
    if S.LightningBolt:IsCastableP() and (S.StormElemental:CooldownRemainsP() > 120 and S.StormElemental:IsAvailable() and (S.IgneousPotential:AzeriteRank() < 2 or Player:BuffDownP(S.LavaSurgeBuff) and Player:HasHeroism())) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 352"; end
    end
    -- lightning_bolt,if=(buff.stormkeeper.remains<1.1*gcd*buff.stormkeeper.stack|buff.stormkeeper.up&buff.master_of_the_elements.up)
    if S.LightningBolt:IsCastableP() and ((Player:BuffRemainsP(S.StormkeeperBuff) < 1.1 * Player:GCD() * Player:BuffStackP(S.StormkeeperBuff) or Player:BuffP(S.StormkeeperBuff) and Player:BuffP(S.MasteroftheElementsBuff))) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 362"; end
    end
    -- frost_shock,if=talent.icefury.enabled&talent.master_of_the_elements.enabled&buff.icefury.up&buff.master_of_the_elements.up
    if S.FrostShock:IsCastableP() and (S.Icefury:IsAvailable() and S.MasteroftheElements:IsAvailable() and Player:BuffP(S.IcefuryBuff) and Player:BuffP(S.MasteroftheElementsBuff)) then
      if HR.Cast(S.FrostShock) then return "frost_shock 372"; end
    end
    -- lava_burst,if=buff.ascendance.up
    if S.LavaBurst:IsCastableP() and (Player:BuffP(S.AscendanceBuff)) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 382"; end
    end
    -- flame_shock,target_if=refreshable&active_enemies>1&buff.surge_of_power.up
    if S.FlameShock:IsCastableP() then
      if HR.CastCycle(S.FlameShock, 40, EvaluateCycleFlameShock390) then return "flame_shock 408" end
    end
    -- lava_burst,if=talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((1.16*(expected_combat_length-time)-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration))<(expected_combat_length-time-cooldown.storm_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.storm_elemental.remains)%cooldown.storm_elemental.duration)))
    if S.LavaBurst:IsCastableP() and (S.StormElemental:IsAvailable() and S.LavaBurst:CooldownUpP() and Player:BuffP(S.SurgeofPowerBuff) and (Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * math.floor ((Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) / 150) < 30 * (1 + num((S.EchooftheElementals:AzeriteRank() >= 2))) or (1.16 * Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * math.floor ((1.16 * Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) / 150)) < (Target:TimeToDie() - S.StormElemental:CooldownRemainsP() - 150 * math.floor ((Target:TimeToDie() - S.StormElemental:CooldownRemainsP()) / 150)))) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 409"; end
    end
    -- lava_burst,if=!talent.storm_elemental.enabled&cooldown_react&buff.surge_of_power.up&(expected_combat_length-time-cooldown.fire_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%cooldown.storm_elemental.duration)<30*(1+(azerite.echo_of_the_elementals.rank>=2))|(1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains-cooldown.storm_elemental.duration*floor((1.16*(expected_combat_length-time)-cooldown.fire_elemental.remains)%cooldown.storm_elemental.duration))<(expected_combat_length-time-cooldown.fire_elemental.remains-cooldown.storm_elemental.duration*floor((expected_combat_length-time-cooldown.fire_elemental.remains)%cooldown.storm_elemental.duration)))
    if S.LavaBurst:IsCastableP() and (not S.StormElemental:IsAvailable() and S.LavaBurst:CooldownUpP() and Player:BuffP(S.SurgeofPowerBuff) and (Target:TimeToDie() - S.FireElemental:CooldownRemainsP() - 150 * math.floor ((Target:TimeToDie() - S.FireElemental:CooldownRemainsP()) / 150) < 30 * (1 + num((S.EchooftheElementals:AzeriteRank() >= 2))) or (1.16 * Target:TimeToDie() - S.FireElemental:CooldownRemainsP() - 150 * math.floor ((1.16 * Target:TimeToDie() - S.FireElemental:CooldownRemainsP()) / 150)) < (Target:TimeToDie() - S.FireElemental:CooldownRemainsP() - 150 * math.floor ((Target:TimeToDie() - S.FireElemental:CooldownRemainsP()) / 150)))) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 433"; end
    end
    -- lightning_bolt,if=buff.surge_of_power.up
    if S.LightningBolt:IsCastableP() and (Player:BuffP(S.SurgeofPowerBuff)) then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 457"; end
    end
    -- lava_burst,if=cooldown_react&!talent.master_of_the_elements.enabled
    if S.LavaBurst:IsCastableP() and (S.LavaBurst:CooldownUpP() and not S.MasteroftheElements:IsAvailable()) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 461"; end
    end
    -- icefury,if=talent.icefury.enabled&!(maelstrom>75&cooldown.lava_burst.remains<=0)&(!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<cooldown.storm_elemental.duration-30)
    if S.Icefury:IsCastableP() and (S.Icefury:IsAvailable() and not (Player:Maelstrom() > 75 and S.LavaBurst:CooldownRemainsP() <= 0) and (not S.StormElemental:IsAvailable() or S.StormElemental:CooldownRemainsP() < 120)) then
      if HR.Cast(S.Icefury) then return "icefury 469"; end
    end
    -- lava_burst,if=cooldown_react&charges>talent.echo_of_the_elements.enabled
    if S.LavaBurst:IsCastableP() and (S.LavaBurst:CooldownUpP() and S.LavaBurst:ChargesP() > num(S.EchooftheElements:IsAvailable())) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 479"; end
    end
    -- frost_shock,if=talent.icefury.enabled&buff.icefury.up&buff.icefury.remains<1.1*gcd*buff.icefury.stack
    if S.FrostShock:IsCastableP() and (S.Icefury:IsAvailable() and Player:BuffP(S.IcefuryBuff) and Player:BuffRemainsP(S.IcefuryBuff) < 1.1 * Player:GCD() * Player:BuffStackP(S.IcefuryBuff)) then
      if HR.Cast(S.FrostShock) then return "frost_shock 491"; end
    end
    -- lava_burst,if=cooldown_react
    if S.LavaBurst:IsCastableP() and (S.LavaBurst:CooldownUpP()) then
      if HR.Cast(S.LavaBurst) then return "lava_burst 501"; end
    end
    -- concentrated_flame
    if S.ConcentratedFlame:IsCastableP() then
      if HR.Cast(S.ConcentratedFlame, nil, Settings.Commons.EssenceDisplayStyle) then return "concentrated_flame 503"; end
    end
    -- reaping_flames
    if S.ReapingFlames:IsCastableP() then
      if HR.Cast(S.ReapingFlames, nil, Settings.Commons.EssenceDisplayStyle) then return "reaping_flames 505"; end
    end
    -- flame_shock,target_if=refreshable&!buff.surge_of_power.up
    if S.FlameShock:IsCastableP() then
      if HR.CastCycle(S.FlameShock, 40, EvaluateCycleFlameShock511) then return "flame_shock 521" end
    end
    -- totem_mastery,if=talent.totem_mastery.enabled&(buff.resonance_totem.remains<6|(buff.resonance_totem.remains<(buff.ascendance.duration+cooldown.ascendance.remains)&cooldown.ascendance.remains<15))
    if S.TotemMastery:IsReadyP() and (S.TotemMastery:IsAvailable() and (ResonanceTotemTime() < 6 or (ResonanceTotemTime() < (S.AscendanceBuff:BaseDuration() + S.Ascendance:CooldownRemainsP()) and S.Ascendance:CooldownRemainsP() < 15))) then
      if HR.Cast(S.TotemMastery) then return "totem_mastery 522"; end
    end
    -- frost_shock,if=talent.icefury.enabled&buff.icefury.up&(buff.icefury.remains<gcd*4*buff.icefury.stack|buff.stormkeeper.up|!talent.master_of_the_elements.enabled)
    if S.FrostShock:IsCastableP() and (S.Icefury:IsAvailable() and Player:BuffP(S.IcefuryBuff) and (Player:BuffRemainsP(S.IcefuryBuff) < Player:GCD() * 4 * Player:BuffStackP(S.IcefuryBuff) or Player:BuffP(S.StormkeeperBuff) or not S.MasteroftheElements:IsAvailable())) then
      if HR.Cast(S.FrostShock) then return "frost_shock 536"; end
    end
    -- earth_elemental,if=!talent.primal_elementalist.enabled|talent.primal_elementalist.enabled&(cooldown.fire_elemental.remains<(cooldown.fire_elemental.duration-30)&!talent.storm_elemental.enabled|cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&talent.storm_elemental.enabled)
    -- chain_lightning,if=buff.tectonic_thunder.up&!buff.stormkeeper.up&spell_targets.chain_lightning>1
    if S.ChainLightning:IsCastableP() and (Player:BuffP(S.TectonicThunderBuff) and Player:BuffDownP(S.StormkeeperBuff) and EnemiesCount > 1) then
      if HR.Cast(S.ChainLightning) then return "chain_lightning 550"; end
    end
    -- lightning_bolt
    if S.LightningBolt:IsCastableP() then
      if HR.Cast(S.LightningBolt) then return "lightning_bolt 556"; end
    end
    -- flame_shock,moving=1,target_if=refreshable
    if S.FlameShock:IsCastableP() and Player:IsMoving() then
      if HR.CastCycle(S.FlameShock, 40, EvaluateCycleFlameShock562) then return "flame_shock 570" end
    end
    -- flame_shock,moving=1,if=movement.distance>6
    if S.FlameShock:IsCastableP() and Player:IsMoving() and (movement.distance > 6) then
      if HR.Cast(S.FlameShock) then return "flame_shock 571"; end
    end
    -- frost_shock,moving=1
    if S.FrostShock:IsCastableP() and Player:IsMoving() then
      if HR.Cast(S.FrostShock) then return "frost_shock 573"; end
    end
  end
  -- call precombat
  if not Player:AffectingCombat() then
    local ShouldReturn = Precombat(); if ShouldReturn then return ShouldReturn; end
  end
  if Everyone.TargetIsValid() then
    -- Interrupts
    Everyone.Interrupt(30, S.WindShear, Settings.Commons.OffGCDasOffGCD.WindShear, false);
    -- bloodlust,if=azerite.ancestral_resonance.enabled
    -- potion,if=expected_combat_length-time<60|cooldown.guardian_of_azeroth.remains<30
    if I.PotionofUnbridledFury:IsReady() and Settings.Commons.UsePotions and (Target:TimeToDie() < 60 or S.GuardianofAzeroth:CooldownRemainsP() <30) then
      if HR.CastSuggested(I.PotionofUnbridledFury) then return "battle_potion_of_intellect 577"; end
    end
    -- flame_shock,if=!ticking&spell_targets.chainlightning<4&(cooldown.storm_elemental.remains<cooldown.storm_elemental.duration-30|buff.wind_gust.stack<14)
    if S.FlameShock:IsCastableP() and (Target:DebuffDownP(S.FlameShockDebuff) and EnemiesCount < 4 and (S.StormElemental:CooldownRemainsP() < 120 or Player:BuffStackP(S.WindGustBuff) < 14)) then
      if HR.Cast(S.FlameShock) then return "flame_shock 583"; end
    end
    -- totem_mastery,if=talent.totem_mastery.enabled&buff.resonance_totem.remains<2
    if S.TotemMastery:IsReadyP() and (S.TotemMastery:IsAvailable() and Player:BuffDownP(S.ResonanceTotemBuff)) then
      if HR.Cast(S.TotemMastery) then return "totem_mastery 585"; end
    end
    -- use_items
    -- guardian_of_azeroth,if=dot.flame_shock.ticking&(!talent.storm_elemental.enabled&(cooldown.fire_elemental.duration-30<cooldown.fire_elemental.remains|expected_combat_length-time>190|expected_combat_length-time<32|!(cooldown.fire_elemental.remains+30<expected_combat_length-time)|cooldown.fire_elemental.remains<2)|talent.storm_elemental.enabled&(cooldown.storm_elemental.duration-30<cooldown.storm_elemental.remains|expected_combat_length-time>190|expected_combat_length-time<35|!(cooldown.storm_elemental.remains+30<expected_combat_length-time)|cooldown.storm_elemental.remains<2))
    if S.GuardianofAzeroth:IsCastableP() and (Target:DebuffP(S.FlameShockDebuff) and (not S.StormElemental:IsAvailable() and (S.FireElemental:CooldownRemainsP() > 120 or Target:TimeToDie() > 190 or Target:TimeToDie() < 32 or not (S.FireElemental:CooldownRemainsP() + 30 < Target:TimeToDie()) or S.FireElemental.CooldownRemainsP() < 2) or S.StormElemental:IsAvailable() and (S.StormElemental:CooldownRemainsP() > 120 or Target:TimeToDie() > 190 or Target:TimeToDie() < 35 or not (S.StormElemental:CooldownRemainsP() + 30 < Target:TimeToDie()) or S.StormElemental:CooldownRemainsP() < 2))) then
      if HR.Cast(S.GuardianofAzeroth, nil, Settings.Commons.EssenceDisplayStyle) then return "guardian_of_azeroth"; end
    end
    -- fire_elemental,if=!talent.storm_elemental.enabled&(!essence.condensed_lifeforce.major|cooldown.guardian_of_azeroth.remains>150|expected_combat_length-time<30|expected_combat_length-time<60|expected_combat_length-time>155|!(cooldown.guardian_of_azeroth.remains+30<expected_combat_length-time))
    if S.FireElemental:IsCastableP() and (not S.StormElemental:IsAvailable() and (not S.GuardianofAzeroth:IsAvailable() or S.GuardianofAzeroth:CooldownRemainsP() > 150 or Target:TimeToDie() < 30 or Target:TimeToDie() < 60 or Target:TimeToDie() > 155 or not (S.GuardianofAzeroth:CooldownRemainsP() + 30 < Target:TimeToDie()))) then
      if HR.Cast(S.FireElemental, Settings.Elemental.GCDasOffGCD.FireElemental) then return "fire_elemental 595"; end
    end
    -- focused_azerite_beam
    if S.FocusedAzeriteBeam:IsCastableP() then
      if HR.Cast(S.FocusedAzeriteBeam, nil, Settings.Commons.EssenceDisplayStyle) then return "focused_azerite_beam"; end
    end
    -- purifying_blast
    if S.PurifyingBlast:IsCastableP() then
      if HR.Cast(S.PurifyingBlast, nil, Settings.Commons.EssenceDisplayStyle) then return "purifying_blast"; end
    end
    -- the_unbound_force
    if S.TheUnboundForce:IsCastableP() then
      if HR.Cast(S.TheUnboundForce, nil, Settings.Commons.EssenceDisplayStyle) then return "the_unbound_force"; end
    end
    -- memory_of_lucid_dreams
    if S.MemoryofLucidDreams:IsCastableP() then
      if HR.Cast(S.MemoryofLucidDreams, nil, Settings.Commons.EssenceDisplayStyle) then return "memory_of_lucid_dreams"; end
    end
    -- ripple_in_space
    if S.RippleInSpace:IsCastableP() then
      if HR.Cast(S.RippleInSpace, nil, Settings.Commons.EssenceDisplayStyle) then return "ripple_in_space"; end
    end
    -- worldvein_resonance,if=(talent.unlimited_power.enabled|buff.stormkeeper.up|talent.ascendance.enabled&((talent.storm_elemental.enabled&cooldown.storm_elemental.remains<(cooldown.storm_elemental.duration-30)&cooldown.storm_elemental.remains>15|!talent.storm_elemental.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up))|!cooldown.ascendance.up)
    if S.WorldveinResonance:IsCastableP() and ((S.UnlimitedPower:IsAvailable() or Player:BuffP(S.StormkeeperBuff) or S.Ascendance:IsAvailable() and ((S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() < 120) and S.StormElemental:CooldownRemainsP() > 15 or not S.StormElemental:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and S.Icefury:CooldownUpP())) or not S.Ascendance:CooldownUpP()) then
      if HR.Cast(S.WorldveinResonance, nil, Settings.Commons.EssenceDisplayStyle) then return "worldvein_resonance"; end
    end
    -- blood_of_the_enemy,if=talent.storm_elemental.enabled&pet.primal_storm_elemental.active
    if S.BloodoftheEnemy:IsCastableP() and (S.StormElemental:IsAvailable() and S.StormElemental:CooldownRemainsP() > 120) then
      if HR.Cast(S.BloodoftheEnemy, nil, Settings.Commons.EssenceDisplayStyle) then return "blood_of_the_enemy"; end
    end
    -- storm_elemental,if=talent.storm_elemental.enabled&(!cooldown.stormkeeper.up|!talent.stormkeeper.enabled)&(!talent.icefury.enabled|!buff.icefury.up&!cooldown.icefury.up)&(!talent.ascendance.enabled|!buff.ascendance.up|expected_combat_length-time<32)&(!essence.condensed_lifeforce.major|cooldown.guardian_of_azeroth.remains>150|expected_combat_length-time<30|expected_combat_length-time<60|expected_combat_length-time>155|!(cooldown.guardian_of_azeroth.remains+30<expected_combat_length-time))
    if S.StormElemental:IsCastableP() and (S.StormElemental:IsAvailable() and (not S.Stormkeeper:CooldownUpP() or not S.Stormkeeper:IsAvailable()) and (not S.Icefury:IsAvailable() or Player:BuffDownP(S.IcefuryBuff) and not S.Icefury:CooldownUpP()) and (not S.Ascendance:IsAvailable() or Player:BuffDownP(S.AscendanceBuff) or Target:TimeToDie() < 32) and (not S.GuardianofAzeroth:IsAvailable() or S.GuardianofAzeroth:CooldownRemainsP() > 150 or Target:TimeToDie() < 30 or Target:TimeToDie() < 60 or Target:TimeToDie() > 155 or not (S.GuardianofAzeroth:CooldownRemainsP() + 30 < Target:TimeToDie()))) then
      if HR.Cast(S.StormElemental, Settings.Elemental.GCDasOffGCD.StormElemental) then return "storm_elemental 605"; end
    end
    if (HR.CDsON()) then
      -- blood_fury,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
      if S.BloodFury:IsCastableP() and (not S.Ascendance:IsAvailable() or Player:BuffP(S.AscendanceBuff) or S.Ascendance:CooldownRemainsP() > 50) then
        if HR.Cast(S.BloodFury, Settings.Commons.OffGCDasOffGCD.Racials) then return "blood_fury 611"; end
      end
      -- berserking,if=!talent.ascendance.enabled|buff.ascendance.up
      if S.Berserking:IsCastableP() and (not S.Ascendance:IsAvailable() or Player:BuffP(S.AscendanceBuff)) then
        if HR.Cast(S.Berserking, Settings.Commons.OffGCDasOffGCD.Racials) then return "berserking 619"; end
      end
      -- fireblood,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
      if S.Fireblood:IsCastableP() and (not S.Ascendance:IsAvailable() or Player:BuffP(S.AscendanceBuff) or S.Ascendance:CooldownRemainsP() > 50) then
        if HR.Cast(S.Fireblood, Settings.Commons.OffGCDasOffGCD.Racials) then return "fireblood 625"; end
      end
      -- ancestral_call,if=!talent.ascendance.enabled|buff.ascendance.up|cooldown.ascendance.remains>50
      if S.AncestralCall:IsCastableP() and (not S.Ascendance:IsAvailable() or Player:BuffP(S.AscendanceBuff) or S.Ascendance:CooldownRemainsP() > 50) then
        if HR.Cast(S.AncestralCall, Settings.Commons.OffGCDasOffGCD.Racials) then return "ancestral_call 633"; end
      end
      -- bag_of_tricks,if=!talent.ascendance.enabled|!buff.ascendance.up
      if S.BagofTricks:IsCastableP() and (not S.Ascendance:IsAvailable() or Player:BuffDownP(S.AscendanceBuff)) then
        if HR.Cast(S.BagofTricks, Settings.Commons.OffGCDasOffGCD.Racials) then return "bag_of_tricks 635"; end
      end
    end
    -- run_action_list,name=aoe,if=active_enemies>2&(spell_targets.chain_lightning>2|spell_targets.lava_beam>2)
    if (EnemiesCount > 2) then
      local ShouldReturn = Aoe(); if ShouldReturn then return ShouldReturn; end
    end
    -- run_action_list,name=funnel,if=active_enemies>=2&(spell_targets.chain_lightning<2|spell_targets.lava_beam<2)
    if (Cache.EnemiesCount[40] >= 2 and EnemiesCount < 2) then
      local ShouldReturn = Funnel(); if ShouldReturn then return ShouldReturn; end
    end
    -- run_action_list,name=single_target,if=active_enemies<=2
    if (EnemiesCount <= 2) then
      local ShouldReturn = SingleTarget(); if ShouldReturn then return ShouldReturn; end
    end
  end
end

local function Init ()
  HL.RegisterNucleusAbility(188443, 10, 6)               -- Chain Lightning
  HL.RegisterNucleusAbility(61882, 8, 6)                 -- Earthquake
  HL.RegisterNucleusAbility(192222, 8, 6)                -- Liquid Magma Totem
end

HR.SetAPL(262, APL, Init)
