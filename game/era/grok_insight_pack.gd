class_name GrokInsightPack
extends GrokInsight
## GrokInsight for any era, including era packs. Same calls, same fallback; only the run record names the pack's
## era (EraText.grok_chat_body). The locked GrokInsight is unchanged.


func request_era(sim: DialecticSim, era_id: String, era: Dictionary, fallback: Dictionary) -> void:
	_fallback = fallback
	_key = OS.get_environment("XAI_API_KEY")
	if _key == "":
		_finish_fallback.call_deferred("no XAI_API_KEY set")
		return
	var err := _post(CHAT_URL, EraText.grok_chat_body(sim, era_id, era), _on_chat_done)
	if err != OK:
		_finish_fallback("request not sent (error %d)" % err)
