class_name EraText
extends RefCounted
## Era-aware wrappers around the LOCKED text builders (Insight, ImagePrompt, ClaudeInsight/GrokInsight record).
## Built-in era -> the original builder, untouched output. Era pack -> the same builder run on a built-in era,
## then only the era-specific part is swapped (closing line / scene / ERA title). Nothing locked is edited.

const BASE := "industrial" # stand-in era for the shared wording; its era-specific text is replaced below


static func insight(sim: DialecticSim, era_id: String, era: Dictionary) -> Dictionary:
	if Eras.DATA.has(era_id):
		return Insight.build(sim, era_id)
	var ins := Insight.build(sim, BASE)
	var base_closing: String = Eras.get_era(BASE).closing[sim.outcome]
	assert(ins.text.ends_with(base_closing))
	ins.text = ins.text.trim_suffix(base_closing) + era.closing[sim.outcome]
	return ins


static func image_prompt(sim: DialecticSim, era_id: String, era: Dictionary) -> String:
	if Eras.DATA.has(era_id):
		return ImagePrompt.build(sim, era_id)
	var scene: String = era.get("image_scene", "the %s era" % era.title.to_lower())
	return ImagePrompt.build(sim, BASE).replace(ImagePrompt.ERA_SCENE[BASE], scene)


## Body for the Grok chat call; only the "ERA: ..." line of the run record differs.
static func grok_chat_body(sim: DialecticSim, era_id: String, era: Dictionary) -> Dictionary:
	if Eras.DATA.has(era_id):
		return GrokInsight.build_chat_body(sim, era_id)
	var body: Dictionary = GrokInsight.build_chat_body(sim, BASE).duplicate(true)
	var msg: Dictionary = body.messages[1]
	var old_line := "ERA: %s\n" % Eras.get_era(BASE).title
	assert(msg.content.begins_with(old_line))
	msg.content = "ERA: %s\n" % era.title + msg.content.trim_prefix(old_line)
	return body
